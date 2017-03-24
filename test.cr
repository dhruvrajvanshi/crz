class None(A)
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

x = None(Int32).new.bind do |x|
  Some.new(x)
end

pp x
