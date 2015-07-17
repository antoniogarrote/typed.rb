class Array
  ts '#push / [T]... -> Array[T]'
  ts '#last / Integer... -> [T]'
end

class Animal1

  ts '#make_sound / -> String'
  def make_sound
    'animal sound'
  end

end

class Cat1 < Animal1

  ts '#make_sound / -> String'
  def make_sound
    "meow"
  end

  ts '#jump / -> unit'
  def jump; end
end


class Dog1 < Animal1

  ts '#make_sound / -> String'
  def make_sound
    "bark"
  end

end

ts '#mindless_func / Array[Animal1] -> Array[Animal1]'
def mindless_func(xs)
  xs.push(Dog1.new)
end

cats = Array.(Cat1).new
cats.push(Cat1.new)

horror = mindless_func(cats)

lambda {
  horror.last.jump
}
