#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "fabulous"
require "date"
require "dotenv/load"

# Configure the client
Fabulous.configure do |config|
  config.username = ENV["FABULOUS_USERNAME"] || "your_username"
  config.password = ENV["FABULOUS_PASSWORD"] || "your_password"
  # Optional configuration
  config.timeout = 30        # Request timeout in seconds
  config.open_timeout = 10   # Connection open timeout in seconds
end

client = Fabulous.client

puts "=== Fabulous API Ruby Gem - Complete Examples ==="
puts

# ====================
# DOMAIN MANAGEMENT
# ====================

puts "=" * 50
puts "DOMAIN MANAGEMENT EXAMPLES"
puts "=" * 50
puts

# Check domain availability
puts "1. Check domain availability:"
begin
  domains_to_check = ["example123test.com", "google.com", "my-new-domain.net"]

  domains_to_check.each do |domain|
    available = client.domains.check(domain)
    status = available ? "✓ Available" : "✗ Not available"
    puts "  #{domain}: #{status}"
  end
rescue Fabulous::Error => e
  puts "  Error: #{e.message}"
end

puts

# Register a new domain
puts "2. Register a new domain:"
begin
  domain_to_register = "my-awesome-domain.com"

  if client.domains.check(domain_to_register)
    puts "  Registering #{domain_to_register}..."

    success = client.domains.register(
      domain_to_register,
      years: 2,
      nameservers: ["ns1.example.com", "ns2.example.com"],
      whois_privacy: true,
      auto_renew: true
    )

    if success
      puts "  ✓ Domain registered successfully!"
    else
      puts "  ✗ Registration failed"
    end
  else
    puts "  Domain #{domain_to_register} is not available"
  end
rescue Fabulous::Error => e
  puts "  Error: #{e.message}"
end

puts

# Renew domain
puts "3. Renew a domain:"
begin
  domain_to_renew = "example.com"
  years = 1

  puts "  Renewing #{domain_to_renew} for #{years} year(s)..."

  if client.domains.renew(domain_to_renew, years: years)
    puts "  ✓ Domain renewed successfully!"
  else
    puts "  ✗ Renewal failed"
  end
rescue Fabulous::Error => e
  puts "  Error: #{e.message}"
end

puts

# Domain locking
puts "4. Domain lock management:"
begin
  domain = "example.com"

  # Lock domain
  puts "  Locking #{domain}..."
  puts "  ✓ Domain locked" if client.domains.lock(domain)

  # Unlock domain
  puts "  Unlocking #{domain}..."
  puts "  ✓ Domain unlocked" if client.domains.unlock(domain)
rescue Fabulous::Error => e
  puts "  Error: #{e.message}"
end

puts

# Auto-renewal settings
puts "5. Auto-renewal management:"
begin
  domain = "example.com"

  # Enable auto-renewal
  puts "  Enabling auto-renewal for #{domain}..."
  puts "  ✓ Auto-renewal enabled" if client.domains.set_auto_renew(domain, enabled: true)

  # Disable auto-renewal
  puts "  Disabling auto-renewal for #{domain}..."
  puts "  ✓ Auto-renewal disabled" if client.domains.set_auto_renew(domain, enabled: false)
rescue Fabulous::Error => e
  puts "  Error: #{e.message}"
end

puts

# WHOIS Privacy
puts "6. WHOIS Privacy management:"
begin
  domain = "example.com"

  # Enable WHOIS privacy
  puts "  Enabling WHOIS privacy for #{domain}..."
  puts "  ✓ WHOIS privacy enabled" if client.domains.enable_whois_privacy(domain)

  # Disable WHOIS privacy
  puts "  Disabling WHOIS privacy for #{domain}..."
  puts "  ✓ WHOIS privacy disabled" if client.domains.disable_whois_privacy(domain)
rescue Fabulous::Error => e
  puts "  Error: #{e.message}"
end

puts

# ====================
# DNS MANAGEMENT
# ====================

puts "=" * 50
puts "DNS MANAGEMENT EXAMPLES"
puts "=" * 50
puts

domain = "example.com"

# List all DNS records
puts "1. List all DNS records:"
begin
  records = client.dns.list_records(domain)

  if records.any?
    puts "  DNS records for #{domain}:"
    records.each do |record|
      puts "    - Type: #{record[:type]}, Name: #{record[:name]}, Value: #{record[:value]}"
    end
  else
    puts "  No DNS records found"
  end
rescue Fabulous::Error => e
  puts "  Error: #{e.message}"
end

puts

# A Records Management
puts "2. A Records (IPv4):"
begin
  # Add A record
  puts "  Adding A record..."
  if client.dns.add_a_record(
    domain,
    hostname: "www",
    ip_address: "192.168.1.1",
    ttl: 3600
  )
    puts "  ✓ A record added"
  end

  # List A records
  a_records = client.dns.a_records(domain)
  puts "  Current A records:"
  a_records.each do |record|
    puts "    - #{record[:hostname]} -> #{record[:ip_address]} (TTL: #{record[:ttl]})"
  end

  # Update A record (if we have a record ID)
  if a_records.first
    puts "  Updating first A record..."
    if client.dns.update_a_record(
      domain,
      record_id: a_records.first[:id],
      ip_address: "192.168.1.2"
    )
      puts "  ✓ A record updated"
    end
  end
rescue Fabulous::Error => e
  puts "  Error: #{e.message}"
end

puts

