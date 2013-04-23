require "test/unit"
require "stark/rack"

class TestRack < Test::Unit::TestCase
  class Handler
    def add(a,b)
      a + b
    end
  end

  def setup
    @n = Module.new

    Stark.materialize File.expand_path("../calc.thrift", __FILE__), @n

    @sr, @cw = IO.pipe
    @cr, @sw = IO.pipe

    @client_t = Thrift::IOStreamTransport.new @cr, @cw
    @client_p = Thrift::BinaryProtocol.new @client_t

    @client = @n::Calc::Client.new @client_p, @client_p
    @handler = Handler.new
  end

  def teardown
    @client_t.close
    @sr.close
    @sw.close
  end

  def test_call_to_thrift
    rack = Stark::Rack.new @n::Calc::Processor.new(@handler), :log => false

    st = Thread.new do
      env = { 'rack.input' => @sr }
      env['PATH_INFO'] = ''

      code, headers, out = rack.call env

      out.each do |s|
        @sw << s
      end
    end

    out = @client.add 3, 4

    assert_equal 7, out
  end

  def test_call_to_metadata
    metadata = "This is a sweet service"
    opts = { :log => false, :metadata => metadata }
    rack = Stark::Rack.new @n::Calc::Processor.new(@handler), opts

    env = {}
    env['PATH_INFO'] = '/metadata'

    code, headers, out = rack.call env

    assert_equal metadata, out.first
  end

  def test_call_to_undefined_url
    opts = { :log => false }
    rack = Stark::Rack.new @n::Calc::Processor.new(@handler), opts

    env = {}
    env['PATH_INFO'] = '/blah'

    code, headers, out = rack.call env

    assert_equal 404, code
  end
end
