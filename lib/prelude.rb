require 'continuation'

module Showable; end

class String
  include Showable
end

class Symbol
  include Showable
end

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
  ts '#!~ / Object -> Boolean'
  ts '#<=> / Object -> Integer'
  ts '#=== / Object -> Boolean'
  ts '#=~ / Object -> unit'
  ts '#class / -> Class'
  ts '#clone / -> Object'
  # ts '#define_singleton_method / '
  ts '#display / -> unit'
  ts '#display / IO -> unit'
  ts '#dup / -> Object'
  # diff no block vs block
  ts '#enum_for / -> Enumerator'
  ts '#enum_for / Symbol -> Enumerator'
  ts '#enum_for / Symbol -> Object... -> Enumerator'
  ts '#eql? / Object -> Boolean'
  ts '#extend / Module -> Object'
  ts '#freeze / -> Object'
  ts '#frozen? / -> Boolean'
  ts '#hash / -> Integer'
  ts '#inspect / -> String'
  ts '#instance_of? / Class -> Boolean'
  ts '#instance_variable_defined? / Showable -> Boolean'
  ts '#instance_variable_get / Showable -> Boolean'
  ts '#instance_variable_set / Showable -> Object -> Boolean'
  ts '#instance_variables / -> Array[Symbol]'
  ts '#is_a? / Class -> Boolean'
  ts '#itself / -> Object'
  ts '#kind_of? / Class -> Boolean'
  ts '#method / Symbol -> Method'
  ts '#methods / -> Array[Symbol]'
  ts '#methods / Boolean -> Array[Symbol]'
  ts '#nil? / -> Boolean'
  ts '#object_id / -> Integer'
  ts '#private_methods / -> Array[Symbol]'
  ts '#private_methods / Boolean -> Array[Symbol]'
  ts '#protected_methods / -> Array[Symbol]'
  ts '#protected_methods / Boolean -> Array[Symbol]'
  ts '#public_method / Symbol -> Method'
  ts '#public_methods / -> Array[Symbol]'
  ts '#public_methods / Boolean -> Array[Symbol]'
  ts '#public_send / Showable -> Object... -> Object'
  ts '#remove_instance_variable / Symbol -> Object'
  ts '#respond_to? / Showable -> Boolean'
  ts '#respond_to? / Showable -> Boolean -> Boolean'
  ts '#respond_to_missing? / Showable -> Boolean -> Boolean'
  ts '#send / Showable -> Object... -> Object'
  ts '#singleton_class / -> Class'
  ts '#singleton_method / Symbol -> Object'
  ts '#singleton_methods / Boolean -> Array[Method]'
  ts '#taint / -> Object'
  ts '#tainted? / -> Boolean'
  ts '#tap / &(Object -> unit) -> Object'
  # diff no block vs block
  ts '#to_enum / -> Enumerator'
  ts '#to_enum / Symbol -> Enumerator'
  ts '#to_enum / Symbol -> Object... -> Enumerator'
  ts '#to_s / -> String'
  ts '#trust / -> Object'
  ts '#untaint / -> Object'
  ts '#untrust / -> Object'
  ts '#untrusted? / -> Boolean'
end

