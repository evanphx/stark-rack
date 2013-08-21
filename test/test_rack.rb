require "test/unit"
require "stark/rack"
require "helper"

class TestRack < Test::Unit::TestCase
  include TestHelper


  def test_call_to_thrift
    st = Thread.new do
      env = { 'rack.input' => @sr, 'REQUEST_METHOD' => 'POST' }
      env['PATH_INFO'] = ''

      code, headers, out = stark_rack.call env

      out.each do |s|
        @sw << s
      end
    end

    out = @client.add 3, 4

    assert_equal 7, out
  end

  def test_json_protocol
    @client_p = Thrift::JsonProtocol.new @client_t
    @client = @n::Calc::Client.new @client_p, @client_p

    st = Thread.new do
      env = { 'rack.input' => @sr, 'REQUEST_METHOD' => 'POST' }
      env['PATH_INFO'] = ''
      env['HTTP_CONTENT_TYPE'] = 'application/vnd.thrift+json'

      code, headers, out = stark_rack.call env

      out.each do |s|
        @sw << s
      end
    end

    out = @client.add 3, 4

    assert_equal 7, out
  end

  def test_call_with_wrong_method
    env = { 'REQUEST_METHOD' => 'GET' }
    env['PATH_INFO'] = '/'

    code, headers, out = stark_rack.call env

    assert_equal 405, code
  end

  def test_call_to_undefined_url
    env = { 'REQUEST_METHOD' => 'POST' }
    env['PATH_INFO'] = '/blah'

    code, headers, out = stark_rack.call env

    assert_equal 404, code
  end

  def test_exception_sets_status_and_env_rack_exception
    @client_p = Thrift::JsonProtocol.new @client_t
    @client = @n::Calc::Client.new @client_p, @client_p

    def @handler.add(*)
      raise RangeError, "can't add"
    end


    code = headers = out = nil
    env = { 'rack.input' => @sr, 'REQUEST_METHOD' => 'POST' }
    env['PATH_INFO'] = ''
    env['HTTP_CONTENT_TYPE'] = 'application/vnd.thrift+json'

    st = Thread.new do
      code, headers, out = stark_rack.call env
      out.each do |s|
        @sw << s
      end
    end

    assert_raises Thrift::ApplicationException do
      @client.add 3, 4
    end

    assert_equal RangeError, env['rack.exception'].class
    assert_equal "can't add", env['rack.exception'].to_s
  end

end
