# Fabulous API Ruby Gem

[![Gem Version](https://badge.fury.io/rb/fabulous.svg)](https://badge.fury.io/rb/fabulous)
[![CI](https://github.com/usiegj00/api-fabulous-com/actions/workflows/ci.yml/badge.svg)](https://github.com/usiegj00/api-fabulous-com/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive Ruby client for the [Fabulous.com API](https://api.fabulous.com/api_reference.html), providing domain management and DNS configuration capabilities.

## Features

- Complete domain management (register, renew, transfer, etc.)
- DNS record management (A, AAAA, CNAME, MX, TXT)
- Automatic pagination support
- Comprehensive error handling
- Ruby 3.0+ support

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fabulous'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install fabulous
```

## CLI Usage

The gem includes a powerful command-line interface for managing your Fabulous.com domains.

### Setup

Create a `.env` file with your credentials:

```bash
FABULOUS_USERNAME=your_username
FABULOUS_PASSWORD=your_password
```

### Commands

#### List domains
```bash
# List all domains (shows name, expiry date)
fabulous list

# Show domains expiring within 30 days
fabulous expiring 30

# Search for specific domains
fabulous search "example"

# Sort and filter options
fabulous list --sort expiry --expiring 90 --limit 50
```

Note: The list command shows basic information (domain name and expiry date). For detailed information including auto-renew status, lock status, and nameservers, use the `info` command.

#### Domain information
```bash
# Get detailed domain info
fabulous info example.com

# Check domain availability
fabulous check newdomain.com
```

#### Portfolio summary
```bash
# Show portfolio statistics
fabulous summary
```

#### Nameserver management
```bash
# Get current nameservers
fabulous nameservers get example.com

# Update nameservers
fabulous nameservers set example.com ns1.cloudflare.com ns2.cloudflare.com
```

#### DNS records
```bash
# List DNS records
fabulous dns list example.com

# Add DNS records interactively
fabulous dns add example.com

# Filter by record type
fabulous dns list example.com --type A
```

### CLI Options

- `--sort [name|expiry|status]` - Sort domains by field
- `--filter STRING` - Filter domains by name
- `--expiring N` - Show domains expiring within N days
- `--limit N` - Number of domains to display
- `--interactive` - Enable interactive pagination
- `--help` - Show help for any command

## Configuration

Configure the gem with your Fabulous.com API credentials:

```ruby
require 'fabulous'

Fabulous.configure do |config|
  config.username = 'your_username'
  config.password = 'your_password'
  
  # Optional settings
  config.timeout = 30        # Request timeout in seconds (default: 30)
  config.open_timeout = 10   # Connection timeout in seconds (default: 10)
end
```

### Environment Variables

You can also use environment variables:

```ruby
Fabulous.configure do |config|
  config.username = ENV['FABULOUS_USERNAME']
  config.password = ENV['FABULOUS_PASSWORD']
end
```

## Usage

### Domain Management

#### List All Domains with Pagination

```ruby
client = Fabulous.client

# Get all domains (auto-paginated)
all_domains = client.domains.all
all_domains.each do |domain|
  puts "#{domain[:name]} - Expires: #{domain[:expiry_date]}"
end

# Manual pagination
client.domains.list do |response, page|
  puts "Page #{page} of #{response.page_count}"
  domains = response.data[:domains]
  domains.each do |domain|
    puts domain[:name]
  end
end

# Get specific page
page_1_domains = client.domains.list(page: 1)
```

#### Check Domain Availability

```ruby
if client.domains.check("example.com")
  puts "Domain is available!"
else
  puts "Domain is taken"
end
```

#### Register a Domain

```ruby
client.domains.register(
  "mynewdomain.com",
  years: 2,
  nameservers: ["ns1.example.com", "ns2.example.com"],
  whois_privacy: true,
  auto_renew: true
)
```

#### Get Domain Information

```ruby
info = client.domains.info("example.com")
puts "Status: #{info[:status]}"
puts "Expires: #{info[:expiry_date]}"
puts "Nameservers: #{info[:nameservers].join(', ')}"
```

### Nameserver Management

#### Get Current Nameservers

```ruby
nameservers = client.domains.get_nameservers("example.com")
nameservers.each { |ns| puts ns }
```

#### Update Nameservers

```ruby
new_nameservers = [
  "ns1.cloudflare.com",
  "ns2.cloudflare.com"
]

client.domains.set_nameservers("example.com", new_nameservers)
```

### DNS Record Management

#### List DNS Records

```ruby
# Get all DNS records
records = client.dns.list_records("example.com")

# Get specific record type
a_records = client.dns.list_records("example.com", type: "A")
```

#### Manage A Records

```ruby
# Add A record
client.dns.add_a_record(
  "example.com",
  hostname: "www",
  ip_address: "192.168.1.1",
  ttl: 3600
)

# Get A records
a_records = client.dns.a_records("example.com")

# Update A record
client.dns.update_a_record(
  "example.com",
  record_id: "123",
  ip_address: "192.168.1.2"
)

# Delete A record
client.dns.delete_a_record("example.com", "123")
```

#### Manage MX Records

```ruby
# Add MX record
client.dns.add_mx_record(
  "example.com",
  hostname: "mail.example.com",
  priority: 10,
  ttl: 3600
)

# Get MX records
mx_records = client.dns.mx_records("example.com")

# Update MX record
client.dns.update_mx_record(
  "example.com",
  record_id: "456",
  priority: 5
)

# Delete MX record
client.dns.delete_mx_record("example.com", "456")
```

#### Manage CNAME Records

```ruby
# Add CNAME record
client.dns.add_cname_record(
  "example.com",
  alias: "blog",
  target: "blog.example.com",
  ttl: 3600
)

# Get CNAME records
cname_records = client.dns.cname_records("example.com")
```

#### Manage TXT Records

```ruby
# Add TXT record (for SPF, DKIM, etc.)
client.dns.add_txt_record(
  "example.com",
  hostname: "@",
  text: "v=spf1 include:_spf.google.com ~all",
  ttl: 3600
)
```

#### Manage AAAA Records (IPv6)

```ruby
# Add AAAA record
client.dns.add_aaaa_record(
  "example.com",
  hostname: "www",
  ipv6_address: "2001:db8::1",
  ttl: 3600
)
```

### Domain Settings

```ruby
# Lock/Unlock domain
client.domains.lock("example.com")
client.domains.unlock("example.com")

# Auto-renewal
client.domains.set_auto_renew("example.com", enabled: true)
client.domains.set_auto_renew("example.com", enabled: false)

# WHOIS Privacy
client.domains.enable_whois_privacy("example.com")
client.domains.disable_whois_privacy("example.com")

# Renew domain
client.domains.renew("example.com", years: 2)

# Transfer domain
client.domains.transfer_in("example.com", "AUTH_CODE_HERE")
```

## Error Handling

The gem provides specific error classes for different scenarios:

```ruby
begin
  client.domains.list
rescue Fabulous::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
rescue Fabulous::RequestError => e
  puts "Bad request: #{e.message} (Code: #{e.code})"
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
```

## Advanced Usage

### Multiple Client Instances

```ruby
# Client for account 1
client1 = Fabulous::Client.new(
  Fabulous::Configuration.new.tap do |c|
    c.username = "user1"
    c.password = "pass1"
  end
)

# Client for account 2
client2 = Fabulous::Client.new(
  Fabulous::Configuration.new.tap do |c|
    c.username = "user2"
    c.password = "pass2"
  end
)
```

### Batch Operations

```ruby
domains_to_update = ["domain1.com", "domain2.com", "domain3.com"]

domains_to_update.each do |domain|
  begin
    client.domains.set_auto_renew(domain, enabled: true)
    puts "✓ Updated #{domain}"
  rescue Fabulous::Error => e
    puts "✗ Failed #{domain}: #{e.message}"
  end
end
```

## Examples

See the `examples/` directory for complete working examples:
- `list_domains.rb` - Domain listing with pagination examples
- `manage_nameservers.rb` - Nameserver management examples
- `complete_examples.rb` - Comprehensive API usage examples

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/fabulous.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).