# AAAA Records Management (IPv6)
puts "3. AAAA Records (IPv6):"
begin
  # Add AAAA record
  puts "  Adding AAAA record..."
  if client.dns.add_aaaa_record(
    domain,
    hostname: "www",
    ipv6_address: "2001:db8::1",
    ttl: 3600
  )
    puts "  ✓ AAAA record added"
  end

  # List AAAA records
  aaaa_records = client.dns.aaaa_records(domain)
  puts "  Current AAAA records:"
  aaaa_records.each do |record|
    puts "    - #{record[:hostname]} -> #{record[:ipv6_address]} (TTL: #{record[:ttl]})"
  end
rescue Fabulous::Error => e
  puts "  Error: #{e.message}"
end

puts

# CNAME Records Management
puts "4. CNAME Records:"
begin
  # Add CNAME record
  puts "  Adding CNAME record..."
  if client.dns.add_cname_record(
    domain,
    alias_name: "blog",
    target: "blog.example.com",
    ttl: 3600
  )
    puts "  ✓ CNAME record added"
  end

  # List CNAME records
  cname_records = client.dns.cname_records(domain)
  puts "  Current CNAME records:"
  cname_records.each do |record|
    puts "    - #{record[:alias]} -> #{record[:target]} (TTL: #{record[:ttl]})"
  end
rescue Fabulous::Error => e
  puts "  Error: #{e.message}"
end

puts

# MX Records Management
puts "5. MX Records (Mail):"
begin
  # Add MX records for email
  mx_records_to_add = [
    { hostname: "mail.example.com", priority: 10 },
    { hostname: "mail2.example.com", priority: 20 }
  ]

  mx_records_to_add.each do |mx|
    puts "  Adding MX record: #{mx[:hostname]} (priority: #{mx[:priority]})"
    next unless client.dns.add_mx_record(
      domain,
      hostname: mx[:hostname],
      priority: mx[:priority],
      ttl: 3600
    )

    puts "  ✓ MX record added"
  end

  # List MX records
  mx_records = client.dns.mx_records(domain)
  puts "  Current MX records:"
  mx_records.each do |record|
    puts "    - #{record[:hostname]} (Priority: #{record[:priority]}, TTL: #{record[:ttl]})"
  end
rescue Fabulous::Error => e
  puts "  Error: #{e.message}"
end

puts

# TXT Records Management
puts "6. TXT Records:"
begin
  # Add TXT records (SPF, DKIM, etc.)
  txt_records_to_add = [
    { hostname: "@", text: "v=spf1 include:_spf.google.com ~all" },
    { hostname: "_dmarc", text: "v=DMARC1; p=none; rua=mailto:dmarc@example.com" }
  ]

  txt_records_to_add.each do |txt|
    puts "  Adding TXT record for #{txt[:hostname]}"
    next unless client.dns.add_txt_record(
      domain,
      hostname: txt[:hostname],
      text: txt[:text],
      ttl: 3600
    )

    puts "  ✓ TXT record added"
  end

  # List TXT records
  txt_records = client.dns.txt_records(domain)
  puts "  Current TXT records:"
  txt_records.each do |record|
    puts "    - #{record[:hostname]}: \"#{record[:text]}\" (TTL: #{record[:ttl]})"
  end
rescue Fabulous::Error => e
  puts "  Error: #{e.message}"
end

puts

# ====================
# ERROR HANDLING
# ====================

puts "=" * 50
puts "ERROR HANDLING EXAMPLES"
puts "=" * 50
puts

# Handle different types of errors
begin
  # This will fail with authentication error if credentials are invalid
  client.domains.list(page: 1)
rescue Fabulous::AuthenticationError => e
  puts "Authentication failed: #{e.message} (Code: #{e.code})"
rescue Fabulous::RequestError => e
  puts "Request error: #{e.message} (Code: #{e.code})"
rescue Fabulous::ResponseError => e
  puts "Server error: #{e.message} (Code: #{e.code})"
rescue Fabulous::RateLimitError => e
  puts "Rate limit exceeded: #{e.message}"
rescue Fabulous::TimeoutError => e
  puts "Request timed out: #{e.message}"
rescue Fabulous::ConfigurationError => e
  puts "Configuration error: #{e.message}"
rescue Fabulous::Error => e
  puts "General error: #{e.message}"
end

puts

# ====================
# ADVANCED USAGE
# ====================

puts "=" * 50
puts "ADVANCED USAGE EXAMPLES"
puts "=" * 50
puts

# Using multiple client instances with different credentials
puts "1. Multiple client instances:"
begin
  # Client 1 with specific configuration
  Fabulous::Client.new(
    Fabulous::Configuration.new.tap do |c|
      c.username = "user1"
      c.password = "pass1"
      c.timeout = 60
    end
  )

  # Client 2 with different configuration
  Fabulous::Client.new(
    Fabulous::Configuration.new.tap do |c|
      c.username = "user2"
      c.password = "pass2"
      c.timeout = 30
    end
  )

  puts "  Created two separate client instances with different configurations"
rescue Fabulous::Error => e
  puts "  Error: #{e.message}"
end

puts

# Batch operations with progress tracking
puts "2. Batch operations with progress:"
begin
  domains_to_process = ["domain1.com", "domain2.com", "domain3.com"]
  total = domains_to_process.length
  processed = 0

  puts "  Processing #{total} domains..."

  domains_to_process.each do |domain|
    # Perform operation (e.g., enable auto-renewal)
    client.domains.set_auto_renew(domain, enabled: true)
    processed += 1
    progress = (processed.to_f / total * 100).round
    puts "  [#{progress}%] ✓ Processed #{domain}"
  rescue Fabulous::Error => e
    puts "  [ERROR] Failed to process #{domain}: #{e.message}"
  end

  puts "  Completed: #{processed}/#{total} domains processed"
rescue Fabulous::Error => e
  puts "  Error: #{e.message}"
end

puts
puts "=== Examples completed ==="
