#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "fabulous"
require "dotenv/load"

# Configure the client with your credentials
Fabulous.configure do |config|
  config.username = ENV["FABULOUS_USERNAME"] || "your_username"
  config.password = ENV["FABULOUS_PASSWORD"] || "your_password"
end

client = Fabulous.client

puts "=== Listing All Domains (Auto-Pagination) ==="
begin
  # Method 1: Get all domains at once (auto-paginated)
  all_domains = client.domains.all
  
  puts "Total domains found: #{all_domains.length}"
  all_domains.each_with_index do |domain, index|
    puts "#{index + 1}. #{domain[:name]}"
    puts "   Status: #{domain[:status]}"
    puts "   Expires: #{domain[:expiry_date]}"
    puts "   Auto-renew: #{domain[:auto_renew]}"
    puts "   Locked: #{domain[:locked]}"
    puts
  end
rescue Fabulous::Error => e
  puts "Error: #{e.message}"
end

puts "\n=== Manual Pagination Example ==="
begin
  # Method 2: Manual pagination - process page by page
  page = 1
  total_domains = 0
  
  client.domains.list do |response, current_page|
    domains = response.data[:domains] || []
    total_domains += domains.length
    
    puts "Page #{current_page} of #{response.page_count}"
    puts "Domains on this page: #{domains.length}"
    
    domains.each do |domain|
      puts "  - #{domain[:name]} (expires: #{domain[:expiry_date]})"
    end
    
    puts
  end
  
  puts "Total domains across all pages: #{total_domains}"
rescue Fabulous::Error => e
  puts "Error: #{e.message}"
end

puts "\n=== Fetch Specific Page ==="
begin
  # Method 3: Fetch a specific page
  page_number = 1
  domains_page = client.domains.list(page: page_number)
  
  puts "Domains on page #{page_number}:"
  domains_page.each do |domain|
    puts "  - #{domain[:name]}"
  end
rescue Fabulous::Error => e
  puts "Error: #{e.message}"
end

puts "\n=== Process Domains with Custom Logic ==="
begin
  # Method 4: Process domains with custom filtering
  expiring_soon = []
  auto_renew_disabled = []
  
  client.domains.list do |response, page|
    domains = response.data[:domains] || []
    
    domains.each do |domain|
      # Check if domain expires within 30 days
      if domain[:expiry_date]
        begin
          expiry = Date.parse(domain[:expiry_date])
          days_until_expiry = (expiry - Date.today).to_i
          
          if days_until_expiry <= 30 && days_until_expiry > 0
            expiring_soon << { name: domain[:name], days: days_until_expiry }
          end
        rescue ArgumentError
          # Handle invalid date format
        end
      end
      
      # Check for domains without auto-renew
      unless domain[:auto_renew]
        auto_renew_disabled << domain[:name]
      end
    end
  end
  
  if expiring_soon.any?
    puts "Domains expiring within 30 days:"
    expiring_soon.each do |domain|
      puts "  - #{domain[:name]} (#{domain[:days]} days)"
    end
  else
    puts "No domains expiring within 30 days"
  end
  
  puts
  
  if auto_renew_disabled.any?
    puts "Domains without auto-renew enabled:"
    auto_renew_disabled.each do |domain|
      puts "  - #{domain}"
    end
  else
    puts "All domains have auto-renew enabled"
  end
rescue Fabulous::Error => e
  puts "Error: #{e.message}"
end