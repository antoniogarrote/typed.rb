ts 'type Monoid[T]'
module Monoid
  ts '#mappend / [T] -> [T] -> [T]'
  abstract(:mappend)

  ts '#mempty / -> [T]'
  abstract(:mempty)
end


ts 'type Sum[Integer] super Monoid[T]'
class Sum

  include Monoid

  def mappend(a,b)
    a + b
  end

  def mempty
    0
  end

end


ts '#sum / Array[Integer] -> Integer'
def sum(xs)
  monoid = Sum.new
  zero = monoid.mempty
  xs.reduce(zero) { |a,b| monoid.mappend(a,b) }
end


ts '#moncat[T] / Array[T] -> Monoid[T] -> [T]'
def moncat(xs, m)
  zero = m.mempty
  xs.reduce(zero) { |a,b| m.mappend(a,b) }
end

->() {
  moncat([1,2,3], Sum.new)
}