module Kernel
  ts '#Array[E] / Range[E] -> Array[E]'
  ts '#Complex / BasicObject -> Complex'
  ts '#Complex / Integer -> Integer -> Complex'
  ts '#Float / BasicObject -> Float'
  ts '#Hash / BasicObject -> Float'
  ts '#Integer / BasicObject -> Integer'
  ts '#Integer / BasicObject -> Integer -> Integer'
  ts '#Rational / Numeric -> Rational'
  ts '#Rational / Numeric -> Numeric -> Rational'
  ts '#String / BasicObject -> String'
  ts '#__callee__ / -> Symbol'
  ts '#__dir__ / -> String'
  ts '#__method__ / -> Symbol'
  ts '#` / String -> BasicObject'
  ts '#abort / -> unit'
  ts '#abort / String -> unit'
  ts '.abort / -> unit'
  ts '.abort / String -> unit'
  ts '#at_exit / &(-> unit) -> Proc'
  ts '#autoload / Showable -> String -> unit'
  ts '#autoload? / Showable -> String'
  ts '#binding / -> Binding'
  ts '#block_given? / -> Boolean'
  ts '#callcc / &(Continuation -> BasicObject) -> BasicObject'
  ts '#caller / Range -> Array[String]'
  ts '#caller / Integer -> Integer -> Array[String]'
  ts '#caller_locations / Range[Integer] -> Array[String]'
  ts '#caller_locations / Integer -> Integer -> Array[String]'
  # ts '#catch / -> unit'
  # ts '#chomp / String -> String'
  # ts '#chop / String -> String'
  ts '#eval / String -> BasicObject'
  ts '#eval / String -> Binding -> BasicObject'
  ts '#eval / String -> Binding -> String -> BasicObject'
  ts '#eval / String -> Binding -> String -> Integer -> BasicObject'
  ts '#exec / BasicObject... -> String'
  ts '#exit / -> unit'
  ts '#exit / Boolean -> unit'
  ts '#exit! / -> unit'
  ts '#exit! / Boolean -> unit'
  ts '#fail / -> unit'
  ts '#fail / Exception -> unit'
  ts '#fail / Exception -> String -> unit'
  ts '#fail / Exception -> String -> Array[Object] -> unit'
  ts '#fork / &(-> unit)-> Integer'
  ts '#format / String -> Array[Object] -> String'
  ts '#gets / -> String'
  ts '#gets / Object -> String'
  ts '#gets / String -> Integer -> String'
  ts '#global_variables / -> Array[Symbol]'
  # ts '#gsub / Object -> String'
  ts '#iterator? / -> Boolean'
  # ts '#lambda / (BasicObject... -> unit) -> Proc'
  ts '#load / String -> Boolean'
  ts '#load / String -> Boolean -> Boolean'
  ts '#local_variables / -> Array[Symbol]'
  ts '#loop / -> Enumerator'
  ts '#loop / &( -> unit) -> unit'
  ts '#open / String -> IO'
  ts '#open / String -> &(IO -> unit) -> unit'
  ts '#open / String -> Object... -> IO'
  ts '#open / String -> Object... -> &(IO -> unit) -> unit'
  ts '#p / -> unit'
  ts '#p / BasicObject -> BasicObject'
  ts '#p / BasicObject... -> Array[BasicObject]'
  ts '#print / BasicObject... -> unit'
  ts '#printf / String -> BasicObject... -> unit'
  ts '#printf / IO -> String -> BasicObject... -> unit'
  # ts '#proc / '
  ts '#putc / Integer -> Integer'
  ts '#puts / BasicObject -> BasicObject... -> unit'
  ts '#raise / -> unit'
  ts '#raise / Exception -> unit'
  ts '#raise / Exception -> String -> unit'
  ts '#raise / Exception -> String -> Array[Object] -> unit'
  ts '#rand / -> Float'
  ts '#rand[E < Numeric] / [E] -> [E]'
  ts '#readline / Object -> String'
  ts '#readline / String -> Integer -> String'
  ts '#readlines / Object -> String'
  ts '#readlines / String -> Integer -> String'
  ts '#require / String -> Boolean'
  ts '#require_relative / String -> Boolean'
  ts '#select / Array[IO] -> Array[IO]'
  ts '#select / Array[IO] -> Array[IO] -> Array[IO]'
  ts '#select / Array[IO] -> Array[IO] -> Array[IO] -> Array[IO]'
  ts '#select / Array[IO] -> Array[IO] -> Array[IO] -> Integer -> Array[IO] '
  # set_trace_func
  ts '#sleep / -> Integer'
  ts '#sleep / Integer -> Integer'
  # spawn
  ts '#sprintf / String -> BasicObject... -> String'
  ts '#srand / -> Bignum'
  ts '#srand / -> Bignum -> Bignum'
  # sub
  ts '#syscall / Integer -> BasicObject... -> Integer'
  # system
  ts '#test / String -> BasicObject... -> BasicObject'
  # throw
  # trace_var
  # trap
  # untrace_var
  ts '#warn / String -> unit'
  ts '#warn / String -> String... -> unit'
end

