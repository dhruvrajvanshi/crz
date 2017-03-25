module CRZ::Containers
  property value

  class Nilable(A)
    include Monad(A)

    property value

    def initialize(@value : A? = nil)
    end

    def self.pure(value : A) forall A
      Nilable.new value
    end

    def bind(&block : A -> Nilable(B)) : Nilable(B) forall B
      if @value.nil?
        Nilable(B).new
      else
        yield @value.as(A)
      end
    end
  end
end
