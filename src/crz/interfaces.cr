module CRZ
  module Functor(A)

    def replace(other : Functor(B), v : A) : Functor(A)
      map { |_| v }
    end
  end

  module Applicative(A)
    include Functor(A)

    def *(func : Applicative(A -> B)) : Applicative(B) forall B
      ap(func)
    end

    def self.of(value : A) : Applicative(A) forall A
      raise "of method unimplemented"
    end
  end

  module Monad(A)
    include Applicative(A)


    def ap(func : Applicative(A -> B)) : Applicative(B) forall B
      func.bind do |f|
        self.map &f
      end
    end

    def map(&block : A -> B) : Monad(B) forall B
      bind do |x|
        typeof(self).of(block.call x)
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
      bind { |v|
        other.map {|_|
          v
        }
      }
    end
  end
end