class Class
  ts '#initialize / -> Class'
  ts '#initialize / Class -> Class'
  ts '#allocate / -> BasicObject'
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
  # Should we split this into #[] and #slice ?
  ts '#[] / Object -> Object'
  ts '#[] / Integer -> Integer -> Array[T]'
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
  ts '#delete / [T] -> &(-> [T]) -> [T]'
  ts '#delete_at / Integer -> [T]'
  ts '#delete_if / &([T] -> Boolean) -> Array[T]'
  ts '#drop / Integer -> Array[T]'
  ts '#drop_while / &([T] -> Boolean) -> Array[T]'
  ts '#each / &([T] -> unit) -> Array[T]'
  ts '#each_index / &([Integer] -> unit) -> Array[T]'
  ts '#empty? / -> Boolean'
  ts '#eql? / Array[?] -> Boolean'
  ts '#fetch / Integer -> &(Integer ->[T]) -> [T]'
  ts '#fetch / Integer -> [T] -> [T]'
  # diff no block vs block
  ts '#fill / [T] -> Array[T]'
  ts '#fill / [T] -> Integer -> Array[T]'
  ts '#fill / [T] -> Integer -> Integer -> Array[T]'
  ts '#find_index / &([T] -> Boolean) -> Integer'
  ts '#find_index / [T] -> Integer'
  ts '#first / -> Array[T]'
  ts '#first / Integer-> Array[T]'
  ts '#flatten / -> Array[Object]'
  ts '#flatten / Integer -> Array[Object]'
  ts '#flatten! / -> Array[Object]'
  ts '#flatten! / Integer -> Array[Object]'
  ts '#frozen? / -> Boolean'
  ts '#hash / -> Integer'
  ts '#include? / [T] -> Boolean'
  # diff no block vs block
  ts '#index / &([T] -> Boolean) -> Integer'
  ts '#index / [T] -> Integer'
  ts '#initialize_copy / Array[T] -> Array[T]'
  ts '#insert / Integer -> [T] -> [T]... -> Array[T]'
  ts '#inspect / -> String'
  ts '#join / -> String'
  ts '#join / String -> String'
  ts '#keep_if / &([T] -> Boolean) -> Array[T]'
  ts '#last / -> [T]'
  ts '#last / Integer -> Array[T]'
  ts '#length / -> Integer'
  ts '#map[E] / &([T] -> [E]) -> Array[E]'
  ts '#map![E] / &([T] -> [E]) -> Array[E]'
  ts '#pack / String -> String'
  # diff no block vs block
  ts '#permutation / -> Array[Array[T]]'
  ts '#permutation / Integer -> Array[Array[T]]'
  ts '#pop / -> [T]'
  ts '#pop / Integer -> Array[T]'
  ts '#product / Array[T]... -> Array[Array[T]]'
  ts '#push / [T]... -> Array[T]'
  # ts '#rassoc / '
  ts '#reject / &([T] -> Boolean) -> Array[T]'
  ts '#reject! / &([T] -> Boolean) -> Array[T]'
  ts '#repeated_combination / Integer -> Array[Array[T]]'
  ts '#repeated_permutation / Integer -> Array[Array[T]]'
  ts '#replace / Array[T] -> Array[T]'
  ts '#reverse / -> Array[T]'
  ts '#reverse! / -> Array[T]'
  ts '#reverse_each / &([T] -> unit) -> Array[T]'
  ts '#rindex / &([T] -> Boolean) -> Integer'
  ts '#rindex / [T] -> Integer'
  ts '#rotate / -> Array[T]'
  ts '#rotate / Integer -> Array[T]'
  ts '#rotate! / -> Array[T]'
  ts '#rotate! / Integer -> Array[T]'
  ts '#sample / -> Array[T]'
  ts '#sample / Integer -> Array[T]'
  ts '#select / &([T] -> Boolean) -> Array[T]'
  ts '#select! / &([T] -> Boolean) -> Array[T]'
  ts '#shift / -> [T]'
  ts '#shift / Integer -> Array[T]'
  ts '#shuffle / -> Array[T]'
  ts '#shuffle! / -> Array[T]'
  ts '#size / -> Integer'
  ts '#slice / Object -> Object'
  ts '#slice / Integer -> Integer -> Array[T]'
  ts '#slice! / Object -> Object'
  ts '#slice! / Integer -> Integer -> Array[T]'
  ts '#sort / &([T] -> [T] -> Integer) -> Array[T]'
  ts '#sort! / &([T] -> [T] -> Integer) -> Array[T]'
  ts '#sort_by! / &([T] -> Object) -> Array[T]'
  ts '#take / Integer -> Array[T]'
  ts '#take_while / &([T] -> Boolean) -> Array[T]'
  ts '#to_a / -> Array[T]'
  ts '#to_ary / -> Array[T]'
  ts '#to_h / -> Hash[T][T]'
  ts '#to_s / -> String'
  # ts '#transpose'
  ts '#uniq / &([T] -> Object) -> Array[T]'
  ts '#uniq! / &([T] -> Object) -> Array[T]'
  ts '#unshift / [T]... -> Array[T]'
  ts '#values_at / Integer... -> Array[T]'
  ts '#zip / Array[T]... -> Array[Array[T]]'
  ts '#| / Array[T] -> Array[T]'
end

class Module
  ts '#include / Module... -> Class'
end

