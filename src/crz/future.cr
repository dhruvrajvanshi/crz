require "./*"
include CRZ

module CRZ::Containers
  adt_class Future(A), Success(A), Processing(A), Failure,
    abstract class ADTFuture(A)
      include Monad(A)

      @error : Exception = Exception.new
      @channel = Channel(Int32 | Exception).new
      @is_completed = false
      @is_error = false

      property :channel, :is_completed
      property :error, :is_error

      # Set dummy to an instance of type A.
      # The value can be anything. It needs to be set in order to pass through the compiler.
      # If anyone has a good idea please let me know.
      def self.spawn(dummy : A, &block : -> A) : Future(A) forall A
        c = Channel(Int32 | Exception).new
        f = Future::Processing(A).new(dummy)
        f.channel = c
        s = spawn do
          begin
            f.is_completed = false
            result = block.call
            f.value0 = result
            f.is_completed = true
            c.send(1)
          rescue err
            f.error = err
            f.is_error = true
            f.is_completed = true
            c.send(err)
          end
        end
        f
      end

      def self.of(value : A) : Future(A) forall A
        f = Future::Success(A).new(value)
        f.is_completed = true
        f
      end

      def flat_map(&block : A -> Future(B)) : Future(B) forall B
        bind(block)
      end

      def bind(&block : A -> Future(B)) : Future(B) forall B
        begin
          channel.receive if is_completed == false && self.is_a?(Future::Processing)
        rescue e
          @error = e
          is_error = true
        end

        if self.is_a?(Future::Processing)
          @is_error == false ? block.call(self.value0) : (f = Future::Failure(A).new; f.error = @error; f)
        elsif self.is_a?(Future::Success)
          @is_error == false ? block.call(self.value0) : (f = Future::Failure(A).new; f.error = @error; f)
        else
          self
        end
      end

      def unwrap : A
        r = bind { |x| Future::Success(A).new(x) }
        if r.is_a?(Future::Success)
          r.value0
        elsif r.is_a?(Future::Processing)
          r.value0
        else
          raise r.error
        end
      end

      def flatten : A
        unwrap
      end

      def get : A
        unwrap
      end

      def get_or_else(default : A) : A
        self.is_a?(Future::Success) ? self.value0 : default
      end

      def get_option : Option(A)
        self.is_a?(Future::Success) ? Option::Some(A).new(self.value0) : Option::None(A).new
      end

      def get_result
        self.is_a?(Future::Success) ? Result::Ok(A, Excception).new(self.value0) : Result::Err(A, Exception).new(self.error)
      end

      def has_value
        self.is_a?(Future::Success) ? true : false
      end
    end
end
