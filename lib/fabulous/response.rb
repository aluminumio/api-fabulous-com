# frozen_string_literal: true

module Fabulous
  class Response
    attr_reader :doc, :raw_xml

    def initialize(xml_string)
      @raw_xml = xml_string
      @doc = Nokogiri::XML(xml_string)
    end

    def success?
      status_code && status_code.to_i == 200
    end

    def status_code
      # Try both old and new format
      @status_code ||= doc.at_xpath("//statusCode")&.text&.to_i ||
                       doc.at_xpath("//response/status")&.text&.to_i
    end

    def status_message
      # Try both old and new format
      @status_message ||= doc.at_xpath("//statusText")&.text ||
                          doc.at_xpath("//response/reason")&.text
    end

    def data
      @data ||= parse_data
    end

    def paginated?
      # Check for old format with pagecount element
      if (pagecount = doc.at_xpath("//pagecount"))
        page = doc.at_xpath("//page")&.text&.to_i || 1
        return pagecount.text.to_i > page
      end

      # Check if results count exceeds what's shown (pagination needed)
      total = doc.at_xpath("//results")&.attr("count").to_i
      shown = doc.xpath("//results/result").length
      total > shown && shown.positive?
    end

    def page_count
      # Check for old format with pagecount element
      if (pagecount = doc.at_xpath("//pagecount"))
        return pagecount.text.to_i
      end

      # Calculate based on total results and page size
      total = doc.at_xpath("//results")&.attr("count").to_i
      page_size = doc.xpath("//results/result").length
      return 1 if page_size.zero?

      (total.to_f / page_size).ceil
    end

    def current_page
      # Check for old format with page element
      if (page = doc.at_xpath("//page"))
        return page.text.to_i
      end

      # Try to get from request params
      doc.at_xpath("//request/params/param[@name='page']")&.text&.to_i || 1
    end

    private

    def parse_data
      result = {}

      # Parse new format with results
      results = doc.xpath("//results/result")
      if results && !results.empty?
        result[:domains] = parse_results_domains(results)
      # Parse old format - check various xpath patterns
      else
        # Try different patterns to find domains
        domains = doc.xpath("//response/domains/domain")
        domains = doc.xpath("//domains/domain") if domains.empty?
        domains = doc.xpath("//domain") if domains.empty?

        result[:domains] = parse_domains(domains) if domains && !domains.empty?
      end

      if (dns_records = doc.xpath("//dnsrecord"))
        result[:dns_records] = parse_dns_records(dns_records)
      end

      if (mx_records = doc.xpath("//mxrecord"))
        result[:mx_records] = parse_mx_records(mx_records)
      end

      if (cname_records = doc.xpath("//cnamerecord"))
        result[:cname_records] = parse_cname_records(cname_records)
      end

      if (a_records = doc.xpath("//arecord"))
        result[:a_records] = parse_a_records(a_records)
      end

      # Parse single domain info
      if (domain_info = doc.at_xpath("//domainInfo"))
        result[:domain_info] = parse_domain_info(domain_info)
      elsif (info_result = doc.at_xpath("//results/result[expiry]"))
        # domainInfo response format
        result[:domain_info] = {
          expiry_date: info_result.at_xpath("expiry")&.text,
          nameservers: info_result.xpath("nameserverss/nameservers").map(&:text),
          status: info_result.at_xpath("fabstatus")&.text&.capitalize || "Active",
          auto_renew: info_result.at_xpath("autorenewstatus")&.text == "1",
          locked: info_result.xpath("registrystatuss/registrystatus").any? { |s| s.text.include?("Prohibited") },
          whois_privacy: info_result.at_xpath("whoisprivacyenabled")&.text == "1"
        }
      elsif (domain_element = doc.at_xpath("//domain"))
        # Alternative format for domain info
        result[:domain_info] = {
          status: domain_element.at_xpath("status")&.text || "Active"
        }
      end

      # Parse availability check
      if (availability = doc.at_xpath("//availability"))
        result[:available] = availability.text == "true"
      end

      result.empty? ? parse_generic : result
    end

    def parse_results_domains(results)
      results.map do |result|
        {
          name: result.at_xpath("domain")&.text,
          expiry_date: result.at_xpath("exdate")&.text,
          status: "Active", # Not provided in new format, assuming active
          auto_renew: nil, # Not provided in this format
          locked: nil # Not provided in this format
        }.compact
      end
    end

    def parse_domains(domains)
      domains.map do |domain|
        {
          name: domain.at_xpath("name")&.text,
          status: domain.at_xpath("status")&.text,
          expiry_date: domain.at_xpath("expiryDate")&.text,
          auto_renew: domain.at_xpath("autoRenew")&.text == "true",
          locked: domain.at_xpath("locked")&.text == "true"
        }.compact
      end
    end

    def parse_domain_info(info)
      {
        name: info.at_xpath("name")&.text,
        status: info.at_xpath("status")&.text,
        creation_date: info.at_xpath("creationDate")&.text,
        expiry_date: info.at_xpath("expiryDate")&.text,
        nameservers: info.xpath("nameservers/nameserver").map(&:text),
        auto_renew: info.at_xpath("autoRenew")&.text == "true",
        locked: info.at_xpath("locked")&.text == "true",
        whois_privacy: info.at_xpath("whoisPrivacy")&.text == "true"
      }.compact
    end

    def parse_dns_records(records)
      records.map do |record|
        {
          id: record.at_xpath("id")&.text,
          type: record.at_xpath("type")&.text,
          name: record.at_xpath("name")&.text,
          value: record.at_xpath("value")&.text,
          ttl: record.at_xpath("ttl")&.text&.to_i,
          priority: record.at_xpath("priority")&.text&.to_i
        }.compact
      end
    end

    def parse_mx_records(records)
      records.map do |record|
        {
          id: record.at_xpath("id")&.text,
          hostname: record.at_xpath("hostname")&.text,
          priority: record.at_xpath("priority")&.text&.to_i,
          ttl: record.at_xpath("ttl")&.text&.to_i
        }.compact
      end
    end

    def parse_cname_records(records)
      records.map do |record|
        {
          id: record.at_xpath("id")&.text,
          alias: record.at_xpath("alias")&.text,
          target: record.at_xpath("target")&.text,
          ttl: record.at_xpath("ttl")&.text&.to_i
        }.compact
      end
    end

    def parse_a_records(records)
      records.map do |record|
        {
          id: record.at_xpath("id")&.text,
          hostname: record.at_xpath("hostname")&.text,
          ip_address: record.at_xpath("ipAddress")&.text,
          ttl: record.at_xpath("ttl")&.text&.to_i
        }.compact
      end
    end

    def parse_generic
      # Return all non-status elements as a hash
      result = {}
      doc.root.children.each do |child|
        next if child.text? || child.name =~ /status/i

        result[child.name.to_sym] = if child.children.length > 1
                                      parse_element(child)
                                    else
                                      child.text
                                    end
      end
      result
    end

    def parse_element(element)
      if element.children.all?(&:text?)
        element.text
      else
        result = {}
        element.children.each do |child|
          next if child.text?

          if result[child.name.to_sym]
            result[child.name.to_sym] = [result[child.name.to_sym]] unless result[child.name.to_sym].is_a?(Array)
            result[child.name.to_sym] << parse_element(child)
          else
            result[child.name.to_sym] = parse_element(child)
          end
        end
        result
      end
    end
  end
end