ts 'type Hash[S][T]'
class Hash
  #  ts '#map[E] / &(Pair[S][T] -> [E]) -> Array[E]'

  ts '.[] / BasicObject... -> Hash[S][T]'
  ts '.try_convert / BasicObject -> Hash[S][T]'
  ts '#initialize / -> Hash[S][T]'
  ts '#initialize / &(Hash[S][T] -> [S] -> unit) -> Hash[S][T]'
  ts '#initialize / [T] -> Hash[S][T]'
  #==
  # []
  ts '#[]= / [S] -> [T] -> [T]'
  ts '#any? / &([S] -> [T] -> Boolean) -> Boolean'
  ts '#assoc / [S] -> Pair[S][T]'
  unless (instance_method(:untyped_assoc) rescue false)
    alias_method :untyped_assoc, :assoc
    def assoc(k)
      res = untyped_assoc(k)
      return res if res.nil?
      Pair.('[S][T]').new(res)
    end
  end
  ts '#clear / -> Hash[S][T]'
  ts '#compare_by_identity / -> Hash[S][T]'
  ts '#compare_by_identity? / -> Boolean'
  ts '#default / -> [T]'
  ts '#default / [S] -> [T]'
  ts '#default= / [T] -> [T]'
  # ts '#default_proc / -> (Hash[S][T] -> [S] -> [K])'
  # default_proc=
  ts '#delete / [S] -> &([S] -> [T]) -> [T]'
  ts '#delete_if / &([S] -> [T] -> Boolean) -> Hash[S][T]'
  ts '#each / &([S] -> [T] -> unit) -> Hash[S][T]'
  ts '#each_key / -> Enumerator' # TODO: make this generic, do for other functions as well
  ts '#each_key / &([S] -> unit) -> Hash[S][T]'
  ts '#each_pair / &([S] -> [T] -> unit) -> Hash[S][T]'
  ts '#each_value / &([T] -> unit) -> Hash[S][T]'
  ts '#empty? / -> Boolean'
  #ts '#eql? / Hash[?][?] -> Boolean' -> from Object
  ts '#fetch / [S] -> &([S] -> [T]) -> [T]'
  ts '#fetch / [S] -> [T] -> [T]'
  ts '#flatten / -> Array[Object]'
  ts '#flatten / Integer -> Array[Object]'
  ts '#has_key? / [S] -> Boolean'
  ts '#has_value? / [T] -> Boolean'
  ts '#hash / -> Fixnum'
  ts '#include? / [S] -> Boolean'
  ts '#invert / -> Hash[T][S]'
  ts '#keep_if / &([S] -> [T] -> Boolean) -> Hash[S][T]'
  ts '#key / [T] -> [S]'
  ts '#key? / [S] -> Boolean'
  ts '#keys / -> Array[S]'
  ts '#length / -> Fixnum'
  ts '#member? / [S] -> Boolean'
  ts '#merge / Hash[S][T] -> Hash[S][T]'
  ts '#merge / Hash[S][T] -> &([S] -> [T] -> [T] -> [T]) -> Hash[S][T]'
  ts '#merge! / Hash[S][T] -> Hash[S][T]'
  ts '#merge! / Hash[S][T] -> &([S] -> [T] -> [T] -> [T]) -> Hash[S][T]'
  ts '#rassoc / [T] -> Pair[S][T]'
  unless (instance_method(:untyped_rassoc) rescue false)
    alias_method :untyped_rassoc, :rassoc
    def rassoc(k)
      res = untyped_rassoc(k)
      return res if res.nil?
      Pair.('[S][T]').new(res)
    end
  end
  ts '#rehash / -> Hash[S][T]'
  ts '#reject / &([S] -> [T] -> Boolean) -> Hash[S][T]'
  ts '#reject! / &([S] -> [T] -> Boolean) -> Hash[S][T]'
  ts '#replace / Hash[S][T] -> Hash[S][T]'
  ts '#select / &([S] -> [T] -> Boolean) -> Hash[S][T]'
  ts '#select! / &([S] -> [T] -> Boolean) -> Hash[S][T]'
  ts  '#shift / -> Pair[S][T]'
  unless (instance_method(:untyped_shift) rescue false)
    alias_method :untyped_shift, :shift
    def shift
      res = untyped_shift
      return res if res.nil?
      Pair.('[S][T]').new(res)
    end
  end
  ts '#size / -> Fixnum'
  ts '#store / [S] -> [T] -> [T]'
  ts '#to_a / -> Array[Pair[S][T]]'
  ts '#to_h / -> Hash[S][T]'
  ts '#to_hash / -> Hash[S][T]'
  ts '#update / Hash[S][T] -> Hash[S][T]'
  ts '#update / Hash[S][T] -> &([S] -> [T] -> [T] -> [T]) -> Hash[S][T]'
  ts '#value? / [T] -> Boolean'
  ts '#values / -> Array[T]'
  ts '#values_at / [S]... -> Array[T]'
end

ts 'type Range[T]'
class Range
  ts '#initialize / [T] -> [T] -> Range[T]'
  ts '#initialize / [T] -> [T] -> Boolean -> Range[T]'
end

class Integer
  ts '#+ / Integer -> Integer'
  def +(_other)
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
