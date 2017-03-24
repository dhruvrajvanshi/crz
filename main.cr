abstract class Option(A)
  abstract def to_s
  abstract def map(&block : A -> B) : Option(B) forall B
  abstract def bind(&block : A -> Option(B)) forall B 

  def self.pure(value : A)
    Some.new(value)
  end

  def >=(&block)
    bind(block)
  end

  def >>(other : Option(B)) : Option(B) forall B
    bind {|_| other}
  end

  def <<(other : Option(B)) : Option(A) forall B
    bind {|_| self}
  end
end

class Some(A) < Option(A)
  def initialize(@value : A)
  end

  def map(&block : A -> B) : Option(B) forall B
    Some.new(yield @value)
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

  def map(&block : A -> B) : Option(B) forall B
    return None(T).new
    yield
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

x = None(Int32).new().bind do |x|
  Some.new(x && false)
end

# pp (Some.new(345) << Some.new(34))
print mdo({
  x =~ Some.new(32),
  b = x <= 32,
  p =~ Some.new(23),
  z =~ None(Int32).new,
  a =~ Some.new(23),
  z = Some.new(a),
  Some.new([x, a, z])
}).to_s

# print (a = 23)