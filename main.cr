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

b = Some.new(23).map {|x| x + 1}


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

macro variant(base, args)
  {% if base[0].class_name == "Path" %}
    {% base_class = base[0].names[0] %}
  {% else %}
    {% base_class = base[0].name.names[0] %}
  {% end %}
  # base class {{args[0]}}
  macro match_{{base_class.underscore}}(val, cases)
    %value = \{{val}}  
    -> {
      %matcher_func = -> {
        \{% for lhs in cases.keys %}
          \{% if lhs.class_name == "Underscore" %}
              return \{{cases[lhs]}}
          \{% else %}
            \{% if lhs.class_name == "Path" %}
              \{% 
                lhs_class = lhs.names[0]
               %}
            \{% else %}
              \{%
                 lhs_class = lhs[0].names[0]
               %}
            \{% end %}

            if \{{val}}.is_a? {{base_class}}::\{{lhs_class}}
              ## bind values
              \{% if lhs.class_name != "Path" %}
                \{% for i in 1...lhs.size %}
                  \{{lhs[i]}} = %value.as({{base_class}}::\{{lhs_class}}).value\{{i-1}}
                \{% end %}
              \{% end %}
              return \{{cases[lhs]}}
            end
          \{% end %}
        \{% end %}
        raise ArgumentError.new("Non exhaustive patterns passed to match_" + {{base_class.underscore.stringify}})
      }
      %matcher_func.call()
    }.call
  end
  abstract class {{base[0]}}
    {% if base[0].class_name == "Path" %}
      # non generic base
      {% for i in 0...args.size %}
        {% if args[i].class_name == "Path" %}
          class {{args[i].names[0]}} < {{base[0]}}
            def initialize
            end
          end
        {% else %}
          class {{args[i].name}} < {{base[0]}}
            {% for j in 0...args[i].type_vars.size %}
              property value{{j}}
            {% end %}
            def initialize(
              {% for j in 0...args[i].type_vars.size-1 %}
                @value{{j}} : {{args[i].type_vars[j]}},
              {% end %}
              @value{{args[i].type_vars.size - 1}} : {{args[i].type_vars[args[i].type_vars.size - 1]}}
            )
            end
          end
        {% end %}
      {% end %}
    {% else %}
      # generic base
      {% for i in 0...args.size %}
        {% if args[i].class_name == "Path" %} # constructor with no value types
          class {{args[i].names[0]}}(
              {{base[0].type_vars[0]}}
              {% for j in 1...base[0].type_vars.size %}
                , {{base[0].type_vars[j]}}
              {% end %}
            ) < {{base[0]}}
            def initialize
            end
          end
        {% else %} # intersection type
          class {{args[i].name}}(
              {{base[0].type_vars[0]}}
              {% for j in 1...base[0].type_vars.size %}
                , {{base[0].type_vars[j]}}
              {% end %}
            ) < {{base[0]}}
            {% for j in 0...args[i].type_vars.size %}
              property value{{j}}
            {% end %}
            def initialize(
              {% for j in 0...args[i].type_vars.size-1 %}
                @value{{j}} : {{args[i].type_vars[j]}},
              {% end %}
              @value{{args[i].type_vars.size - 1}} : {{args[i].type_vars[args[i].type_vars.size - 1]}}
            )
            end
          end
        {% end %}
      {% end %}
    {% end %}
  end
end


# macro matcher_body(args)
#   {% if matcher %}
# end

variant [IntList], {
  Empty,
  Cons(Int32, IntList)
}

variant [List(A)], {
  Empty,
  Cons(A, List(A))
}


# puts match_list(List::Empty(Int32).new, {
#   Empty => 1,
#   Cons {x, xs} => 3
# })

# puts match_int_list((IntList::Cons.new 2, IntList::Empty.new), {
#   [Empty] => 1,
#   [Cons, x, xs] => xs
# })

puts match_list (List::Cons.new(true, List::Empty(Bool).new)), {
  [Cons, x, xs] => "Empty"
}

# puts match((List::Cons.new 1, List::Empty(Int32).new), {
#     Empty =~ 1,
#     Cons [x, xs] =~ x
#   })

# matcher({List(A),
#   Empty,
#   Cons(A, List(A))
# })

# base class List(A)
# class List(A)
#   macro def match()
#     if(self.is_a? Empty)
#       expr
#     elsif self.is_a? Cons
#       a = self.value0
#       b = self.value1
#       expr
#     end
#   end
# end

