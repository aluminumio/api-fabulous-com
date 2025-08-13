# frozen_string_literal: true

module Fabulous
  class Configuration
    attr_accessor :username, :password, :base_url, :timeout, :open_timeout

    def initialize
      @base_url = "https://api.fabulous.com"
      @timeout = 30
      @open_timeout = 10
    end

    def valid?
      !username.nil? && !password.nil?
    end
  end
end
