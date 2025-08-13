# frozen_string_literal: true

require "faraday"
require "nokogiri"

require_relative "fabulous/version"
require_relative "fabulous/configuration"
require_relative "fabulous/errors"
require_relative "fabulous/client"
require_relative "fabulous/response"
require_relative "fabulous/resources/base"
require_relative "fabulous/resources/domain"
require_relative "fabulous/resources/dns"

module Fabulous
  class << self
    attr_accessor :configuration

    def configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end

    def client
      @client ||= Client.new
    end

    def reset!
      @client = nil
      self.configuration = Configuration.new
    end
  end
end
