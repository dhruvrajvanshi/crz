module CRZ
  module Functor(A)
    abstract def map(&block : A -> B) : Functor(B) forall B

    def replace(other : Functor(B), v : A) : Functor(A)
      map { |_| v }
    end
  end

  module Applicative(A)
    include Functor(A)

    abstract def ap(func : Applicative(A -> B)) : Applicative(B) forall B

    def *(func : Applicative(A -> B)) : Applicative(B) forall B
      ap(func)
    end

    def self.pure(value : A) : Applicative(A)
      raise "pure method unimplemented"
    end
  end

  module Monad(A)
    include Applicative(A)

    abstract def bind(&block : A -> Monad(B)) : Monad(B) forall B

    def ap(func : Applicative(A -> B)) : Applicative(B) forall B
      func.bind do |f|
        self.map &f
      end
    end

    def map(&block : A -> B) : Monad(B) forall B
      bind do |x|
        typeof(self).pure(block.call x)
      end
    end

    def >=(block : A -> Monad(B)) : Monad(B) forall B
      bind do |x|
        block.call(x)
      end
    end

    def >>(other : Monad(B)) : Monad(B) forall B
      bind { |_| other }
    end

    def <<(other : Monad(B)) : Monad(A) forall B
      bind { |_| self }
    end
  end
end
