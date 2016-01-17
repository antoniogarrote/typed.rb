class BasicObject
  def ts(signature)
    # TODO: Add information about the script and line for the invocation here
    # caller_infos = caller.first.split(":")
    # puts "#{caller_infos[0]} : #{caller_infos[1]} : #{str}"
    ::TypedRb.log(binding, :debug, "Parsing signature: #{signature}")
    if $TYPECHECK
      if ::TypedRb::Runtime::TypeSignatureProcessor.type_signature?(signature)
        ::TypedRb::Runtime::TypeSignatureProcessor.process(signature)
      else
        ::TypedRb::Runtime::MethodSignatureProcessor.process(signature, self)
      end
    end
    # rescue ::StandardError => ex
    #  puts ex.message
    #  puts ex.backtrace.join("\n")
    #  raise ::StandardError, "Error parsing type signature '#{signature}': #{ex.message}"
  end

  def ts_ignore; end

  def cast(from, _to)
    # noop
    from
  end
end

class Class
  ts '.call / Class... -> unit'
  def call(*_types)
    self
  end
end
