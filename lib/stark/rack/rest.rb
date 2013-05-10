require 'rack/request'
require 'rack/utils/okjson'
require 'stark/rack'

class Stark::Rack
  # This enables requests like "GET /foo" to be translated to either a no-args
  # call to the foo method or a single-arg call containing an array or map of
  # the incoming parameters.
  class REST
    include ContentNegotiation

    # Name of marker key in a hash that indicates it represents a struct. The
    # struct name is the corresponding value.
    STRUCT = '_struct_'

    def initialize(app)
      @app = app
    end

    def call(env)
      if applies?(env)
        env['stark.protocol.factory'] = VerboseProtocolFactory.new
        if send("create_thrift_call_from_#{env['stark.rest.input.format']}", env)
          status, headers, body = @app.call env
          headers["Content-Type"] = 'application/json'
          [status, headers, unmarshal_result(env, body)]
        else
          [400, {}, []]
        end
      else
        @app.call env
      end
    end

    def applies?(env)
      path         = env["PATH_INFO"]
      content_type = env["HTTP_CONTENT_TYPE"]

      if path && path.length > 1 # need a method name
        env['stark.rest.method.name'] = path.split('/')[1].gsub(/[^a-zA-Z0-9_]/, '_')
        if content_type == 'application/json'
          env['stark.rest.input.format'] = 'json'
        elsif env["REQUEST_METHOD"] == "GET" || # pure GET, no body
            # posted content looks like form data
            Rack::Request::FORM_DATA_MEDIA_TYPES.include?(content_type)
          env['stark.rest.input.format'] = 'params'
        end
      end
    end

    def create_thrift_call_from_json(env)
      params = Rack::Utils::OkJson.decode(env['rack.input'].read)
      params = { 'args' => params } if Array === params
      encode_thrift_call env, params
    rescue
      false
    end

    def create_thrift_call_from_params(env)
      encode_thrift_call env, ::Rack::Request.new(env).params
    end

    def encode_thrift_call(env, params)
      name = env['stark.rest.method.name']
      input = StringIO.new
      proto = protocol_factory(env).get_protocol(Thrift::IOStreamTransport.new(input, input))
      proto.write_message_begin name, Thrift::MessageTypes::CALL, 0

      obj = { STRUCT => "#{name}_args" }
      if !params.empty?
        arguments = params['arg'] || params['args']
        if Hash === arguments
          0.upto(arguments.size - 1) do |i|
            obj["arg#{i}"] = arguments["#{i}"]
          end
        elsif Array === arguments
          0.upto(arguments.size - 1) do |i|
            obj["arg#{i}"] = arguments[i]
          end
        else
          obj['arg0'] = params
        end
      end

      encode_thrift_obj proto, obj

      proto.write_message_end
      proto.trans.flush

      input.rewind
      env['rack.input'] = input
      env['PATH_INFO'] = '/'
      env['REQUEST_METHOD'] = 'POST'
      true
    end

    # Determine a thrift type to use from an array of values.
    def value_type(vals)
      types = vals.map {|v| v.class }.uniq

      # Convert everything to string if there isn't a single unique type
      return Thrift::Types::STRING if types.size > 1

      type = types.first

      # Array -> LIST
      return Thrift::Types::LIST if type == Array

      # Hash can be a MAP or STRUCT
      if type == Hash
        if vals.first.has_key?(STRUCT)
          return Thrift::Types::STRUCT
        else
          return Thrift::Types::MAP
        end
      end

      Thrift::Types::STRING
    end

    def encode_thrift_obj(proto, obj)
      case obj
      when Hash
        if struct = obj.delete(STRUCT)
          proto.write_struct_begin struct
          idx = 1
          obj.each do |k,v|
            proto.write_field_begin k, value_type([v]), idx
            encode_thrift_obj proto, v
            proto.write_field_end
            idx += 1
          end
          proto.write_field_stop
          proto.write_struct_end
        else
          proto.write_map_begin Thrift::Types::STRING, value_type(obj.values), obj.size
          obj.each do |k,v|
            proto.write_string k
            encode_thrift_obj proto, v
          end
          proto.write_map_end
        end
      when Array
        proto.write_list_begin value_type(obj), obj.size
        obj.each {|v| encode_thrift_obj proto, v }
        proto.write_list_end
      else
        proto.write_string obj.to_s
      end
    end

    def decode_thrift_obj(proto, type)
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
          struct = proto.read_struct_begin
          hash[STRUCT] = struct if struct
          while true
            name, type, id = proto.read_field_begin
            break if type == Thrift::Types::STOP
            hash[(name || id).to_s] = decode_thrift_obj proto, type
            proto.read_field_end
          end
          proto.read_struct_end
        end
      when Thrift::Types::MAP
        Hash.new.tap do |hash|
          kt, vt, size = proto.read_map_begin
          size.times do
            hash[decode_thrift_obj(proto, kt).to_s] = decode_thrift_obj(proto, vt)
          end
          proto.read_map_end
        end
      when Thrift::Types::SET
        Set.new.tap do |set|
          vt, size = proto.read_set_begin
          size.times do
            set << decode_thrift_obj(proto, vt)
          end
          proto.read_set_end
        end
      when Thrift::Types::LIST
        Array.new.tap do |list|
          vt, size = proto.read_list_begin
          size.times do
            list << decode_thrift_obj(proto, vt)
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
      result = decode_thrift_obj(proto, type)
      [Rack::Utils::OkJson.encode((id == 0 ? "result" : "error") => result)]
    end
  end
end
