# frozen_string_literal: true

module Fabulous
  class Client
    attr_reader :configuration

    def initialize(configuration = nil)
      @configuration = configuration || Fabulous.configuration || Configuration.new
      validate_configuration!
    end

    def domains
      @domains ||= Resources::Domain.new(self)
    end

    def dns
      @dns ||= Resources::DNS.new(self)
    end

    def request(action, params = {})
      params = build_params(action, params)

      # The Fabulous API uses GET requests with URL parameters
      url = "/#{action}"

      response = connection.get(url) do |req|
        req.params = params
      end

      # Debug output if ENV variable is set
      if ENV["DEBUG_FABULOUS"]
        puts "Request URL: #{configuration.base_url}#{url}"
        puts "Parameters: #{params.inspect}"
        puts "HTTP Status: #{response.status}"
        puts "Response Body:"
        puts response.body
        puts
      end

      Response.new(response.body).tap do |parsed_response|
        handle_errors(parsed_response)
      end
    rescue Faraday::TimeoutError, Net::OpenTimeout, Net::ReadTimeout, Timeout::Error => e
      raise TimeoutError, "Request timed out: #{e.message}"
    rescue Faraday::Error => e
      # Check if the error message indicates a timeout
      raise TimeoutError, "Request timed out: #{e.message}" if e.message =~ /timeout|expired/i

      raise RequestError, "Request failed: #{e.message}"
    end

    private

    def connection
      @connection ||= Faraday.new(url: configuration.base_url) do |faraday|
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter
        faraday.options.timeout = configuration.timeout
        faraday.options.open_timeout = configuration.open_timeout
      end
    end

    def build_params(_action, params)
      # Don't include action in params, it's part of the URL path
      {
        username: configuration.username,
        password: configuration.password
      }.merge(params)
    end

    def handle_errors(response)
      return if response.success?

      case response.status_code
      when 300..399
        raise AuthenticationError.new(response.status_message || "Authentication failed", response.status_code)
      when 400..499
        raise RequestError.new(response.status_message || "Request error", response.status_code)
      when 500..599
        raise ResponseError.new(response.status_message || "Server error", response.status_code)
      when 689
        raise RateLimitError, "Execution time exhausted (300 seconds per 24 hours limit reached)"
      else
        raise Error, "Unknown error: #{response.status_message} (code: #{response.status_code})"
      end
    end

    def validate_configuration!
      raise ConfigurationError, "Username and password are required" unless configuration.valid?
    end
  end
end
