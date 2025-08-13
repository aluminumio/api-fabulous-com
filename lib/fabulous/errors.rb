# frozen_string_literal: true

module Fabulous
  class Error < StandardError; end
  
  class ConfigurationError < Error; end
  
  class AuthenticationError < Error
    attr_reader :code
    
    def initialize(message, code = nil)
      @code = code
      super(message)
    end
  end
  
  class RequestError < Error
    attr_reader :code
    
    def initialize(message, code = nil)
      @code = code
      super(message)
    end
  end
  
  class ResponseError < Error
    attr_reader :code
    
    def initialize(message, code = nil)
      @code = code
      super(message)
    end
  end
  
  class RateLimitError < Error; end
  
  class TimeoutError < Error; end
end