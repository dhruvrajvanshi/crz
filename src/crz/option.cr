include CRZ

module CRZ::Containers
  alias Some = Option::Some
  alias None = Option::None
  adt Option(A),
    Some(A),
    None do
      include Monad(A)

      def to_s
        Option.match self, Option(A), {
          [Some, x] => "Some(#{x})",
          [None]    => "None",
        }
      end

      def self.of(value : T) : Option(T) forall T
        Option::Some.new(value)
      end

      def unwrap : A
        Option.match self, Option(A), {
          [Some, x] => x,
          [None]    => raise Exception.new("Tried to unwrap Option::None value"),
        }
      end

      def get : A
        unwrap
      end

      def unwrap_or_else(default : A) : A
        Option.match self, Option(A), {
            [Some, x] => x,
            [None]    => default
        }
      end

      def get_or_else(default : A) : A
        unwrap_or_else(default)
      end

      def has_value : Bool
        Option.match self, Option(A), {
          [Some, _] => true,
          [_]       => false,
        }
      end

      def flat_map(&block : A -> Option(B)) : Option(B) forall B
        bind(block)
      end

      def bind(&block : A -> Option(B)) : Option(B) forall B
        Option.match self, Option(A), {
          [Some, x] => (block.call x),
          [None]    => Option::None(B).new,
        }
      end
    end
end
