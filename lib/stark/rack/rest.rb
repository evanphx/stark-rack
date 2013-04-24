require 'rack/request'

class Stark::Rack
  # This enables requests like "GET /foo" to be translated to either a no-args
  # call to the foo method or a single-arg call containing an array or map of
  # the incoming parameters.
  class REST
    include ContentNegotiation

    def initialize(app)
      @app = app
    end

    def call(env)
      if env["REQUEST_METHOD"] == "GET" || env["HTTP_CONTENT_TYPE"] != THRIFT_CONTENT_TYPE
        env["HTTP_ACCEPT"] ||= "application/json"
        create_thrift_call_from_params env
      end
      @app.call env
    end

    def path_to_method_name(path)
      path.split('/')[1].gsub(/[^a-zA-Z0-9_]/, '_')
    end

    def create_thrift_call_from_params(env)
      name = path_to_method_name env['PATH_INFO']
      params = ::Rack::Request.new(env).params
      input = StringIO.new
      proto = protocol_factory(env).get_protocol(Thrift::IOStreamTransport.new(input, input))
      proto.write_message_begin name, Thrift::MessageTypes::CALL, 0
      proto.write_struct_begin "#{name}_args"
      if !params.empty?
        if Hash === params['arg']
          params = params['arg']
          0.upto(params.size - 1) do |i|
            proto.write_field_begin "arg#{i}", Thrift::Types::STRING, i
            proto.write_string params["#{i}"]
            proto.write_field_end
          end
        else
          proto.write_field_begin 'params', Thrift::Types::MAP, 1
          proto.write_map_begin Thrift::Types::STRING, Thrift::Types::STRING, params.size
          params.each do |k,v|
            proto.write_string k
            proto.write_string v
          end
          proto.write_map_end
          proto.write_field_end
        end
      end
      proto.write_field_stop
      proto.write_struct_end
      proto.write_message_end
      proto.trans.flush
      input.rewind
      env['PATH_INFO'] = '/'
      env['rack.input'] = input
    end
  end
end
