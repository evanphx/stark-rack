require "test/unit"
require "stark/rack"
require "stark/rack/metadata"
require "helper"

class TestMetadata < Test::Unit::TestCase
  include TestHelper

  def setup
    super
    @metadata = { 'version' => '1.0 baby', 'name' => "This is a sweet service" }
    @rack = Stark::Rack::Metadata.new stark_rack, @metadata
  end

  def test_call_to_metadata
    @client = Stark::Rack::Metadata::Client.new @client_p, @client_p
    st = Thread.new do
      env = { 'rack.input' => @sr, 'PATH_INFO' => '/metadata', 'REQUEST_METHOD' => 'POST' }
      code, headers, out = @rack.call env

      out.each do |s|
        @sw << s
      end
    end

    assert_equal @metadata, @client.metadata
  end

  def test_call_add_passes_through_metadata
    st = Thread.new do
      env = { 'rack.input' => @sr, 'PATH_INFO' => '/', 'REQUEST_METHOD' => 'POST' }
      code, headers, out = @rack.call env

      out.each do |s|
        @sw << s
      end
    end

    result = @client.add 1, 1
    assert_equal 2, result
  end

end
