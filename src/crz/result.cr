module CRZ::Containers
  alias Ok = Result::Ok
  alias Err = Result::Err
  adt_class Result(T, E),
    Ok(T),
    Err(E),
    abstract class ADTResult(T, E)
      include Monad(T)
      
      def self.of(value : T) : Result(T, E)
        Result::Ok(T, E).new value
      end

      def bind(&block : T -> Result(U, E)) : Result(U, E) forall U
        Result.match self, {
          [Ok, x]  => (block.call x),
          [Err, e] => Result::Err(U, E).new e,
        }
      end

      def map(&block : T -> U) : Result(U, E) forall U
        Result.match self, {
          [Ok, x] => (Result::Ok(U, E).new (block.call x)),
          [Err, e] => Result::Err(U, E).new e
        }
      end

      def unwrap() : T
        Result.match self, {
          [Ok, x] => x,
          [Err, e] => raise Exception.new("Tried to unwrap Result::Err value")
        }
      end

      def has_value() : Bool 
        Result.match self, {
          [Ok, x] => true,
          [_] => false
        }
      end
    end
end