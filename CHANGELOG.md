# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2025-08-13

### Added
- Initial release of the Fabulous Ruby gem
- Complete domain management API support
  - List domains with pagination
  - Check domain availability
  - Register, renew, and transfer domains
  - Get/set nameservers
  - Domain locking/unlocking
  - Auto-renewal settings
  - WHOIS privacy management
- Full DNS record management
  - A, AAAA, CNAME, MX, and TXT records
  - CRUD operations for all record types
- Command-line interface (CLI)
  - Beautiful terminal UI with colored output
  - Domain listing with filtering and sorting
  - Portfolio summary with statistics
  - Interactive DNS record management
  - Nameserver management commands
- Automatic pagination support for large portfolios
- Comprehensive error handling
- Environment variable support via .env files
- Full test suite with RSpec
