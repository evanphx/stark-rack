require 'stark'
require 'composite_io'

class Stark::Rack
  module Metadata
    DEFAULT_METADATA = { 'version' => Stark::Rack::VERSION }
    METADATA_IDL = "service Metadata {\nmap<string,string> metadata()\n}\n"
    Stark.materialize StringIO.new(METADATA_IDL), Stark::Rack

    def self.new(app, metadata = {})
      Middleware.new app, metadata
    end

    class Middleware
      include ContentNegotiation

      def initialize(app, metadata)
        @app = app
        @handler = Handler.new metadata
        @processor = Processor.new @handler
      end

      def call(env)
        env['rack.input'] = RewindableInput.new(env['rack.input'])
        status, hdr, body = @app.call env

        if status == 404
          env['rack.input'].rewind

          out       = StringIO.new
          transport = Thrift::IOStreamTransport.new env['rack.input'], out
          protocol  = protocol_factory(env).get_protocol transport

          if @processor.process(protocol, protocol)
            return [200, headers(env), [out.string]]
          end
        end

        [status, hdr, body]
      end
    end

    class Handler
      attr_reader :metadata
      def initialize(metadata)
        @metadata = DEFAULT_METADATA.merge(metadata || {})
        @metadata.keys.each do |k|
          unless String === @metadata[k]
            @metadata[k] = @metadata[k].to_s # stringify values
          end
          unless String === k              # stringify keys
            @metadata[k.to_s] = @metadata.delete k
          end
        end
      end
    end

    class RewindableInput
      def initialize(io)
        @io = io
        @buffered = StringIO.new
      end

      def read(n)
        if @io
          @io.read(n).tap do |s|
            if s
              @buffered.write s
            else
              @io.close
              @io = nil
            end
          end
        else
          @buffered.read(n)
        end
      end

      def rewind
        if @io
          @io = CompositeReadIO.new([StringIO.new(@buffered.string), @io])
          @buffered = StringIO.new
        else
          @buffered.rewind
        end
      end
    end
  end
end
