require 'log4r'

module TypedRb
  def log(client_binding, level, message)
    client = client_binding.receiver
    client_id = if client.instance_of?(Class)
                  if client.name
                    client.name
                  else
                    Object.const_get(client.to_s.match(/Class:(.*)>/)[1]).name
                  end
                else
                  if client.class.name
                    client.class.name
                  else
                    Object.const_get(client.class.to_s.match(/Class:(.*)>/)[1]).name
                  end
                end
    line = client_binding.eval('__LINE__')
    file = client_binding.eval('__FILE__')
    message = "#{file}:#{line}\n  #{message}\n"
    logger('['+client_id.gsub('::','/')+']').send(level, message)
  end

  def logger(client)
    logger = Log4r::Logger[client]
    if logger.nil?
      logger = Log4r::Logger.new(client)
    end
    logger.outputters = Log4r::Outputter.stdout
    set_level(logger)
    logger
  end

  def set_level(logger)
    logger.level = case (ENV['LOG_LEVEL'] || ENV['log_level'] || '').upcase
                   when 'DEBUG'
                     Log4r::DEBUG
                   when 'INFO'
                     Log4r::INFO
                   when 'WARN'
                     Log4r::WARN
                   when 'ERROR'
                     Log4r::ERROR
                   when 'FATAL'
                     Log4r::FATAL
                   else
                     Log4r::INFO
                   end
  end
end

TypedRb.module_eval do
  module_function(:log)
  public :log
  module_function(:logger)
  public :logger
  module_function(:set_level)
  public :set_level
end

Dir[File.join(File.dirname(__FILE__), '**/*.rb')].each do |file|
  load(file) if file != __FILE__ && !file.end_with?('lib/prelude.rb')
end
