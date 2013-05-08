class Stark::Rack
  class LoggingProcessor
    def initialize(handler, secondary=nil)
      @handler = handler
      @secondary = secondary
    end

    def process(iprot, oprot)
      name, type, seqid = iprot.read_message_begin
      x = nil
      if @handler.respond_to?("process_#{name}")
        begin
          @handler.send("process_#{name}", seqid, iprot, oprot)
        rescue StandardError => e
          Stark.logger.error "#{@handler.class.name}#process_#{name}: #{e.message}\n  " + e.backtrace.join("\n  ")
          x = Thrift::ApplicationException.new(
                           Thrift::ApplicationException::UNKNOWN,
                           "#{e.message} (#{e.class})")
          oprot.write_message_begin(name, Thrift::MessageTypes::EXCEPTION, seqid)
          x.write(oprot)
          oprot.write_message_end
          oprot.trans.flush
        end

        if s = @secondary
          if x
            s.error name, type, seqid, x
          else
            s.success name, type, seqid
          end
        end

        [name, type, seqid, x]
      else
        iprot.skip(Thrift::Types::STRUCT)
        iprot.read_message_end
        x = Thrift::ApplicationException.new(Thrift::ApplicationException::UNKNOWN_METHOD,
                                     "Unknown function: #{name}")
        oprot.write_message_begin(name, Thrift::MessageTypes::EXCEPTION, seqid)
        x.write(oprot)
        oprot.write_message_end
        oprot.trans.flush
        if s = @secondary
          s.error name, type, seqid, x
        end
        false
      end
    end
  end
end
