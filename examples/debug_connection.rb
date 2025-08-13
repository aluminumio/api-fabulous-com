#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "fabulous"
require "dotenv/load"

# Configure the client with your credentials
Fabulous.configure do |config|
  config.username = ENV["FABULOUS_USERNAME"]
  config.password = ENV["FABULOUS_PASSWORD"]
end

puts "Username: #{ENV['FABULOUS_USERNAME']}"
puts "Password: #{'*' * ENV['FABULOUS_PASSWORD'].length}"
puts "API URL: #{Fabulous.configuration.base_url}"
puts

client = Fabulous.client

begin
  # Try a simple request
  puts "Making test request to listDomains..."
  response = client.request("listDomains", page: 1)
  
  puts "Raw XML Response:"
  puts response.raw_xml
  puts
  
  puts "Parsed Response:"
  puts "Status Code: #{response.status_code}"
  puts "Status Message: #{response.status_message}"
  puts "Success?: #{response.success?}"
  puts "Data: #{response.data.inspect}"
  
rescue Fabulous::Error => e
  puts "Error: #{e.class} - #{e.message}"
  puts "Error code: #{e.respond_to?(:code) ? e.code : 'N/A'}"
rescue StandardError => e
  puts "Unexpected error: #{e.class} - #{e.message}"
  puts e.backtrace.first(5)
end