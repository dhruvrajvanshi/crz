module Functor(A)
  abstract def map(&block : A -> B) : Functor(B) forall B

end
module Applicative(A)
  extend Functor(A)
  def apply(other : Applicative(B), &block : ((A, B)-> C)) : Applicative(C) forall B, C
    bind {|a|
      other.bind { |b| 
        Some.new(block.call a, b)
      }
    }
  end

  def self.pure(value : A) : Applicative(A)
    raise "pure method unimplemented"
  end
end

module Monad(A)
  extend Applicative(A)
  abstract def bind(&block : A -> Monad(B)) : Monad(B) forall B 

  def map(&block : A -> B) : Monad(B) forall B
    bind {|x|
      typeof(self).pure(yield x)
    }
  end

  def >=(block : A -> Monad(B)) : Monad(B) forall B
    bind do |x|
      block.call(x)
    end
  end

  def >>(other : Monad(B)) : Monad(B) forall B
    bind {|_| other}
  end

  def <<(other : Monad(B)) : Monad(A) forall B
    bind {|_| self}
  end
end

abstract class Option(A)
  include Monad(A)
  abstract def to_s

  def self.pure(value : A) : Option(A)
    Some.new(value)
  end
end

class Some(A) < Option(A)
  def initialize(@value : A)
  end

  def bind(&block)
    yield @value
  end

  def to_s
    "Some(#{@value})"
  end
end

class None(A) < Option(A)
  def initialize
  end

  def bind(&block : A -> Option(B)) : Option(B) forall B
    None(B).new
  end

  def to_s
    "None"
  end
end

macro mdo(body)
  {% if ["Assign", "TypeNode", "Splat", "Union", "UninitializedVar", "TypeDeclaration", 
    "Generic", "ClassDef", "Def", "VisibilityModifier", "MultiAssign"].includes? body[body.size - 1].class_name %}
    {{body[0].raise "Last line of an mdo expression should be an expression."}}
  {% end %}

  {{body[0].args[0]}}.bind do |{{body[0].receiver}}|
  {% for i in 1...body.size - 1 %}
    {% if body[i].class_name == "Assign" %}
      {{body[0].args[0]}}.bind do |__mdo_generated_{{i}}|
        {{body[i].target}} = {{body[i].value}}
    {% else %}
      {% if body[i].class_name == "Call" && body[i].name == "=~" %}
          {{body[i].args[0]}}.bind do |{{body[i].receiver}}|
      {% else %}
        {{body[i].raise "Only =~ or = are allowed"}}
      {% end %}
    {% end %}
  {% end %}
      {{body[body.size - 1]}}
  {% for i in 0...body.size - 2 %}
    end
  {% end %}
  end
end

a = Some.new(1)

b = Some.new(23)


# pp (Some.new(345) << Some.new(34))
# puts mdo({
#   x =~ Some.new(32),
#   b = x <= 32,
#   p =~ Some.new(23),
#   z =~ None(Int32).new,
#   a =~ Some.new(23),
#   z = Some.new(a),
#   Some.new([x, a, z])
# }).to_s
def f(x, y, z, a) 
  x + y + z + a
end
macro ap(call)
  {% if call.class_name != "Call" %}
    {{call.raise "Second argument to ap must be a function call"}}
  {% end %}
  {% for i in 0..call.args.size - 1 %}
    {{call.args[i]}}.bind { |arg{{i}}|
  {% end %}

  typeof({{call.args[0]}}).pure(
    {{call.name}}(
      {% for i in 0..call.args.size - 2 %}
        arg{{i}},
      {% end %}
      arg{{call.args.size-1}}
    )
  )

  {% for i in 0...call.args.size %}
    }
  {% end %}
end

# macro curry(func_def)
#   {{func_def}}
# end

# curry(def add(x, y)
#   x + y
# end)

# Some.new(1).apply Some.new(2), f
asdf : Monad(Int32) = Some.new(1).map {|x| x+1}
puts asdf.to_s
puts ap(f Some.new(1), Some.new(2), Some.new(3), Some.new(4)).to_s

# print (a = 23)