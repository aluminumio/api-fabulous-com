# frozen_string_literal: true

require "spec_helper"

RSpec.describe Fabulous::Resources::Domain do
  let(:client) { test_client }
  let(:domain_resource) { described_class.new(client) }
  let(:api_url) { "https://api.fabulous.com" }
  
  describe "#list" do
    let(:domains_xml) do
      <<~XML
        <domains>
          <domain>
            <name>example1.com</name>
            <status>Active</status>
            <expiryDate>2024-12-31</expiryDate>
            <autoRenew>true</autoRenew>
            <locked>false</locked>
          </domain>
          <domain>
            <name>example2.com</name>
            <status>Active</status>
            <expiryDate>2025-01-15</expiryDate>
            <autoRenew>false</autoRenew>
            <locked>true</locked>
          </domain>
        </domains>
      XML
    end
    
    context "without pagination" do
      it "returns all domains" do
        stub_request(:post, api_url)
          .with(body: hash_including("action" => "listDomains", "page" => "1"))
          .to_return(body: xml_response(200, "Success", domains_xml))
        
        domains = domain_resource.list(page: 1)
        
        expect(domains).to be_an(Array)
        expect(domains.length).to eq(2)
        expect(domains[0][:name]).to eq("example1.com")
        expect(domains[1][:name]).to eq("example2.com")
      end
    end
    
    context "with pagination" do
      let(:page1_xml) do
        <<~XML
          <domains>
            <domain><name>domain1.com</name></domain>
          </domains>
          <pagecount>2</pagecount>
          <page>1</page>
        XML
      end
      
      let(:page2_xml) do
        <<~XML
          <domains>
            <domain><name>domain2.com</name></domain>
          </domains>
          <pagecount>2</pagecount>
          <page>2</page>
        XML
      end
      
      it "fetches all pages automatically" do
        stub_request(:post, api_url)
          .with(body: hash_including("action" => "listDomains", "page" => "1"))
          .to_return(body: xml_response(200, "Success", page1_xml))
        
        stub_request(:post, api_url)
          .with(body: hash_including("action" => "listDomains", "page" => "2"))
          .to_return(body: xml_response(200, "Success", page2_xml))
        
        domains = domain_resource.all
        
        expect(domains.length).to eq(2)
        expect(domains[0][:name]).to eq("domain1.com")
        expect(domains[1][:name]).to eq("domain2.com")
      end
    end
  end
  
  describe "#check" do
    it "returns true when domain is available" do
      stub_request(:post, api_url)
        .with(body: hash_including("action" => "checkDomain", "domain" => "available.com"))
        .to_return(body: xml_response(200, "Success", "<availability>true</availability>"))
      
      expect(domain_resource.check("available.com")).to be true
    end
    
    it "returns false when domain is not available" do
      stub_request(:post, api_url)
        .with(body: hash_including("action" => "checkDomain", "domain" => "taken.com"))
        .to_return(body: xml_response(200, "Success", "<availability>false</availability>"))
      
      expect(domain_resource.check("taken.com")).to be false
    end
  end
  
  describe "#info" do
    let(:domain_info_xml) do
      <<~XML
        <domainInfo>
          <name>example.com</name>
          <status>Active</status>
          <creationDate>2020-01-01</creationDate>
          <expiryDate>2025-01-01</expiryDate>
          <nameservers>
            <nameserver>ns1.example.com</nameserver>
            <nameserver>ns2.example.com</nameserver>
          </nameservers>
          <autoRenew>true</autoRenew>
          <locked>false</locked>
          <whoisPrivacy>true</whoisPrivacy>
        </domainInfo>
      XML
    end
    
    it "returns domain information" do
      stub_request(:post, api_url)
        .with(body: hash_including("action" => "domainInfo", "domain" => "example.com"))
        .to_return(body: xml_response(200, "Success", domain_info_xml))
      
      info = domain_resource.info("example.com")
      
      expect(info[:name]).to eq("example.com")
      expect(info[:status]).to eq("Active")
      expect(info[:nameservers]).to eq(["ns1.example.com", "ns2.example.com"])
      expect(info[:auto_renew]).to be true
      expect(info[:locked]).to be false
    end
  end
  
  describe "#register" do
    it "registers a domain successfully" do
      stub_request(:post, api_url)
        .with(body: hash_including(
          "action" => "registerDomain",
          "domain" => "newdomain.com",
          "years" => "2",
          "ns1" => "ns1.example.com",
          "ns2" => "ns2.example.com",
          "whoisPrivacy" => "true",
          "autoRenew" => "false"
        ))
        .to_return(body: xml_response(200, "Success"))
      
      result = domain_resource.register(
        "newdomain.com",
        years: 2,
        nameservers: ["ns1.example.com", "ns2.example.com"],
        whois_privacy: true,
        auto_renew: false
      )
      
      expect(result).to be true
    end
  end
  
  describe "#set_nameservers" do
    it "updates nameservers successfully" do
      stub_request(:post, api_url)
        .with(body: hash_including(
          "action" => "setNameServers",
          "domain" => "example.com",
          "ns1" => "ns1.new.com",
          "ns2" => "ns2.new.com",
          "ns3" => "ns3.new.com"
        ))
        .to_return(body: xml_response(200, "Success"))
      
      result = domain_resource.set_nameservers(
        "example.com",
        ["ns1.new.com", "ns2.new.com", "ns3.new.com"]
      )
      
      expect(result).to be true
    end
  end
  
  describe "#get_nameservers" do
    it "retrieves nameservers from domain info" do
      domain_info_xml = <<~XML
        <domainInfo>
          <nameservers>
            <nameserver>ns1.example.com</nameserver>
            <nameserver>ns2.example.com</nameserver>
          </nameservers>
        </domainInfo>
      XML
      
      stub_request(:post, api_url)
        .with(body: hash_including("action" => "domainInfo"))
        .to_return(body: xml_response(200, "Success", domain_info_xml))
      
      nameservers = domain_resource.get_nameservers("example.com")
      
      expect(nameservers).to eq(["ns1.example.com", "ns2.example.com"])
    end
  end
  
  describe "#lock" do
    it "locks a domain" do
      stub_request(:post, api_url)
        .with(body: hash_including("action" => "lockDomain", "domain" => "example.com"))
        .to_return(body: xml_response(200, "Success"))
      
      expect(domain_resource.lock("example.com")).to be true
    end
  end
  
  describe "#unlock" do
    it "unlocks a domain" do
      stub_request(:post, api_url)
        .with(body: hash_including("action" => "unlockDomain", "domain" => "example.com"))
        .to_return(body: xml_response(200, "Success"))
      
      expect(domain_resource.unlock("example.com")).to be true
    end
  end
  
  describe "#set_auto_renew" do
    it "enables auto-renewal" do
      stub_request(:post, api_url)
        .with(body: hash_including(
          "action" => "setAutoRenew",
          "domain" => "example.com",
          "autoRenew" => "true"
        ))
        .to_return(body: xml_response(200, "Success"))
      
      expect(domain_resource.set_auto_renew("example.com", enabled: true)).to be true
    end
    
    it "disables auto-renewal" do
      stub_request(:post, api_url)
        .with(body: hash_including(
          "action" => "setAutoRenew",
          "domain" => "example.com",
          "autoRenew" => "false"
        ))
        .to_return(body: xml_response(200, "Success"))
      
      expect(domain_resource.set_auto_renew("example.com", enabled: false)).to be true
    end
  end
end