require 'pry'
require './lib/init'
ENV['LOG_LEVEL'] = 'DEBUG'
TypedRb::Language.new.check_file('./lib/runtime.rb')
