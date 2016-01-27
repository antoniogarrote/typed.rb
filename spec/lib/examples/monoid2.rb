require 'typed/runtime'

module Monoid

  ts 'type Monoid::Instance[T]'
  module Instance
    ts '#mappend / [T] -> [T]'
    abstract(:mappend)
  end

  ts 'type Monoid::Class[T]'
  module Class
    ts '#mempty / -> [T]'
    abstract(:mempty)
  end
end

ts 'type Array[T] super Monoid::Instance[Array[T]]'
class Array

  extend Monoid::Class
  include Monoid::Instance

  def mappend(b)
    concat(b)
  end

  def self.mempty
    []
  end

end

Array.(Integer).new.mappend([3])