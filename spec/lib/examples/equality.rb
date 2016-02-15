module Categories
  ts 'type Categories::Equal[T]'
  module Equal

    ts '#eq? / [T] -> Boolean'
    def eq?(o); self.eql?(o); end

    ts '#not_eq? / [T] -> Boolean'
    def not_eq?(o); ! self.eq?(o); end

  end
end

ts 'type Integer super Categories::Equal[Integer]'
class Integer
  include Categories::Equal
end
