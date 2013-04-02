require 'thrift/rack'

$:.unshift File.expand_path("../gen-rb", __FILE__)

require 'calc'

class CalcImpl
  def add(lhs, rhs)
    lhs + rhs
  end
end

impl = CalcImpl.new

processor = Calc::Processor.new impl

obj = Thrift::Rack.new processor

run obj
