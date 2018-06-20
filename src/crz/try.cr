
module CRZ::Containers
  adt_class Try(A), Success(A), Failure,

    abstract class ADTTry(A)
      include Monad(A)

      @error : Exception = Exception.new
      property :error

      def self.try(&block : -> A) : Try(A) forall A
        begin
          Try::Success(A).new(block.call)
        rescue err
          e = Try::Failure(A).new
          e.error = err
          e
        end
      end

      def self.of(value : A) : Try(A) forall A
        Try::Success(A).new(value)
      end

      def flat_map(&block : A -> Try(B)) : Try(B) forall B
        bind(block)
      end

      def bind(&block : A -> Try(B)) : Try(B) forall B
        self.is_a?(Try::Success) ? block.call(self.value0) : self
      end

      def unwrap : A
        self.is_a?(Try::Success) ? self.value0 : raise self.error
      end

      def flatten : A
        unwrap
      end

      def get : A
        unwrap
      end

        def has_value : Bool
          self.is_a?(Try::Success) ? true : false
        end


        def to_s
          self.is_a?(Try::Success) ? "Try::Success(#{value0})" : "Try::Failure"
        end


      def unwrap_or(default : A) : A
        self.is_a?(Try::Success) ? self.value0 : default
      end

      def unwrap_or_else(default : A) : A
        unwrap_or(default)
      end

      def get_or_else(default : A) : A
        unwrap_or(default)
      end

      def get_option : Option(A)
        self.is_a?(Try::Success) ? Option::Some(A).new(self.value0) : Option::None(A).new
      end

      def get_result
        self.is_a?(Try::Success) ? Result::Ok(A, Excception).new(self.value0) : Result::Err(A, Exception).new(self.error)
      end
    end
end
