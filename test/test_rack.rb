require "test/unit"
require "stark/rack"
require "helper"

class TestRack < Test::Unit::TestCase
  include TestHelper

  def test_call_to_thrift
    st = Thread.new do
      env = { 'rack.input' => @sr }
      env['PATH_INFO'] = ''

      code, headers, out = stark_rack.call env

      out.each do |s|
        @sw << s
      end
    end

    out = @client.add 3, 4

    assert_equal 7, out
  end

  def test_call_to_undefined_url
    env = {}
    env['PATH_INFO'] = '/blah'

    code, headers, out = stark_rack.call env

    assert_equal 404, code
  end

end
