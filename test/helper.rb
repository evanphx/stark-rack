module TestHelper
  class Handler
    def add(a,b)
      @result = a + b
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

  def stark_rack
    @stark_rack ||= Stark::Rack.new(@n::Calc::Processor.new(@handler), :log => false)
  end
end