# # variants (subclasses)
# class Empty(A) < List(A)
#   def initialize
#   end
# end

# class Cons(A) < List(A)
#   def initialize(
#                  @value0 : A,
#                  @value1 : List(A))
#   end
# end


# macro curry(func_def)
#   {{func_def}}
# end

# curry(def add(x, y)
#   x + y
# end)

# Some.new(1).apply Some.new(2), f
# asdf : Monad(Int32) = Some.new(1).map {|x| x+1}
# puts asdf.to_s
# puts ap(f Some.new(1), Some.new(2), Some.new(3), Some.new(4)).to_s

# print (a = 23)


macro variant_module(base, args, cls_dec)
  {% if base[0].class_name == "Path" %}
    {% base_class = base[0].names[0] %}
  {% else %}
    {% base_class = base[0].name.names[0] %}
  {% end %}
  macro match_{{base_class.underscore}}(val, cases)
    %value = \{{val}}  
    -> {
      %matcher_func = -> {
        \{% for lhs in cases.keys %}
          \{% if lhs.class_name == "Underscore" %}
              return \{{cases[lhs]}}
          \{% else %}
            \{% if lhs.class_name == "Path" %}
              \{% 
                lhs_class = lhs.names[0]
               %}
            \{% else %}
              \{%
                 lhs_class = lhs[0].names[0]
               %}
            \{% end %}

            if \{{val}}.is_a? {{base_class}}::\{{lhs_class}}
              ## bind values
              \{% if lhs.class_name != "Path" %}
                \{% for i in 1...lhs.size %}
                  \{{lhs[i]}} = %value.as({{base_class}}::\{{lhs_class}}).value\{{i-1}}
                \{% end %}
              \{% end %}
              return \{{cases[lhs]}}
            end
          \{% end %}
        \{% end %}
        raise ArgumentError.new("Non exhaustive patterns passed to match_" + {{base_class.underscore.stringify}})
      }
      %matcher_func.call()
    }.call
    \{{debug()}}
  end

  {{cls_dec.id}}

  module {{base[0]}}
    {% if base[0].class_name == "Path" %}
      # non generic base
      {% for i in 0...args.size %}
        {% if args[i].class_name == "Path" %}
          class {{args[i].names[0]}}
              include {{base[0]}}
            def initialize
            end
          end
        {% else %}
          class {{args[i].name}}
              include {{base[0]}}
            {% for j in 0...args[i].type_vars.size %}
              property value{{j}}
            {% end %}
            def initialize(
              {% for j in 0...args[i].type_vars.size-1 %}
                @value{{j}} : {{args[i].type_vars[j]}},
              {% end %}
              @value{{args[i].type_vars.size - 1}} : {{args[i].type_vars[args[i].type_vars.size - 1]}}
            )
            end
          end
        {% end %}
      {% end %}
    {% else %}
      # generic base
      {% for i in 0...args.size %}
        {% if args[i].class_name == "Path" %} # constructor with no value types
          class {{args[i].names[0]}}(
              {{base[0].type_vars[0]}}
              {% for j in 1...base[0].type_vars.size %}
                , {{base[0].type_vars[j]}}
              {% end %}
            )
            include {{base[0]}}
            def initialize
            end
          end
        {% else %} # intersection type
          class {{args[i].name}}(
              {{base[0].type_vars[0]}}
              {% for j in 1...base[0].type_vars.size %}
                , {{base[0].type_vars[j]}}
              {% end %}
            )
            include {{base[0]}}
            {% for j in 0...args[i].type_vars.size %}
              property value{{j}}
            {% end %}
            def initialize(
              {% for j in 0...args[i].type_vars.size-1 %}
                @value{{j}} : {{args[i].type_vars[j]}},
              {% end %}
              @value{{args[i].type_vars.size - 1}} : {{args[i].type_vars[args[i].type_vars.size - 1]}}
            )
            end
          end
        {% end %}
      {% end %}
    {% end %}
  end
end

variant_module [Optional(A)], {
  Some(A), None
},
module Optional(A)
  def to_s
    match_optional(self, {
      [Some, x] => "Some(#{x})",
      [None] => "None"
    })
  end
end

puts Optional::Some.new(2).to_s

# puts variantA::Some.new(2).to_s
# puts variantOptional::Some(1)