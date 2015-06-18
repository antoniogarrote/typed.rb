class Integer
  ts '#+ / Integer -> Integer'
end

class Counter
  ts '#initialize / Integer -> unit'
  def initialize(start_value)
    @counter = start_value
  end

  ts '#inc / Integer -> Integer'
  def inc(num=1)
    @counter = @counter + num
  end

  ts '#counter / -> Integer'
  def counter
    @counter
  end
end
