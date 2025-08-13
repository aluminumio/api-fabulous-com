# frozen_string_literal: true

module Fabulous
  module Resources
    class DNS < Base
      def list_records(domain_name, type: nil)
        params = { domain: domain_name }
        params[:type] = type if type

        response = request("listDNSrecords", params)
        response.data[:dns_records] || []
      end

      # MX Records
      def mx_records(domain_name)
        response = request("getMXRecords", domain: domain_name)
        response.data[:mx_records] || []
      end

      def add_mx_record(domain_name, hostname:, priority:, ttl: 3600)
        response = request("addMXRecord", {
                             domain: domain_name,
                             hostname: hostname,
                             priority: priority,
                             ttl: ttl
                           })
        response.success?
      end

      def update_mx_record(domain_name, record_id:, hostname: nil, priority: nil, ttl: nil)
        params = {
          domain: domain_name,
          recordId: record_id
        }
        params[:hostname] = hostname if hostname
        params[:priority] = priority if priority
        params[:ttl] = ttl if ttl

        response = request("updateMXRecord", params)
        response.success?
      end

      def delete_mx_record(domain_name, record_id)
        response = request("deleteMXRecord", domain: domain_name, recordId: record_id)
        response.success?
      end

      # CNAME Records
      def cname_records(domain_name)
        response = request("getCNAMERecords", domain: domain_name)
        response.data[:cname_records] || []
      end

      def add_cname_record(domain_name, alias_name:, target:, ttl: 3600)
        response = request("addCNAMERecord", {
                             domain: domain_name,
                             alias: alias_name,
                             target: target,
                             ttl: ttl
                           })
        response.success?
      end

      def update_cname_record(domain_name, record_id:, alias_name: nil, target: nil, ttl: nil)
        params = {
          domain: domain_name,
          recordId: record_id
        }
        params[:alias] = alias_name if alias_name
        params[:target] = target if target
        params[:ttl] = ttl if ttl

        response = request("updateCNAMERecord", params)
        response.success?
      end

      def delete_cname_record(domain_name, record_id)
        response = request("deleteCNAMERecord", domain: domain_name, recordId: record_id)
        response.success?
      end

      # A Records
      def a_records(domain_name)
        response = request("getARecords", domain: domain_name)
        response.data[:a_records] || []
      end

      def add_a_record(domain_name, hostname:, ip_address:, ttl: 3600)
        response = request("addARecord", {
                             domain: domain_name,
                             hostname: hostname,
                             ipAddress: ip_address,
                             ttl: ttl
                           })
        response.success?
      end

      def update_a_record(domain_name, record_id:, hostname: nil, ip_address: nil, ttl: nil)
        params = {
          domain: domain_name,
          recordId: record_id
        }
        params[:hostname] = hostname if hostname
        params[:ipAddress] = ip_address if ip_address
        params[:ttl] = ttl if ttl

        response = request("updateARecord", params)
        response.success?
      end

      def delete_a_record(domain_name, record_id)
        response = request("deleteARecord", domain: domain_name, recordId: record_id)
        response.success?
      end

      # TXT Records
      def txt_records(domain_name)
        response = request("getTXTRecords", domain: domain_name)
        response.data[:txt_records] || []
      end

      def add_txt_record(domain_name, hostname:, text:, ttl: 3600)
        response = request("addTXTRecord", {
                             domain: domain_name,
                             hostname: hostname,
                             text: text,
                             ttl: ttl
                           })
        response.success?
      end

      def update_txt_record(domain_name, record_id:, hostname: nil, text: nil, ttl: nil)
        params = {
          domain: domain_name,
          recordId: record_id
        }
        params[:hostname] = hostname if hostname
        params[:text] = text if text
        params[:ttl] = ttl if ttl

        response = request("updateTXTRecord", params)
        response.success?
      end

      def delete_txt_record(domain_name, record_id)
        response = request("deleteTXTRecord", domain: domain_name, recordId: record_id)
        response.success?
      end

      # AAAA Records (IPv6)
      def aaaa_records(domain_name)
        response = request("getAAAARecords", domain: domain_name)
        response.data[:aaaa_records] || []
      end

      def add_aaaa_record(domain_name, hostname:, ipv6_address:, ttl: 3600)
        response = request("addAAAARecord", {
                             domain: domain_name,
                             hostname: hostname,
                             ipv6Address: ipv6_address,
                             ttl: ttl
                           })
        response.success?
      end

      def update_aaaa_record(domain_name, record_id:, hostname: nil, ipv6_address: nil, ttl: nil)
        params = {
          domain: domain_name,
          recordId: record_id
        }
        params[:hostname] = hostname if hostname
        params[:ipv6Address] = ipv6_address if ipv6_address
        params[:ttl] = ttl if ttl

        response = request("updateAAAARecord", params)
        response.success?
      end

      def delete_aaaa_record(domain_name, record_id)
        response = request("deleteAAAARecord", domain: domain_name, recordId: record_id)
        response.success?
      end
    end
  end
end
