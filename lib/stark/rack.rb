require 'stark'

class Stark::Rack
  VERSION = '1.0.0'

  class LoggingProcessor
    def initialize(handler, secondary=nil)
      @handler = handler
      @secondary = secondary
    end

    def process(iprot, oprot)
      name, type, seqid = iprot.read_message_begin
      if @handler.respond_to?("process_#{name}")
        e = nil

        begin
          @handler.send("process_#{name}", seqid, iprot, oprot)
        rescue StandardError => e
          x = Thrift::ApplicationException.new(
                           Thrift::ApplicationException::UNKNOWN,
                           "#{e.message} (#{e.class}")
          oprot.write_message_begin(name, Thrift::MessageTypes::EXCEPTION, seqid)
          x.write(oprot)
          oprot.write_message_end
          oprot.trans.flush
        end

        if s = @secondary
          if e
            s.error name, type, seqid, e
          else
            s.success name, type, seqid
          end
        end

        [name, type, seqid, e]
      else
        iprot.skip(Thrift::Types::STRUCT)
        iprot.read_message_end
        x = Thrift::ApplicationException.new(Thrift::ApplicationException::UNKNOWN_METHOD,
                                     "Unknown function: #{name}")
        oprot.write_message_begin(name, Thrift::MessageTypes::EXCEPTION, seqid)
        x.write(oprot)
        oprot.write_message_end
        oprot.trans.flush
        false
      end
    end
  end

  FORMAT = %{when: %0.4f, client: "%s", path: "%s%s", type: "%s", name: "%s", seqid: %d, error: %s\n}

  TYPES = {
    1 => "CALL",
    2 => "REPLY",
    3 => "EXCEPTION",
    4 => "ONEWAY"
  }

  def initialize(processor, options={})
    @processor = LoggingProcessor.new processor
    @protocol = Thrift::BinaryProtocolFactory.new
    @log = options[:log]
    @logger = STDERR
    @metadata = options[:metadata]
  end

  attr_accessor :log

  def call(env)
    headers = {
      'Content-Type' => "application/x-thrift"
    }

    path = env['REQUEST_PATH'] || "/"

    if path == "/metadata"
      headers['Content-Type'] = "text/plain"

      return [200, headers, [@metadata]]
    end

    out = StringIO.new

    transport = Thrift::IOStreamTransport.new env['rack.input'], out
    protocol = @protocol.get_protocol transport

    if @log
      name, type, seqid, err = @processor.process protocol, protocol

      @logger.write FORMAT % [
        Time.now.to_f,
        env['HTTP_X_FORWARDED_FOR'] || env["REMOTE_ADDR"] || "-",
        env["PATH_INFO"],
        env["QUERY_STRING"].empty? ? "" : "?"+env["QUERY_STRING"],
        TYPES[type],
        name,
        seqid,
        err ? "'#{err.message} (#{err.class})'" : "null"
      ]
    else
      @processor.process protocol, protocol
    end

    [200, headers, [out.string]]
  end
end
