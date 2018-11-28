require 'spec_helper'
require 'net/http/tracer'

RSpec.describe Net::Http::Tracer do
  describe "Class Methods" do
    it { should respond_to :instrument }
    it { should respond_to :patch_request }
  end

  describe "tracing requests" do

    before(:context) do
      OpenTracing.global_tracer = OpenTracingTestTracer.build

      Net::Http::Tracer.instrument
    end

    after(:example) do
      OpenTracing.global_tracer.spans.clear
    end

    it "adds spans for GET using a direct method" do
      stub_request(:any, "www.example.com")
      Net::HTTP.get("www.example.com", "/")

      expect(OpenTracing.global_tracer.spans.count).to be > 0
    end

    it "adds spans for POST with URI" do
      stub_request(:any, "www.example.com")
      uri = URI("http://www.example.com/")
      Net::HTTP.post_form(uri, 'q' => 'test')

      expect(OpenTracing.global_tracer.spans.count).to be > 0
    end

    it "adds spans for PUT in block style" do
      stub_request(:any, "www.example.com")
      uri = URI("http://www.example.com/")

      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Put.new uri

        response = http.request request
      end

      expect(OpenTracing.global_tracer.spans.count).to be > 0
    end
  end
end
