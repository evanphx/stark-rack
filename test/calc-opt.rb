module Calc
  class Client
    def add(lhs, rhs)
      op = @oprot
      op.write_message_begin 'add', ::Thrift::MessageTypes::CALL, 0
      op.write_struct_begin "add_args"
      op.write_field_begin 'lhs', ::Thrift::Types::I32, 1
      op.write_i32 lhs
      op.write_field_end
      op.write_field_begin 'rhs', ::Thrift::Types::I32, 2
      op.write_i32 rhs
      op.write_field_end
      op.write_field_stop
      op.write_struct_end
      op.write_message_end
      op.trans.flush
      ip = @iprot
      fname, mtype, rseqid = ip.read_message_begin
      handle_exception mtype
      ip.read_struct_begin
      rname, rtype, rid = ip.read_field_begin
      result = ip.read_i32
      rname, rtype, rid = ip.read_field_begin
      fail if rtype != ::Thrift::Types::STOP
      ip.read_field_end
      ip.read_struct_end
      ip.read_message_end
      return result
    end
  end
end
