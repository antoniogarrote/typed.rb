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

class Object
  ts '#to_s / -> String'
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
  ts '#callcc / &(Continuation -> BasicObject) -> BasicObject'
  ts '#caller / Integer -> Integer -> Array[String]'
  ts '#caller / Range -> Array[String]'
end

ts 'type Array[T]'
class Array
  ts '.[] / [T]... -> Array[T]'
  ts '#initialize / Integer -> Array[T]'
  ts '#initialize / Integer -> [T] -> Array[T]'
  ts '#& / Array[T] -> Array[T]'
  ts '#* / Integer -> Array[T]'
  ts '#+ / Array[T] -> Array[T]'
  ts '#- / Array[T] -> Array[T]'
  ts '#<< / [T] -> Array[T]'
  ts '#<=> / Array[T] -> Integer'
  ts '#== / Array[T] -> Array[T]'
  ts '#at / Integer -> [T]'
  ts '#[] / Object -> Object'
  ts '#[] / Integer -> Integer -> Array[T]'
  ts '#slice / Object -> Object'
  ts '#slice / Integer -> Integer -> Array[T]'
  ts '#push / [T]... -> Array[T]'
  ts '#any? / &([T] -> Boolean) -> Boolean'
  ts '#assoc / Object -> Array[T]'
  ts '#bsearch / &([T] -> Boolean) -> [T]'
  ts '#clear / -> Array[T]'
  ts '#collect[E] / &([T] -> [E]) -> Array[E]'
  ts '#collect![E] / &([T] -> [E]) -> Array[E]'
  ts '#combination / Integer -> Array[Array[T]]'
  ts '#compact / -> Array[T]'
  ts '#compact! / -> Array[T]'
  ts '#concat / Array[T] -> Array[T]'
  ts '#count / &([T] -> Boolean) -> Integer'
  ts '#count / [T] -> Integer'
  ts '#cycle / &([T] -> unit) -> unit'
  ts '#cycle / Integer -> &([T] -> unit) -> unit'
  # diff no block vs block
  ts '#delete / [T] -> &(-> [T]) -> [T]'
  ts '#delete_at / Integer -> [T]'
  ts '#delete_if / &([T] -> Boolean) -> Array[T]'
  ts '#drop / Integer -> Array[T]'
  ts '#drop_while / &([T] -> Boolean) -> Array[T]'
  ts '#each / &([T] -> unit) -> Array[T]'
  ts '#each_index / &([Integer] -> unit) -> Array[T]'
  ts '#empty? / -> Boolean'
  ts '#eql? / Array[?] -> Boolean'
  # ts '#fetch
  # ts '#fill
  # ts '#find_index
  # ts '#first
  # ts '#flatten
  # ts '#flatten!
  # ts '#frozen?
  # ts '#hash
  # ts '#include?
  # ts '#index
  # ts '#initialize_copy
  # ts '#insert
  # ts '#inspect
  # ts '#join
  # ts '#keep_if
  # ts '#last
  # ts '#length
  # ts '#map
  # ts '#map!
  # ts '#pack
  # ts '#permutation
  # ts '#pop
  # ts '#product
  # ts '#push
  # ts '#rassoc
  # ts '#reject
  # ts '#reject!
  # ts '#repeated_combination
  # ts '#repeated_permutation
  # ts '#replace
  # ts '#reverse
  # ts '#reverse!
  # ts '#reverse_each
  # ts '#rindex
  # ts '#rotate
  # ts '#rotate!
  # ts '#sample
  # ts '#select
  # ts '#select!
  # ts '#shift
  # ts '#shuffle
  # ts '#shuffle!
  # ts '#size
  # ts '#slice
  # ts '#slice!
  # ts '#sort
  # ts '#sort!
  # ts '#sort_by!
  # ts '#take
  # ts '#take_while
  # ts '#to_a
  # ts '#to_ary
  # ts '#to_h
  # ts '#to_s
  # ts '#transpose
  # ts '#uniq
  # ts '#uniq!
  # ts '#unshift
  # ts '#values_at
  # ts '#zip
  # ts '#|
#  ts '#map[E] / &([T] -> [E]) -> Array[E]'
end

class Module
  ts '#include / Module... -> Class'
end

ts 'type Hash[S][T]'
class Hash
  ts '#initialize / [S]... -> Hash[S][T]'
#  ts '#map[E] / &(Pair[S][T] -> [E]) -> Array[E]'
end

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

ts 'type Pair[S][T] super Array[Object]'
class Pair < Array
  ts '#first / -> [S]'

  ts '#second / -> [T]'
  def second
    cast(at(1), '[T]')
  end
end
