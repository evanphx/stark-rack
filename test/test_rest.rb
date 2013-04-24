require "test/unit"
require "stark/rack"
require "stark/rack/metadata"
require "stark/rack/rest"
require "helper"

class TestREST < Test::Unit::TestCase
  include TestHelper

  def test_get_last_result
    rack = Stark::Rack::REST.new stark_rack
    @handler.add 2, 2

    out = ['']
    Thread.new do
      env = {'rack.input' => StringIO.new, 'REQUEST_METHOD' => 'GET',
        'PATH_INFO' => '/last_result', 'QUERY_STRING' => ''}

      code, headers, out = rack.call env
    end.join

    json = '{"result":4}'
    assert_equal json, out.join
  end

  def test_store_vars
    rack = Stark::Rack::REST.new stark_rack
    Thread.new do
      env = {'rack.input' => StringIO.new, 'REQUEST_METHOD' => 'GET',
        'PATH_INFO' => '/store_vars', 'QUERY_STRING' => 'a=1&b=2&c=3'}

      code, headers, out = rack.call env
    end.join

    assert_equal 1, @handler.get_var('a')
    assert_equal 2, @handler.get_var('b')
    assert_equal 3, @handler.get_var('c')
  end

  def test_get_var
    rack = Stark::Rack::REST.new stark_rack
    @handler.store_vars 'a' => 42
    out = ['']
    Thread.new do
      env = {'rack.input' => StringIO.new, 'REQUEST_METHOD' => 'GET',
        'PATH_INFO' => '/get_var', 'QUERY_STRING' => 'arg[0]=a'}

      code, headers, out = rack.call env
    end.join

    json = '{"result":42}'
    assert_equal json, out.join
  end

  def test_get_metadata
    metadata = { 'version' => '1.0 baby', 'name' => "This is a sweet service" }
    rack = Stark::Rack::REST.new Stark::Rack::Metadata.new(stark_rack, metadata)

    out = ['']
    Thread.new do
      env = {'rack.input' => StringIO.new, 'REQUEST_METHOD' => 'GET',
        'PATH_INFO' => '/metadata', 'QUERY_STRING' => ''}

      code, headers, out = rack.call env
    end.join

    json = '{"result":{"version":"1.0 baby","name":"This is a sweet service"}}'
    assert_equal json, out.join
  end
end
