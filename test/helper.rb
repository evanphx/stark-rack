module TestHelper
  class Handler
    def initialize(n)
      @state = n::State.new
    end
    def add(a,b)
      @state.last_result = a + b
    end
    def last_result
      @state.last_result
    end
    def store_vars(hash)
      @state.vars ||= {}
      hash.each do |k,v|
        @state.vars[k] = v.to_i
      end
    end
    def get_var(name)
      @state.vars[name]
    end
    def get_state
      @state
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
    @handler = Handler.new(@n)
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
