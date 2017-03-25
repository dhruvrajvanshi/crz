module CRZ
  module Functor(A)
    abstract def map(&block : A -> B) : Functor(B) forall B

  end
  module Applicative(A)
    include Functor(A)
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
    include Applicative(A)
    abstract def bind(&block : A -> Monad(B)) : Monad(B) forall B 

    def map(&block : A -> B) : Monad(B) forall B
      bind {|x|
        typeof(self).pure(block.call x)
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
end