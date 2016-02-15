module Categories
  ts 'type Categories::Enum[T]'
  module Enum
    ts '#succ / -> [T]'
    abstract(:succ)

    ts '#pred / -> [T]'
    abstract(:pred)

    ts '#to / [T] -> Array[T]'
    def to(x)
      xs = Array.('[T]').new
      next_val = self
      while(next_val != x)
        xs.push(next_val)
        next_val = next_val.succ
      end
      xs.push(next_val)
      xs
    end
  end
end


ts 'type Integer super Categories::Enum[Integer]'
class Integer
  include Categories::Enum

  def succ
    self + 1
  end

  def pred
    self - 1
  end
end

3.to(10)


