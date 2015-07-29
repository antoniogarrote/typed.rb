require 'continuation'

class BasicObject
  ts '#initialize / -> unit'
  ts '#! / -> Boolean'
  ts '#!= / BasicObject -> Boolean'
  ts '#== / BasicObject -> Boolean'
  ts '#__id__ / -> Integer'
  ts '#__send__ / BasicObject -> BasicObject... -> BasicObject'
  ts '#equal? / BasicObject -> Boolean'
  ts '#instance_eval / String -> String -> Integer -> &(BasicObject -> unit) -> BasicObject'
  ts '#method_missing / Symbol -> BasicObject... -> BasicObject'
  ts '#singleton_method_added / Symbol -> unit'
  ts '#singleton_method_removed / Symbol -> unit'
  ts '#singleton_method_undefined / Symbol -> unit'
  ts '#ts / String -> unit'
  ts '#cast / BasicObject -> BasicObject -> BasicObject'
end


module Kernel
  ts '#send / BasicObject -> BasicObject... -> BasicObject'
  ts '#object_id / -> Integer'
  ts '#Array / Range -> Array[Integer]'
  ts '#Complex / BasicObject -> Integer -> Complex'
  ts '#Float / BasicObject -> Float'
  ts '#Hash / BasicObject -> Hash[BasicObject][BasicObject]'
  ts '#Integer / BasicObject -> Integer -> Integer'
  ts '#Rational / BasicObject -> Rational'
  ts '#String / BasicObject -> String'
  ts '#__callee__ / -> Symbol'
  ts '#__dir__ / -> String'
  ts '#__method__ / -> Symbol'
  ts '#` / String -> BasicObject'
  ts '#abort / String -> unit'
  ts '.abort / String -> unit'
  ts '#at_exit / &(-> unit) -> Proc'
  ts '#autoload / BasicObject -> String -> unit'
  ts '#autoload? / Symbol -> String'
  ts '#binding / -> Binding'
  ts '#block_given? / -> Boolean'
  ts '#callcc / (Continuation -> BasicObject) -> BasicObject'
  ts '#caller / Integer -> Integer -> Array[String]'
  ts '#caller / Range -> Array[String]'
end

ts 'type Array[T]'
class Array

  ts '.[] / [T]... -> Array[T]'
  ts '#initialize / BasicObject... -> Array[T]'
  ts '#& / Array[T] -> Array[T]'
  ts '#* / Integer -> Array[T]'
  ts '#+ / Array[T] -> Array[T]'
  ts '#- / Array[T] -> Array[T]'
  ts '#<< / [T] -> Array[T]'
  ts '#<=> / Array[T] -> Integer'
  ts '#== / Array[T] -> Array[T]'
  ts '#at / Integer -> [T]'
  ts '#[] / Integer... -> Object'
end


ts 'type Hash[T][U]'
class Hash; end

ts 'type Range[T]'
class Range; end

class Integer
  ts '#+ / Integer -> Integer'
  def +(other)
    fail StandardError.new('Error invoking abstract method Integer#+')
  end

  # TODO
  # [:+, :-, :*, :/, :**, :~, :&, :|, :^, :[], :<<, :>>, :to_f, :size, :bit_length]
end
