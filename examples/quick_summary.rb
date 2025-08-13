#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "fabulous"
require "dotenv/load"
require "date"

# Configure the client with your credentials
Fabulous.configure do |config|
  config.username = ENV.fetch("FABULOUS_USERNAME", nil)
  config.password = ENV.fetch("FABULOUS_PASSWORD", nil)
end

client = Fabulous.client

puts "=== Fabulous.com Domain Portfolio Summary ==="
puts

begin
  # Get all domains
  all_domains = client.domains.all

  puts "Total domains in portfolio: #{all_domains.length}"
  puts

  # Group by expiry year
  domains_by_year = all_domains.group_by do |domain|
    if domain[:expiry_date]
      begin
        Date.parse(domain[:expiry_date]).year
      rescue StandardError
        "Unknown"
      end
    else
      "Unknown"
    end
  end

  puts "Domains by expiry year:"
  domains_by_year.sort.each do |year, domains|
    puts "  #{year}: #{domains.length} domains"
  end
  puts

  # Find domains expiring soon
  expiring_soon = []
  today = Date.today

  all_domains.each do |domain|
    next unless domain[:expiry_date]

    begin
      expiry = Date.parse(domain[:expiry_date])
      days_until = (expiry - today).to_i

      if days_until <= 90 && days_until.positive?
        expiring_soon << { name: domain[:name], days: days_until, date: domain[:expiry_date] }
      end
    rescue ArgumentError
      # Skip invalid dates
    end
  end

  if expiring_soon.any?
    puts "⚠️  Domains expiring within 90 days:"
    expiring_soon.sort_by { |d| d[:days] }.each do |domain|
      puts "  - #{domain[:name]} (#{domain[:days]} days, expires: #{domain[:date]})"
    end
  else
    puts "✅ No domains expiring within 90 days"
  end

  puts

  # Show sample domains
  puts "Sample domains from portfolio:"
  all_domains.first(5).each do |domain|
    puts "  - #{domain[:name]} (expires: #{domain[:expiry_date]})"
  end
rescue Fabulous::Error => e
  puts "Error: #{e.message}"
end
