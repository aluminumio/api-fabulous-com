# frozen_string_literal: true

require "thor"
require "tty-table"
require "tty-spinner"
require "tty-prompt"
require "pastel"
require "dotenv/load"
require "date"
require "fabulous"

module Fabulous
  class Nameservers < Thor
    def initialize(*args)
      super
      @pastel = Pastel.new
      configure_client
    end

    desc "get DOMAIN", "Get nameservers for a domain"
    def get(domain_name)
      spinner = TTY::Spinner.new("#{@pastel.cyan('⚡')} Fetching nameservers... ", format: :dots)
      spinner.auto_spin

      begin
        nameservers = client.domains.get_nameservers(domain_name)
        spinner.success(@pastel.green("✓ Found nameservers"))

        puts
        puts @pastel.bold.cyan("Nameservers for #{domain_name}:")
        if nameservers&.any?
          nameservers.each_with_index do |ns, i|
            puts "  #{@pastel.dim("#{i + 1}.")} #{@pastel.white(ns)}"
          end
        else
          puts @pastel.yellow("  No nameservers found")
        end
      rescue Fabulous::Error => e
        spinner.error(@pastel.red("✗ Error: #{e.message}"))
        exit 1
      end
    end

    desc "set DOMAIN NS1 NS2 [NS3...]", "Set nameservers for a domain"
    def set(domain_name, *nameservers)
      if nameservers.length < 2
        puts @pastel.red("✗ Error: At least 2 nameservers required")
        exit 1
      end

      puts @pastel.cyan("Setting nameservers for #{domain_name}:")
      nameservers.each_with_index do |ns, i|
        puts "  #{i + 1}. #{ns}"
      end

      spinner = TTY::Spinner.new("#{@pastel.cyan('⚡')} Updating... ", format: :dots)
      spinner.auto_spin

      begin
        if client.domains.set_nameservers(domain_name, nameservers)
          spinner.success(@pastel.green("✓ Nameservers updated successfully"))
        else
          spinner.error(@pastel.red("✗ Failed to update nameservers"))
        end
      rescue Fabulous::Error => e
        spinner.error(@pastel.red("✗ Error: #{e.message}"))
        exit 1
      end
    end

    private

    def configure_client
      Fabulous.configure do |config|
        config.username = ENV.fetch("FABULOUS_USERNAME", nil)
        config.password = ENV.fetch("FABULOUS_PASSWORD", nil)
      end
    end

    def client
      @client ||= Fabulous.client
    end
  end

  class DNS < Thor
    def initialize(*args)
      super
      @pastel = Pastel.new
      @prompt = TTY::Prompt.new
      configure_client
    end

    desc "list DOMAIN", "List all DNS records for a domain"
    option :type, type: :string, enum: %w[A AAAA CNAME MX TXT], desc: "Filter by record type"
    def list(domain_name)
      spinner = TTY::Spinner.new("#{@pastel.cyan('⚡')} Fetching DNS records... ", format: :dots)
      spinner.auto_spin

      begin
        records = client.dns.list_records(domain_name, type: options[:type])
        spinner.success(@pastel.green("✓ Found #{records.length} records"))

        if records.empty?
          puts @pastel.yellow("No DNS records found")
        else
          display_dns_records(records)
        end
      rescue Fabulous::Error => e
        spinner.error(@pastel.red("✗ Error: #{e.message}"))
        exit 1
      end
    end

    desc "add DOMAIN", "Add a DNS record interactively"
    def add(domain_name)
      type = @prompt.select("Choose record type:", %w[A AAAA CNAME MX TXT])

      case type
      when "A"
        hostname = @prompt.ask("Hostname (e.g., www or @ for root):")
        ip = @prompt.ask("IP Address:")
        ttl = @prompt.ask("TTL:", default: "3600").to_i

        spinner = TTY::Spinner.new("#{@pastel.cyan('⚡')} Adding A record... ", format: :dots)
        spinner.auto_spin

        if client.dns.add_a_record(domain_name, hostname: hostname, ip_address: ip, ttl: ttl)
          spinner.success(@pastel.green("✓ A record added"))
        else
          spinner.error(@pastel.red("✗ Failed to add record"))
        end

      when "MX"
        hostname = @prompt.ask("Mail server hostname:")
        priority = @prompt.ask("Priority:", default: "10").to_i
        ttl = @prompt.ask("TTL:", default: "3600").to_i

        spinner = TTY::Spinner.new("#{@pastel.cyan('⚡')} Adding MX record... ", format: :dots)
        spinner.auto_spin

        if client.dns.add_mx_record(domain_name, hostname: hostname, priority: priority, ttl: ttl)
          spinner.success(@pastel.green("✓ MX record added"))
        else
          spinner.error(@pastel.red("✗ Failed to add record"))
        end

      when "CNAME"
        alias_name = @prompt.ask("Alias (e.g., blog):")
        target = @prompt.ask("Target domain:")
        ttl = @prompt.ask("TTL:", default: "3600").to_i

        spinner = TTY::Spinner.new("#{@pastel.cyan('⚡')} Adding CNAME record... ", format: :dots)
        spinner.auto_spin

        if client.dns.add_cname_record(domain_name, alias_name: alias_name, target: target, ttl: ttl)
          spinner.success(@pastel.green("✓ CNAME record added"))
        else
          spinner.error(@pastel.red("✗ Failed to add record"))
        end

      when "TXT"
        hostname = @prompt.ask("Hostname (@ for root):")
        text = @prompt.ask("Text value:")
        ttl = @prompt.ask("TTL:", default: "3600").to_i

        spinner = TTY::Spinner.new("#{@pastel.cyan('⚡')} Adding TXT record... ", format: :dots)
        spinner.auto_spin

        if client.dns.add_txt_record(domain_name, hostname: hostname, text: text, ttl: ttl)
          spinner.success(@pastel.green("✓ TXT record added"))
        else
          spinner.error(@pastel.red("✗ Failed to add record"))
        end
      end
    rescue Fabulous::Error => e
      puts @pastel.red("✗ Error: #{e.message}")
      exit 1
    end

    private

    def configure_client
      Fabulous.configure do |config|
        config.username = ENV.fetch("FABULOUS_USERNAME", nil)
        config.password = ENV.fetch("FABULOUS_PASSWORD", nil)
      end
    end

    def client
      @client ||= Fabulous.client
    end

    def display_dns_records(records)
      table = TTY::Table.new(
        header: [
          @pastel.bold("Type"),
          @pastel.bold("Name"),
          @pastel.bold("Value"),
          @pastel.bold("TTL"),
          @pastel.bold("Priority")
        ]
      )

      records.each do |record|
        table << [
          dns_type_badge(record[:type]),
          record[:name] || "-",
          truncate(record[:value], 40),
          record[:ttl] || "-",
          record[:priority] || "-"
        ]
      end

      puts
      puts table.render(:unicode, padding: [0, 1], border: { style: :cyan })
    end

    def dns_type_badge(type)
      colors = {
        "A" => :green,
        "AAAA" => :green,
        "CNAME" => :yellow,
        "MX" => :blue,
        "TXT" => :magenta
      }

      color = colors[type] || :white
      @pastel.send(color, type || "?")
    end

    def truncate(text, length)
      return "-" unless text

      text.length > length ? "#{text[0...length]}..." : text
    end
  end

  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    def initialize(*args)
      super
      @pastel = Pastel.new
      @prompt = TTY::Prompt.new
      configure_client
    end

    desc "list", "List all domains in your portfolio"
    option :sort, type: :string, enum: %w[name expiry status], default: "name", desc: "Sort by field"
    option :filter, type: :string, desc: "Filter domains by name (partial match)"
    option :expiring, type: :numeric, desc: "Show domains expiring within N days"
    option :page, type: :numeric, desc: "Show specific page (without pagination)"
    option :limit, type: :numeric, default: 20, desc: "Number of domains per page"
    option :interactive, type: :boolean, default: false, desc: "Enable interactive pagination"
    def list
      spinner = TTY::Spinner.new("#{@pastel.cyan('⚡')} Fetching domains... ", format: :dots)
      spinner.auto_spin

      begin
        domains = if options[:page]
                    client.domains.list(page: options[:page])
                  else
                    client.domains.all
                  end
        spinner.success(@pastel.green("✓ Found #{domains.length} domains"))

        # Apply filters
        if options[:filter]
          domains = domains.select { |d| d[:name].include?(options[:filter]) }
          puts @pastel.yellow("Filtered to #{domains.length} domains matching '#{options[:filter]}'")
        end

        if options[:expiring]
          today = Date.today
          domains = domains.select do |d|
            next false unless d[:expiry_date]

            begin
              expiry = Date.parse(d[:expiry_date])
              days = (expiry - today).to_i
              days.positive? && days <= options[:expiring]
            rescue ArgumentError
              false
            end
          end
          puts @pastel.yellow("Showing #{domains.length} domains expiring within #{options[:expiring]} days")
        end

        # Sort domains
        domains = sort_domains(domains, options[:sort])

        # Display domains
        if domains.empty?
          puts @pastel.yellow("No domains found matching your criteria")
        else
          display_domains_table(domains, options[:limit], options[:interactive])
        end
      rescue Fabulous::Error => e
        spinner.error(@pastel.red("✗ Error: #{e.message}"))
        exit 1
      end
    end

    desc "info DOMAIN", "Show detailed information about a domain"
    def info(domain_name)
      spinner = TTY::Spinner.new("#{@pastel.cyan('⚡')} Fetching domain info... ", format: :dots)
      spinner.auto_spin

      begin
        info = client.domains.info(domain_name)

        if info.nil?
          spinner.error(@pastel.red("✗ Domain not found or no information available"))
          exit 1
        end

        spinner.success(@pastel.green("✓ Domain found"))

        puts
        puts @pastel.bold.cyan("═" * 60)
        puts @pastel.bold.white("  Domain Information: #{domain_name}")
        puts @pastel.bold.cyan("═" * 60)
        puts

        display_info_item("Status", info[:status] || "Active", status_color(info[:status]))
        display_info_item("Created", info[:creation_date] || "-")
        display_info_item("Expires", info[:expiry_date] || "-", expiry_color(info[:expiry_date]))
        display_info_item("Auto-Renew", if info[:auto_renew].nil?
                                          "-"
                                        else
                                          (info[:auto_renew] ? "Enabled" : "Disabled")
                                        end,
                          info[:auto_renew] ? :green : nil)
        display_info_item("Domain Lock", if info[:locked].nil?
                                           "-"
                                         else
                                           (info[:locked] ? "Locked" : "Unlocked")
                                         end,
                          info[:locked] ? :green : nil)
        display_info_item("WHOIS Privacy", if info[:whois_privacy].nil?
                                             "-"
                                           else
                                             (info[:whois_privacy] ? "Enabled" : "Disabled")
                                           end,
                          info[:whois_privacy] ? :green : nil)

        if info[:nameservers]&.any?
          puts
          puts @pastel.bold.cyan("Nameservers:")
          info[:nameservers].each_with_index do |ns, i|
            puts "  #{@pastel.dim("#{i + 1}.")} #{@pastel.white(ns)}"
          end
        end

        puts
        puts @pastel.cyan("─" * 60)
      rescue Fabulous::Error => e
        spinner.error(@pastel.red("✗ Error: #{e.message}"))
        exit 1
      end
    end

    desc "search QUERY", "Search for domains"
    def search(query)
      invoke :list, [], filter: query
    end

    desc "expiring [DAYS]", "Show domains expiring soon"
    def expiring(days = 30)
      invoke :list, [], expiring: days.to_i
    end

    desc "nameservers SUBCOMMAND ...ARGS", "Manage nameservers"
    subcommand "nameservers", Nameservers

    desc "dns SUBCOMMAND ...ARGS", "Manage DNS records"
    subcommand "dns", DNS

    desc "check DOMAIN", "Check if a domain is available"
    def check(domain_name)
      spinner = TTY::Spinner.new("#{@pastel.cyan('⚡')} Checking availability... ", format: :dots)
      spinner.auto_spin

      begin
        available = client.domains.check(domain_name)

        if available
          spinner.success(@pastel.green("✓ #{domain_name} is available!"))
        else
          spinner.stop(@pastel.yellow("✗ #{domain_name} is not available"))
        end
      rescue Fabulous::Error => e
        spinner.error(@pastel.red("✗ Error: #{e.message}"))
        exit 1
      end
    end

    desc "summary", "Show portfolio summary"
    def summary
      spinner = TTY::Spinner.new("#{@pastel.cyan('⚡')} Analyzing portfolio... ", format: :dots)
      spinner.auto_spin

      begin
        domains = client.domains.all
        spinner.success(@pastel.green("✓ Analysis complete"))

        puts
        puts @pastel.bold.cyan("═" * 60)
        puts @pastel.bold.white("  Portfolio Summary")
        puts @pastel.bold.cyan("═" * 60)
        puts

        # Total domains
        puts "#{@pastel.bold('Total Domains:')} #{@pastel.cyan(domains.length.to_s)}"
        puts

        # Group by year
        by_year = domains.group_by do |d|
          Date.parse(d[:expiry_date]).year
        rescue StandardError
          "Unknown"
        end

        puts @pastel.bold("Domains by Expiry Year:")
        by_year.sort.each do |year, year_domains|
          bar_length = (year_domains.length.to_f / domains.length * 30).round
          bar = "█" * bar_length
          puts "  #{year}: #{@pastel.cyan(bar)} #{year_domains.length}"
        end

        # Expiring soon
        today = Date.today
        expiring_30 = domains.count do |d|
          next false unless d[:expiry_date]

          begin
            expiry = Date.parse(d[:expiry_date])
            days = (expiry - today).to_i
            days.positive? && days <= 30
          rescue StandardError
            false
          end
        end

        expiring_90 = domains.count do |d|
          next false unless d[:expiry_date]

          begin
            expiry = Date.parse(d[:expiry_date])
            days = (expiry - today).to_i
            days.positive? && days <= 90
          rescue StandardError
            false
          end
        end

        puts
        puts @pastel.bold("Expiring Soon:")
        puts "  Next 30 days: #{color_expiry_count(expiring_30)}"
        puts "  Next 90 days: #{color_expiry_count(expiring_90)}"

        puts
        puts @pastel.cyan("─" * 60)
      rescue Fabulous::Error => e
        spinner.error(@pastel.red("✗ Error: #{e.message}"))
        exit 1
      end
    end

    desc "version", "Show version"
    def version
      puts "Fabulous CLI v#{Fabulous::VERSION}"
    end

    private

    def configure_client
      Fabulous.configure do |config|
        config.username = ENV.fetch("FABULOUS_USERNAME", nil)
        config.password = ENV.fetch("FABULOUS_PASSWORD", nil)
      end

      return if Fabulous.configuration.valid?

      puts @pastel.red("✗ Error: Missing credentials")
      puts "Please set FABULOUS_USERNAME and FABULOUS_PASSWORD environment variables"
      puts "You can create a .env file with:"
      puts "  FABULOUS_USERNAME=your_username"
      puts "  FABULOUS_PASSWORD=your_password"
      exit 1
    end

    def client
      @client ||= Fabulous.client
    end

    def sort_domains(domains, sort_by)
      case sort_by
      when "expiry"
        domains.sort_by { |d| d[:expiry_date] || "9999-12-31" }
      when "status"
        domains.sort_by { |d| d[:status] || "Unknown" }
      else # name
        domains.sort_by { |d| d[:name] }
      end
    end

    def display_domains_table(domains, limit, interactive = false)
      if interactive
        display_domains_interactive(domains, limit)
      else
        # Non-interactive display - show all or limited number
        display_limit = limit || domains.length
        domains_to_show = domains.first(display_limit)

        table = TTY::Table.new(
          header: [
            @pastel.bold("Domain"),
            @pastel.bold("Status"),
            @pastel.bold("Expires"),
            @pastel.bold("Days Left")
          ]
        )

        Date.today
        domains_to_show.each do |domain|
          days_left = calculate_days_left(domain[:expiry_date])

          table << [
            @pastel.white(domain[:name]),
            status_badge(domain[:status]),
            domain[:expiry_date] || "-",
            days_left_badge(days_left)
          ]
        end

        puts
        puts table.render(:unicode, padding: [0, 1], border: { style: :cyan })

        if domains.length > display_limit
          puts
          puts @pastel.dim("Showing #{display_limit} of #{domains.length} domains (use --limit to show more)")
        end
      end
    end

    def display_domains_interactive(domains, limit)
      pages = (domains.length.to_f / limit).ceil
      current_page = 0

      loop do
        start_idx = current_page * limit
        end_idx = start_idx + limit
        page_domains = domains[start_idx...end_idx]

        table = TTY::Table.new(
          header: [
            @pastel.bold("Domain"),
            @pastel.bold("Status"),
            @pastel.bold("Expires"),
            @pastel.bold("Days Left")
          ]
        )

        Date.today
        page_domains.each do |domain|
          days_left = calculate_days_left(domain[:expiry_date])

          table << [
            @pastel.white(domain[:name]),
            status_badge(domain[:status]),
            domain[:expiry_date] || "-",
            days_left_badge(days_left)
          ]
        end

        puts
        puts table.render(:unicode, padding: [0, 1], border: { style: :cyan })

        break unless pages > 1

        puts
        puts @pastel.dim("Page #{current_page + 1} of #{pages} (#{domains.length} total domains)")

        choices = []
        choices << "Next page" if current_page < pages - 1
        choices << "Previous page" if current_page.positive?
        choices << "Exit"

        choice = @prompt.select("Navigate:", choices, cycle: true)

        case choice
        when "Next page"
          current_page += 1
        when "Previous page"
          current_page -= 1
        when "Exit"
          break
        end
      end
    end

    def calculate_days_left(expiry_date)
      return nil unless expiry_date

      begin
        expiry = Date.parse(expiry_date)
        (expiry - Date.today).to_i
      rescue ArgumentError
        nil
      end
    end

    def days_left_badge(days)
      return "-" if days.nil?

      if days.negative?
        @pastel.red("Expired")
      elsif days <= 30
        @pastel.red("#{days}d")
      elsif days <= 90
        @pastel.yellow("#{days}d")
      else
        @pastel.green("#{days}d")
      end
    end

    def status_badge(status)
      case status&.downcase
      when "active"
        @pastel.green("● Active")
      when "inactive"
        @pastel.red("● Inactive")
      when "pending"
        @pastel.yellow("● Pending")
      else
        @pastel.dim("● #{status || 'Unknown'}")
      end
    end

    def display_info_item(label, value, color = nil)
      formatted_value = value || "-"
      formatted_value = @pastel.send(color, formatted_value) if color
      puts "  #{@pastel.bold(label.ljust(15))} #{formatted_value}"
    end

    def status_color(status)
      case status&.downcase
      when "active" then :green
      when "inactive" then :red
      when "pending" then :yellow
      end
    end

    def expiry_color(expiry_date)
      days = calculate_days_left(expiry_date)
      return nil unless days

      if days.negative?
        :red
      elsif days <= 30
        :red
      elsif days <= 90
        :yellow
      else
        :green
      end
    end

    def color_expiry_count(count)
      if count.zero?
        @pastel.green(count.to_s)
      elsif count <= 5
        @pastel.yellow(count.to_s)
      else
        @pastel.red(count.to_s)
      end
    end
  end
end
