require 'stark'
require 'stark/rack/content_negotiation'
require 'stark/rack/logging_processor'

class Stark::Rack

  VERSION = '1.0.0'

  FORMAT = %{when: %0.4f, client: "%s", path: "%s%s", type: "%s", name: "%s", seqid: %d, error: %s\n}

  TYPES = {
    1 => "CALL",
    2 => "REPLY",
    3 => "EXCEPTION",
    4 => "ONEWAY"
  }

  include ContentNegotiation

  def initialize(processor, options={})
    @log = options[:log]
    @logger = STDERR
    @app_processor = processor
  end

  attr_accessor :log

  def processor
    @processor ||= LoggingProcessor.new(@app_processor, error_capture)
  end

  def call(env)
    dup._call(env)
  end

  def _call(env)
    path = env['PATH_INFO'] || ""
    path << "/" if path.empty?

    unless path == "/"
      return [404, {}, ["Nothing at #{path}"]]
    end

    out = StringIO.new

    transport = Thrift::IOStreamTransport.new env['rack.input'], out
    protocol  = protocol_factory(env).get_protocol transport

    if @log
      name, type, seqid, err = processor.process protocol, protocol

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
      processor.process protocol, protocol
    end

    [status_from_last_error, headers(env), [out.string]]
  end

  def error_capture
    lambda do |m,*args|
      @last_error = [m, args]
    end.tap do |x|
      (class << x; self; end).instance_eval {
        alias_method :method_missing, :call }
    end
  end

  def status_from_last_error
    return 200 if @last_error.nil? || @last_error.first == :success
    x = @last_error.last[3]
    case x.type
    when Thrift::ApplicationException::UNKNOWN_METHOD
      404
    else
      500
    end
  end
end
