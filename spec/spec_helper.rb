# frozen_string_literal: true

require "bundler/setup"
require "fabulous"
require "webmock/rspec"
require "vcr"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.warnings = true
  
  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.order = :random
  Kernel.srand config.seed
end

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  
  # Filter sensitive data
  config.filter_sensitive_data("<USERNAME>") { ENV["FABULOUS_USERNAME"] }
  config.filter_sensitive_data("<PASSWORD>") { ENV["FABULOUS_PASSWORD"] }
end

# Helper to create a test client
def test_client(username: "test_user", password: "test_pass")
  Fabulous::Client.new(
    Fabulous::Configuration.new.tap do |config|
      config.username = username
      config.password = password
    end
  )
end

# Helper to create XML response
def xml_response(status_code, status_text, body = "")
  <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <response>
      <statusCode>#{status_code}</statusCode>
      <statusText>#{status_text}</statusText>
      #{body}
    </response>
  XML
end