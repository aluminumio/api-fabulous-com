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

# Example domain - replace with your actual domain
EXAMPLE_DOMAIN = "example.com"

puts "=== Nameserver Management Examples ==="
puts "Working with domain: #{EXAMPLE_DOMAIN}"
puts

# 1. Check current nameservers
puts "1. Getting current nameservers:"
begin
  current_nameservers = client.domains.get_nameservers(EXAMPLE_DOMAIN)
  
  if current_nameservers && current_nameservers.any?
    puts "Current nameservers for #{EXAMPLE_DOMAIN}:"
    current_nameservers.each_with_index do |ns, index|
      puts "  #{index + 1}. #{ns}"
    end
  else
    puts "No nameservers found or domain not accessible"
  end
rescue Fabulous::Error => e
  puts "Error getting nameservers: #{e.message}"
end

puts

# 2. Update nameservers
puts "2. Updating nameservers:"
begin
  new_nameservers = [
    "ns1.example.com",
    "ns2.example.com",
    "ns3.example.com",
    "ns4.example.com"
  ]
  
  puts "Setting new nameservers:"
  new_nameservers.each_with_index do |ns, index|
    puts "  #{index + 1}. #{ns}"
  end
  
  if client.domains.set_nameservers(EXAMPLE_DOMAIN, new_nameservers)
    puts "✓ Nameservers updated successfully!"
  else
    puts "✗ Failed to update nameservers"
  end
rescue Fabulous::Error => e
  puts "Error updating nameservers: #{e.message}"
end

puts

# 3. Get detailed domain information including nameservers
puts "3. Getting detailed domain information:"
begin
  domain_info = client.domains.info(EXAMPLE_DOMAIN)
  
  if domain_info
    puts "Domain: #{domain_info[:name]}"
    puts "Status: #{domain_info[:status]}"
    puts "Created: #{domain_info[:creation_date]}"
    puts "Expires: #{domain_info[:expiry_date]}"
    puts "Auto-renew: #{domain_info[:auto_renew] ? 'Enabled' : 'Disabled'}"
    puts "Domain lock: #{domain_info[:locked] ? 'Locked' : 'Unlocked'}"
    puts "WHOIS Privacy: #{domain_info[:whois_privacy] ? 'Enabled' : 'Disabled'}"
    
    if domain_info[:nameservers] && domain_info[:nameservers].any?
      puts "Nameservers:"
      domain_info[:nameservers].each_with_index do |ns, index|
        puts "  #{index + 1}. #{ns}"
      end
    end
  else
    puts "Could not retrieve domain information"
  end
rescue Fabulous::Error => e
  puts "Error getting domain info: #{e.message}"
end

puts

# 4. Change nameservers for multiple domains
puts "4. Bulk nameserver update example:"
begin
  # Get list of domains to update
  domains_to_update = ["example1.com", "example2.com", "example3.com"]
  
  # Common nameservers to set for all domains
  common_nameservers = [
    "ns1.cloudflare.com",
    "ns2.cloudflare.com"
  ]
  
  puts "Updating nameservers for multiple domains:"
  
  domains_to_update.each do |domain|
    print "  Updating #{domain}... "
    begin
      if client.domains.set_nameservers(domain, common_nameservers)
        puts "✓ Success"
      else
        puts "✗ Failed"
      end
    rescue Fabulous::Error => e
      puts "✗ Error: #{e.message}"
    end
  end
rescue Fabulous::Error => e
  puts "Error in bulk update: #{e.message}"
end

puts

# 5. Verify nameserver propagation
puts "5. Verify nameserver changes:"
begin
  domain_to_verify = EXAMPLE_DOMAIN
  
  puts "Checking nameservers for #{domain_to_verify}:"
  
  # Get nameservers from API
  api_nameservers = client.domains.get_nameservers(domain_to_verify)
  
  if api_nameservers
    puts "Nameservers according to Fabulous API:"
    api_nameservers.each_with_index do |ns, index|
      puts "  #{index + 1}. #{ns}"
    end
    
    puts "\nNote: DNS propagation can take up to 48 hours to complete worldwide."
    puts "You can check propagation status using online tools like whatsmydns.net"
  else
    puts "Could not retrieve nameserver information"
  end
rescue Fabulous::Error => e
  puts "Error verifying nameservers: #{e.message}"
end

puts

# 6. Example: Switch to popular DNS providers
puts "6. Quick switch to popular DNS providers:"
puts

dns_providers = {
  cloudflare: [
    "ns1.cloudflare.com",
    "ns2.cloudflare.com"
  ],
  google: [
    "ns-cloud-e1.googledomains.com",
    "ns-cloud-e2.googledomains.com",
    "ns-cloud-e3.googledomains.com",
    "ns-cloud-e4.googledomains.com"
  ],
  aws_route53: [
    "ns-123.awsdns-12.com",
    "ns-456.awsdns-34.net",
    "ns-789.awsdns-56.org",
    "ns-012.awsdns-78.co.uk"
  ]
}

puts "Available DNS provider presets:"
dns_providers.each do |provider, nameservers|
  puts "  #{provider}:"
  nameservers.each { |ns| puts "    - #{ns}" }
end

puts "\nExample: To switch to Cloudflare DNS:"
puts "  client.domains.set_nameservers('#{EXAMPLE_DOMAIN}', #{dns_providers[:cloudflare].inspect})"

puts

# 7. Custom nameserver validation
puts "7. Custom nameserver validation example:"
begin
  def validate_nameserver(nameserver)
    # Basic validation - check format
    if nameserver =~ /^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)*$/i
      true
    else
      false
    end
  end
  
  test_nameservers = [
    "ns1.valid-domain.com",
    "ns2.valid-domain.com",
    "invalid nameserver",
    "ns3.valid-domain.com"
  ]
  
  puts "Validating nameservers before update:"
  valid_nameservers = []
  
  test_nameservers.each do |ns|
    if validate_nameserver(ns)
      puts "  ✓ #{ns} - Valid"
      valid_nameservers << ns
    else
      puts "  ✗ #{ns} - Invalid format"
    end
  end
  
  if valid_nameservers.length >= 2
    puts "\nReady to update with #{valid_nameservers.length} valid nameservers"
  else
    puts "\nError: At least 2 valid nameservers required"
  end
rescue => e
  puts "Error in validation: #{e.message}"
end