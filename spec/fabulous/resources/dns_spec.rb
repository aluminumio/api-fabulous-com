# frozen_string_literal: true

require "spec_helper"

RSpec.describe Fabulous::Resources::DNS do
  let(:client) { test_client }
  let(:dns_resource) { described_class.new(client) }
  let(:api_url) { "https://api.fabulous.com" }
  let(:domain) { "example.com" }

  describe "#list_records" do
    let(:dns_records_xml) do
      <<~XML
        <dnsrecords>
          <dnsrecord>
            <id>1</id>
            <type>A</type>
            <name>www</name>
            <value>192.168.1.1</value>
            <ttl>3600</ttl>
          </dnsrecord>
          <dnsrecord>
            <id>2</id>
            <type>MX</type>
            <name>@</name>
            <value>mail.example.com</value>
            <ttl>3600</ttl>
            <priority>10</priority>
          </dnsrecord>
        </dnsrecords>
      XML
    end

    it "returns all DNS records" do
      stub_request(:get, "#{api_url}/listDNSrecords")
        .with(query: hash_including("username" => "test_user", "password" => "test_pass", "domain" => domain))
        .to_return(body: xml_response(200, "Success", dns_records_xml))

      records = dns_resource.list_records(domain)

      expect(records).to be_an(Array)
      expect(records.length).to eq(2)
      expect(records[0][:type]).to eq("A")
      expect(records[1][:type]).to eq("MX")
    end

    it "filters by record type" do
      stub_request(:get, "#{api_url}/listDNSrecords")
        .with(query: hash_including("username" => "test_user", "password" => "test_pass", "domain" => domain,
                                    "type" => "A"))
        .to_return(body: xml_response(200, "Success"))

      dns_resource.list_records(domain, type: "A")
    end
  end

  describe "MX Records" do
    let(:mx_records_xml) do
      <<~XML
        <mxrecords>
          <mxrecord>
            <id>1</id>
            <hostname>mail1.example.com</hostname>
            <priority>10</priority>
            <ttl>3600</ttl>
          </mxrecord>
          <mxrecord>
            <id>2</id>
            <hostname>mail2.example.com</hostname>
            <priority>20</priority>
            <ttl>3600</ttl>
          </mxrecord>
        </mxrecords>
      XML
    end

    describe "#mx_records" do
      it "returns MX records" do
        stub_request(:get, "#{api_url}/getMXRecords")
          .with(query: hash_including("username" => "test_user", "password" => "test_pass", "domain" => domain))
          .to_return(body: xml_response(200, "Success", mx_records_xml))

        records = dns_resource.mx_records(domain)

        expect(records.length).to eq(2)
        expect(records[0][:hostname]).to eq("mail1.example.com")
        expect(records[0][:priority]).to eq(10)
      end
    end

    describe "#add_mx_record" do
      it "adds an MX record" do
        stub_request(:get, "#{api_url}/addMXRecord")
          .with(query: hash_including("username" => "test_user", "password" => "test_pass", "domain" => domain,
                                      "hostname" => "mail.example.com", "priority" => "10", "ttl" => "3600"))
          .to_return(body: xml_response(200, "Success"))

        result = dns_resource.add_mx_record(
          domain,
          hostname: "mail.example.com",
          priority: 10,
          ttl: 3600
        )

        expect(result).to be true
      end
    end

    describe "#update_mx_record" do
      it "updates an MX record" do
        stub_request(:get, "#{api_url}/updateMXRecord")
          .with(query: hash_including("username" => "test_user", "password" => "test_pass", "domain" => domain,
                                      "recordId" => "123", "priority" => "5"))
          .to_return(body: xml_response(200, "Success"))

        result = dns_resource.update_mx_record(
          domain,
          record_id: "123",
          priority: 5
        )

        expect(result).to be true
      end
    end

    describe "#delete_mx_record" do
      it "deletes an MX record" do
        stub_request(:get, "#{api_url}/deleteMXRecord")
          .with(query: hash_including("username" => "test_user", "password" => "test_pass", "domain" => domain,
                                      "recordId" => "123"))
          .to_return(body: xml_response(200, "Success"))

        result = dns_resource.delete_mx_record(domain, "123")

        expect(result).to be true
      end
    end
  end

  describe "A Records" do
    let(:a_records_xml) do
      <<~XML
        <arecords>
          <arecord>
            <id>1</id>
            <hostname>www</hostname>
            <ipAddress>192.168.1.1</ipAddress>
            <ttl>3600</ttl>
          </arecord>
        </arecords>
      XML
    end

    describe "#a_records" do
      it "returns A records" do
        stub_request(:get, "#{api_url}/getARecords")
          .with(query: hash_including("username" => "test_user", "password" => "test_pass", "domain" => domain))
          .to_return(body: xml_response(200, "Success", a_records_xml))

        records = dns_resource.a_records(domain)

        expect(records.length).to eq(1)
        expect(records[0][:hostname]).to eq("www")
        expect(records[0][:ip_address]).to eq("192.168.1.1")
      end
    end

    describe "#add_a_record" do
      it "adds an A record" do
        stub_request(:get, "#{api_url}/addARecord")
          .with(query: hash_including("username" => "test_user", "password" => "test_pass", "domain" => domain,
                                      "hostname" => "www", "ipAddress" => "192.168.1.1", "ttl" => "3600"))
          .to_return(body: xml_response(200, "Success"))

        result = dns_resource.add_a_record(
          domain,
          hostname: "www",
          ip_address: "192.168.1.1",
          ttl: 3600
        )

        expect(result).to be true
      end
    end
  end

  describe "CNAME Records" do
    let(:cname_records_xml) do
      <<~XML
        <cnamerecords>
          <cnamerecord>
            <id>1</id>
            <alias>blog</alias>
            <target>blog.example.com</target>
            <ttl>3600</ttl>
          </cnamerecord>
        </cnamerecords>
      XML
    end

    describe "#cname_records" do
      it "returns CNAME records" do
        stub_request(:get, "#{api_url}/getCNAMERecords")
          .with(query: hash_including("username" => "test_user", "password" => "test_pass", "domain" => domain))
          .to_return(body: xml_response(200, "Success", cname_records_xml))

        records = dns_resource.cname_records(domain)

        expect(records.length).to eq(1)
        expect(records[0][:alias]).to eq("blog")
        expect(records[0][:target]).to eq("blog.example.com")
      end
    end

    describe "#add_cname_record" do
      it "adds a CNAME record" do
        stub_request(:get, "#{api_url}/addCNAMERecord")
          .with(query: hash_including("username" => "test_user", "password" => "test_pass", "domain" => domain,
                                      "alias" => "blog", "target" => "blog.example.com", "ttl" => "3600"))
          .to_return(body: xml_response(200, "Success"))

        result = dns_resource.add_cname_record(
          domain,
          alias_name: "blog",
          target: "blog.example.com",
          ttl: 3600
        )

        expect(result).to be true
      end
    end
  end

  describe "TXT Records" do
    describe "#add_txt_record" do
      it "adds a TXT record" do
        stub_request(:get, "#{api_url}/addTXTRecord")
          .with(query: hash_including("username" => "test_user", "password" => "test_pass", "domain" => domain,
                                      "hostname" => "@", "text" => "v=spf1 include:_spf.google.com ~all",
                                      "ttl" => "3600"))
          .to_return(body: xml_response(200, "Success"))

        result = dns_resource.add_txt_record(
          domain,
          hostname: "@",
          text: "v=spf1 include:_spf.google.com ~all",
          ttl: 3600
        )

        expect(result).to be true
      end
    end
  end

  describe "AAAA Records (IPv6)" do
    describe "#add_aaaa_record" do
      it "adds an AAAA record" do
        stub_request(:get, "#{api_url}/addAAAARecord")
          .with(query: hash_including("username" => "test_user", "password" => "test_pass", "domain" => domain,
                                      "hostname" => "www", "ipv6Address" => "2001:db8::1", "ttl" => "3600"))
          .to_return(body: xml_response(200, "Success"))

        result = dns_resource.add_aaaa_record(
          domain,
          hostname: "www",
          ipv6_address: "2001:db8::1",
          ttl: 3600
        )

        expect(result).to be true
      end
    end
  end
end
