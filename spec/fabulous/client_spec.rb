# frozen_string_literal: true

require "spec_helper"

RSpec.describe Fabulous::Client do
  let(:client) { test_client }
  
  describe "#initialize" do
    context "with valid configuration" do
      it "creates a client instance" do
        expect(client).to be_a(Fabulous::Client)
      end
      
      it "stores the configuration" do
        expect(client.configuration).to be_a(Fabulous::Configuration)
        expect(client.configuration.username).to eq("test_user")
        expect(client.configuration.password).to eq("test_pass")
      end
    end
    
    context "with invalid configuration" do
      it "raises an error when username is missing" do
        config = Fabulous::Configuration.new
        config.password = "pass"
        
        expect {
          Fabulous::Client.new(config)
        }.to raise_error(Fabulous::ConfigurationError, /Username and password are required/)
      end
      
      it "raises an error when password is missing" do
        config = Fabulous::Configuration.new
        config.username = "user"
        
        expect {
          Fabulous::Client.new(config)
        }.to raise_error(Fabulous::ConfigurationError, /Username and password are required/)
      end
    end
  end
  
  describe "#domains" do
    it "returns a Domain resource instance" do
      expect(client.domains).to be_a(Fabulous::Resources::Domain)
    end
    
    it "memoizes the domain resource" do
      expect(client.domains).to be(client.domains)
    end
  end
  
  describe "#dns" do
    it "returns a DNS resource instance" do
      expect(client.dns).to be_a(Fabulous::Resources::DNS)
    end
    
    it "memoizes the DNS resource" do
      expect(client.dns).to be(client.dns)
    end
  end
  
  describe "#request" do
    let(:api_url) { "https://api.fabulous.com" }
    
    context "with successful response" do
      it "returns a Response object" do
        stub_request(:post, api_url)
          .with(body: hash_including(
            "username" => "test_user",
            "password" => "test_pass",
            "action" => "testAction"
          ))
          .to_return(body: xml_response(200, "Success"))
        
        response = client.request("testAction")
        expect(response).to be_a(Fabulous::Response)
        expect(response.success?).to be true
      end
    end
    
    context "with authentication error" do
      it "raises AuthenticationError" do
        stub_request(:post, api_url)
          .to_return(body: xml_response(301, "Invalid credentials"))
        
        expect {
          client.request("testAction")
        }.to raise_error(Fabulous::AuthenticationError, /Invalid credentials/)
      end
    end
    
    context "with request error" do
      it "raises RequestError" do
        stub_request(:post, api_url)
          .to_return(body: xml_response(400, "Bad request"))
        
        expect {
          client.request("testAction")
        }.to raise_error(Fabulous::RequestError, /Bad request/)
      end
    end
    
    context "with server error" do
      it "raises ResponseError" do
        stub_request(:post, api_url)
          .to_return(body: xml_response(500, "Internal server error"))
        
        expect {
          client.request("testAction")
        }.to raise_error(Fabulous::ResponseError, /Internal server error/)
      end
    end
    
    context "with rate limit error" do
      it "raises RateLimitError" do
        stub_request(:post, api_url)
          .to_return(body: xml_response(689, "Execution time exhausted"))
        
        expect {
          client.request("testAction")
        }.to raise_error(Fabulous::RateLimitError, /Execution time exhausted/)
      end
    end
    
    context "with timeout" do
      it "raises TimeoutError" do
        stub_request(:post, api_url).to_timeout
        
        expect {
          client.request("testAction")
        }.to raise_error(Fabulous::TimeoutError, /Request timed out/)
      end
    end
  end
end