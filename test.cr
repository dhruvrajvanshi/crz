
abstract class ADTOptional(A)
  def to_s
    match_optional(self, {[Some, x] => "Some(#{x})", [None] => "None"})
  end

  def self.pure(value : T) : Optional(T) forall T
    Optional::Some.new(value)
  end

  def bind(&block : (A -> Optional(B))) : Optional(B) forall B
    match_optional(self, {[Some, x] => block.call(x), [None] => Optional::None(B).new})
  end
end

abstract class Optional(A) < ADTOptional(A)
  # generic base
  # intersection type
  class Some(A) < Optional(A)
    property value0

    def initialize(
                   @value0 : A)
    end
  end

  # constructor with no value types
  class None(A) < Optional(A)
    def initialize
    end
  end
end
