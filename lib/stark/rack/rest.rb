require 'rack/request'
require 'rack/utils/okjson'
require 'stark/rack'

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
        env['stark.protocol.factory'] = VerboseProtocolFactory.new
        create_thrift_call_from_params env
      end
      status, headers, body = @app.call env
      [status, headers, unmarshal_result(env, body)]
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

    def decode_thrift_proto(proto, type)
      case type
      when Thrift::Types::BOOL
        proto.read_bool
      when Thrift::Types::BYTE
        proto.read_i8
      when Thrift::Types::I16
        proto.read_i16
      when Thrift::Types::I32
        proto.read_i32
      when Thrift::Types::I64
        proto.read_i64
      when Thrift::Types::DOUBLE
        proto.read_double
      when Thrift::Types::STRING
        proto.read_string
      when Thrift::Types::STRUCT
        Hash.new.tap do |hash|
          proto.read_struct_begin
          while true
            name, type, id = proto.read_field_begin
            break if type == Thrift::Types::STOP
            hash[(name || id).to_s] = decode_thrift_proto proto, type
            proto.read_field_end
          end
          proto.read_struct_end
        end
      when Thrift::Types::MAP
        Hash.new.tap do |hash|
          kt, vt, size = proto.read_map_begin
          size.times do
            hash[decode_thrift_proto(proto, kt).to_s] = decode_thrift_proto(proto, vt)
          end
          proto.read_map_end
        end
      when Thrift::Types::SET
        Set.new.tap do |set|
          vt, size = proto.read_set_begin
          size.times do
            set << decode_thrift_proto(proto, vt)
          end
          proto.read_set_end
        end
      when Thrift::Types::LIST
        Array.new.tap do |list|
          vt, size = proto.read_list_begin
          size.times do
            list << decode_thrift_proto(proto, vt)
          end
          proto.read_list_end
        end
      when Thrift::Types::STOP
        nil
      else
        raise NotImplementedError, type
      end
    end

    def unmarshal_result(env, body)
      out = StringIO.new(body.join)
      proto = protocol_factory(env).get_protocol(Thrift::IOStreamTransport.new(out, out))
      proto.read_message_begin
      proto.read_struct_begin
      _, type, id = proto.read_field_begin
      result = decode_thrift_proto(proto, type)
      [Rack::Utils::OkJson.encode((id == 0 ? "result" : "error") => result)]
    end
  end
end
