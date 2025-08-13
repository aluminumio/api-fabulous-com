# frozen_string_literal: true

module Fabulous
  module Resources
    class Domain < Base
      def list(page: nil, &block)
        if page
          response = request("listDomains", page: page)
          block_given? ? yield(response) : response.data[:domains]
        else
          paginate("listDomains", &block)
        end
      end

      def all
        paginate("listDomains")
      end

      def check(domain_name)
        response = request("checkDomain", domain: domain_name)
        response.data[:available]
      end

      def info(domain_name)
        response = request("domainInfo", domain: domain_name)
        response.data[:domain_info]
      end

      def register(domain_name, years: 1, nameservers: [], whois_privacy: false, auto_renew: false)
        params = {
          domain: domain_name,
          years: years,
          whoisPrivacy: whois_privacy,
          autoRenew: auto_renew
        }

        nameservers.each_with_index do |ns, index|
          params["ns#{index + 1}"] = ns
        end

        response = request("registerDomain", params)
        response.success?
      end

      def renew(domain_name, years: 1)
        response = request("renewDomain", domain: domain_name, years: years)
        response.success?
      end

      def transfer_in(domain_name, auth_code)
        response = request("transferIn", domain: domain_name, authCode: auth_code)
        response.success?
      end

      def set_nameservers(domain_name, nameservers)
        params = { domain: domain_name }

        nameservers.each_with_index do |ns, index|
          params["ns#{index + 1}"] = ns
        end

        response = request("setNameServers", params)
        response.success?
      end

      def get_nameservers(domain_name)
        info = info(domain_name)
        info[:nameservers] if info
      end

      def lock(domain_name)
        response = request("lockDomain", domain: domain_name)
        response.success?
      end

      def unlock(domain_name)
        response = request("unlockDomain", domain: domain_name)
        response.success?
      end

      def set_auto_renew(domain_name, enabled: true)
        response = request("setAutoRenew", domain: domain_name, autoRenew: enabled)
        response.success?
      end

      def enable_whois_privacy(domain_name)
        response = request("enableWhoisPrivacy", domain: domain_name)
        response.success?
      end

      def disable_whois_privacy(domain_name)
        response = request("disableWhoisPrivacy", domain: domain_name)
        response.success?
      end

      protected

      def extract_items(response)
        response.data[:domains] || []
      end
    end
  end
end
