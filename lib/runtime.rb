class BasicObject
  def ts(signature)
    ::TypedRb.log(binding, :debug, "Parsing signature: #{signature}")
    if $TYPECHECK
      if ::TypedRb::Runtime::TypeSignatureProcessor.type_signature?(signature)
        ::TypedRb::Runtime::TypeSignatureProcessor.process(signature)
      else
        ::TypedRb::Runtime::MethodSignatureProcessor.process(signature, self)
      end
    end
  rescue ::StandardError => ex
    raise ::StandardError, "Error parsing type signature '#{type_signature}': #{ex.message}"
  end

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
