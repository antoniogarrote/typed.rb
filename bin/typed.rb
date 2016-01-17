#!/usr/bin/env ruby
# encoding: utf-8
require 'pry'
require_relative '../lib/typed'
require 'benchmark'
require 'set'
require 'optparse'

class OptionsParser
  class << self
    def parse(options)
      args = { :dynamic_warnings => false }


      opt_parser = OptionParser.new do |opts|
        opts.banner = 'Usage: typed.rb [options] [path]'

        opts.on('-m', '--missing-type', 'Produce warnings when a missing type annotation has been detected') do |m|
          args[:dynamic_warnings] = true
        end

        opts.on('-h', '--help', 'Prints this help') do
          puts opts
          exit
        end
      end

      opt_parser.parse!(options)

      args
    end
  end
end

class TargetFinder
  # Generate a list of target files by expanding globbing patterns
  # (if any). If args is empty, recursively find all Ruby source
  # files under the current directory
  # @return [Array] array of file paths
  def find(args)
    return target_files_in_dir if args.empty?

    files = []

    args.uniq.each do |arg|
      files += if File.directory?(arg)
                 target_files_in_dir(arg.chomp(File::SEPARATOR))
               else
                 process_explicit_path(arg)
               end
    end

    files.map { |f| File.expand_path(f) }.uniq
  end

  # Finds all Ruby source files under the current or other supplied
  # directory. A Ruby source file is defined as a file with the `.rb`
  # extension or a file with no extension that has a ruby shebang line
  # as its first line.
  # It is possible to specify includes and excludes using the config file,
  # so you can include other Ruby files like Rakefiles and gemspecs.
  # @param base_dir Root directory under which to search for
  #   ruby source files
  # @return [Array] Array of filenames
  def target_files_in_dir(base_dir = Dir.pwd)
    # Support Windows: Backslashes from command-line -> forward slashes
    base_dir.gsub!(File::ALT_SEPARATOR, File::SEPARATOR) if File::ALT_SEPARATOR
    all_files = find_files(base_dir, File::FNM_DOTMATCH)
    hidden_files = Set.new(all_files - find_files(base_dir, 0))

    target_files = all_files.select do |file|
      to_inspect?(file, hidden_files)
    end

    target_files
  end

  def to_inspect?(file, hidden_files)
    unless hidden_files.include?(file)
      return true if File.extname(file) == '.rb'
      return true if ruby_executable?(file)
    end
    false
  end

  # Search for files recursively starting at the given base directory using
  # the given flags that determine how the match is made. Excluded files will
  # be removed later by the caller, but as an optimization find_files removes
  # the top level directories that are excluded in configuration in the
  # normal way (dir/**/*).
  def find_files(base_dir, flags)
    wanted_toplevel_dirs = toplevel_dirs(base_dir, flags)
    wanted_toplevel_dirs.map! { |dir| dir << '/**/*' }

    pattern = if wanted_toplevel_dirs.empty?
                # We need this special case to avoid creating the pattern
                # /**/* which searches the entire file system.
                ["#{base_dir}/**/*"]
              else
                # Search the non-excluded top directories, but also add files
                # on the top level, which would otherwise not be found.
                wanted_toplevel_dirs.unshift("#{base_dir}/*")
              end
    Dir.glob(pattern, flags).select { |path| FileTest.file?(path) }
  end

  def toplevel_dirs(base_dir, flags)
    Dir.glob(File.join(base_dir, '*'), flags).select do |dir|
      File.directory?(dir) && !(dir.end_with?('/.') || dir.end_with?('/..'))
    end
  end

  def ruby_executable?(file)
    return false unless File.extname(file).empty?
    first_line = File.open(file, &:readline)
    first_line =~ /#!.*ruby/
  rescue EOFError, ArgumentError => e
    warn "Unprocessable file #{file}: #{e.class}, #{e.message}" if debug?
    false
  end

  def process_explicit_path(path)
    if path.include?('*')
      Dir[path]
    else
      [path]
    end
  end
end

TypedRb.options = OptionsParser.parse(ARGV)

time = Benchmark.realtime do
  files_to_check = TargetFinder.new.find(ARGV).reject { |f| f == File.expand_path(__FILE__) }
  TypedRb::Language.new.check_files(files_to_check)
end

puts "Finished in #{time} seconds"
