require 'log4r'
class Class
  def for_name(klass)
    return TrueClass if klass == 'Boolean'
    return NilClass if klass == 'unit'
    const_get(klass)
  end
end

module Kernel
  alias_method :old_require, :require
  alias_method :old_load, :load
  alias_method :old_require_relative, :require_relative

  def load(name, wrap = false)
    if $LOAD_TO_TYPECHECK
      return if $LOADED_MAP[name]
      to_load = if File.exist?(name)
                  File.absolute_path(name)
                else
                  dir = $LOAD_PATH.detect do |d|
                    File.exist?(File.join(d, name))
                  end
                  return if dir.nil?
                  File.absolute_path(File.join(dir, name))
                end
      if $LOADED_MAP[to_load].nil?
        #puts "** LOADING #{to_load}"
        process_dependency(to_load) { old_load(name, wrap) }
      else
        old_load(name, wrap)
      end
    else
      old_load(name, wrap)
    end
  end

  def require(name)
    if $LOAD_TO_TYPECHECK
      dependency = ["#{name}.rb", name].detect { |f| File.exist?(f) }
      if dependency.nil?
        # system dependency
        old_require(name)
      else
        to_load = File.absolute_path(dependency)
        if $LOADED_MAP[to_load].nil?
          # puts "** REQUIRING #{to_load}"
          process_dependency(to_load) { old_require(name) }
        else
          old_require(name)
        end
      end
    else
      old_require(name)
    end
  end

  def require_relative(name)
    dirs = caller.map do |call|
      file = call.split(':').first
      File.dirname(file)
    end.uniq
    found = dirs.map do |dir|
      File.join(dir, name)
    end.detect do |potential_file|
      (File.exist?(potential_file + '.rb') || File.exist?(potential_file + '.rb'))
    end
    require(found)
  end

  def self.reset_dependencies
    $FILES_TO_TYPECHECK = {}
    $CURRENT_DEPS = $FILES_TO_TYPECHECK
    $LOADED_MAP = {}
  end

  def self.with_dependency_tracking
    $LOAD_TO_TYPECHECK = true
    yield
    $LOAD_TO_TYPECHECK = false
  end

  def self.computed_dependencies(acc = [], graph = $FILES_TO_TYPECHECK)
    graph.each do |(file, deps)|
      acc = computed_dependencies(acc, deps) if deps != {}
      acc << file
    end
    acc
  end

  def process_dependency(to_load)
    $LOADED_MAP[to_load] = true
    $CURRENT_DEPS[to_load] = {}
    old_current_deps = $CURRENT_DEPS
    $CURRENT_DEPS = $CURRENT_DEPS[to_load]
    yield to_load
    $CURRENT_DEPS = old_current_deps
  end
end
Kernel.reset_dependencies

module TypedRb
  def log(client_binding, level, message)
    client = client_binding.receiver
    client_id = if client.instance_of?(Class)
                  if client.name
                    client.name
                  else
                    Class.for_name(client.to_s.match(/Class:(.*)>/)[1]).name
                  end
                else
                  if client.class.name
                    client.class.name
                  else
                    Class.for_name(client.class.to_s.match(/Class:(.*)>/)[1]).name
                  end
                end
    line = client_binding.eval('__LINE__')
    file = client_binding.eval('__FILE__')
    message = "#{file}:#{line}\n  #{message}\n"
    logger('[' + client_id.gsub('::', '/') + ']').send(level, message)
  end

  def logger(client)
    logger = Log4r::Logger[client]
    logger = Log4r::Logger.new(client) if logger.nil?
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
  load(file) if file != __FILE__ && !file.end_with?('lib/typed/prelude.rb')
end
