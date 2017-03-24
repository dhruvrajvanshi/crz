# This is raised when either complete, success or failure is called
# on an already completed promise.
class IllegalStateException < Exception
end

# If you select over a `Future` with a predicate that returns
# false fot the value of the Future, the resulting future
# fails with this exception
class PredicateFailureException < Exception
end

# Raised when `Try(T)#get` is called on a `Failure(T)` instance
class NoSuchElementException < Exception
end

# A Future represents an asynchronous computation that
# returns a value.
# Callbacks can be registered against futures to
# run when the computation completes or fails
#
# Eg.
# ```
# a = Future.new do
#   someTimeConsumingOperation()
# end
# a.on_success do |val|
#   doSomethingWithResult val
# end
# ```
# You can compose new futures using existing ones by
# calling `map` on them. Composed futures will succeed
# only when parent succeeds.
#
# Eg.
# ```
# b = a.map do |x|
#   x + 1
# end
# ```
class Future(T)
  getter value

  # Constructor for a future
  # Call Future.new with a block to get a future value
  # Pass in an optional `ExecutionContext` do define
  # execution behaviour of the Future. By default, it
  # creates a new `InfiniteFiberExecutionContext` for
  # each instance.
  def initialize(
                 @execution_context = InfiniteFiberExecutionContext.new,
                 &block : -> T)
    @completed = false
    @succeeded = false
    @failed = false
    @value = None(Try(T)).new
    @blocked_on_this = 0
    @on_failure = [] of Exception -> Void
    @on_success = [] of T -> Void
    @on_complete = [] of (Future(T)) -> Void
    @completion_channel = Channel::Unbuffered(Int32).new
    @block = block
    execute()
  end

  # Returns a Future with the function applied to
  # the result
  def map(&block : T -> U)
    Future(U).new @execution_context do
      block.call(self.get)
    end
  end

  # Returns a new future that succeeds if current
  # future succeeds and it's value matches the given
  # predicate
  def select(&block : T -> Bool)
    Future(T).new @execution_context do
      if val = block.call(self.get)
        next @value.get.get
      else
        raise PredicateFailureException.new "Future select predicate failed on value #{val}"
      end
    end
  end

  # Alias for `Future.select`
  def filter(&block : T -> Bool)
    self.select(&block)
  end

  # Return a future whose exceptions are handled by
  # the block.
  # Eg.
  # ```
  # a = Future.new { networkCall }
  # a.recover do |e|
  #   case e
  #   when Timeout
  #     "Something"
  #   when ServerError
  #     "Something Else"
  #   else
  #     # Remember to raise e in the else case
  #     raise e
  #   end
  # end
  # ```
  def recover(&block : Exception -> T)
    Future(T).new @execution_context do
      begin
        self.get
      rescue e
        block.call(e)
      end
    end
  end

  # Register a callback to be called when the Future
  # succeeds. The callback is called with the value of
  # the future
  # Eg.
  # ```
  # f.on_success do |value|
  #   do_something_with_value value
  # end
  # ```
  def on_success(&block : T -> _)
    @on_success << block
    if (@succeeded)
      @execution_context.execute do
        block.call(@value.get.get.as T)
      end
    end
    self
  end

  # Register a callback to be called when the Future
  # fails
  def on_failure(&block : Exception -> _)
    @on_failure << block
    if (@failed)
      @execution_context.execute do
        block.call(self.error.as Exception)
      end
    end
    self
  end

  # Register a callback to be called when the Future
  # completes. The callback will be called an instance of
  # `Try(T)`
  # Eg.
  # ```
  # f.on_complete do |t|
  #   case t
  #   when Success
  #     print "Got #{t.get}"
  #   when Failure
  #     raise t.error
  #   end
  # end
  # ```
  def on_complete(&block : Future(T) -> _)
    @on_complete << block
    if @completed
      @execution_context.execute do
        block.call(self)
      end
    end
    self
  end

  # Returns true if computation completed or error thrown
  # false otherwise
  def completed?
    return @completed
  end

  # Returns true if processing succeeded.
  def succeeded?
    return @succeeded
  end

  # Returns true if processing failed
  def failed?
    return @failed
  end

  # Blocks untill future to complete and returns
  # the value. Raises exception failure occurs. Returns the
  # value if already complete
  def get
    if @completed
      @value.get.get
    else
      @blocked_on_this += 1
      @completion_channel.receive
      @value.get.get
    end
  end

  # This returns the error produced by the Future if any.
  # If the future isn't complete or it completed successfully,
  # it returns nil. This makes it indistinguishable from success
  # in case of a future of type Nil.
  # Don't use this method. Use `Future#get` instead to get
  # a single value which indicates whether Future is complete
  # or not(`None`/`Some`) and whether the operation was a
  # success or failure(`Success`/`Failure`).
  # To get the error of a failed future, do
  # ```
  # future.get.error
  # ```
  # Note that this will result in a NoSuchElementException
  # in case the future hasn't been completed
  def error
    case @value
    when None(Try(T))
      nil
    when Some(Try(T))
      v = @value.get
      case v
      when Success(T)
        nil
      when Failure(T)
        v.error
      end
    end
  end

  private def execute
    @execution_context.execute do
      begin
        @value = Some(Try(T)).new(Success(T).new @block.call)
        @succeeded = true
        @failed = false
        @on_success.each do |callback|
          @execution_context.execute do
            callback.call(@value.get.get)
          end
        end
      rescue e
        @value = Some(Try(T)).new(Failure(T).new e)
        @failed = true
        @succeeded = false
        @execution_context.execute do
          @on_failure.each do |callback|
            callback.call(e)
          end
        end
      ensure
        @completed = true
        @on_complete.each do |callback|
          @execution_context.execute do
            callback.call(self)
          end
        end

        # Send a signal to for each thread blocked
        # on this Future
        @blocked_on_this.times do
          @completion_channel.send(0)
        end
      end
    end
  end
end

# An ExecutionContext can execute program logic
# asynchronously
# Include this module in a class to implement
#
# A block can be passed to the exec method to
# execute it asynchronously
module ExecutionContext
  # Runs a block of code on this execution context
  abstract def execute(&block)

  # Overload for execute that takes an object with
  # a call method
  def execute(callable)
    self.execute do
      callable.call
    end
  end

  def submit(&block : -> T)
    Future.new self do
      value = nil
      ch = Channel::Unbuffered(Int32).new
      self.execute do
        value = block.call
        ch.send 0
      end
      ch.receive
      value.as T
    end
  end
end

# Implements `ExecutionContext`. Every call to `execute`
# spawns a new Fiber
class InfiniteFiberExecutionContext
  include ExecutionContext

  def execute(&block)
    spawn do
      block.call
    end
  end
end

# Try represents a computation that may either result in an
# exception, or return a value.
# Instances of Try(T) are either an instance of `Success(T)`
# or `Failure(T)`
# Eg.
# ```
# a = Success(Symbol).new :hello
# a.get # => :hello
# a = Failure(Symbol).new(Exception.new "Error")
# a.get # => Raises Exception("Error")
# # Pattern match over a Try(T)
# case a
# when Success
#   # do something with result
# when Failure
#   # handle exception
# end
# ```
abstract class Try(T)
  # Returns the value from this `Success` or throws the
  # exception if `Failure`
  abstract def get

  # Returns true if `Try` is a `Success`. false otherwise
  abstract def success?

  # Returns true if `Try` is a `Failure`. false otherwise
  abstract def failure?

  # Converts this to a Failure if the predicate is not satisfied
  abstract def select(&block : T -> Bool)
end

class Success(T) < Try(T)
  getter value

  def initialize(value : T)
    @value = value
  end

  def failure?
    false
  end

  def success?
    true
  end

  def get
    @value
  end

  def select(&block : T -> Bool)
    if block.call(@value)
      self
    else
      Failure(T).new(PredicateFailureException.new)
    end
  end
end

class Failure(T) < Try(T)
  getter error

  def initialize(error : Exception)
    @error = error
  end

  def get
    raise @error
  end

  def failure?
    true
  end

  def success?
    false
  end

  def select(&block : T -> Bool)
    self
  end
end

# Represents optional value. Instances of `Option` are either an
# instance of `Some` or `None`.
abstract class Option(T)
  abstract def get
  abstract def empty?
end

class Some(T) < Option(T)
  def initialize(@value : T)
  end

  def get
    @value
  end

  def empty?
    false
  end
end

class None(T) < Option(T)
  def initialize
  end

  def get
    raise NoSuchElementException.new
  end

  def empty?
    true
  end
end

# Promise is an objectwhich can be completed with a value
# or failed with an exception.
# Eg.
# ```
# p = Promise(Symbol).new
# f = p.future
# f.on_success do |val|
#   puts "Future completed with value #{val}"
# end
# p.success(:Hello)
# ```
# ```
# "Future completed with value Hello"
# ```
class Promise(T)
  getter future

  def initialize
    @completion_channel = Channel::Unbuffered(Symbol).new
    @completed = false
    @result = None(Try(T)).new
    @future = Future(T).new do
      @completion_channel.receive
      v = @result.get.get
    end
  end

  # Returns whether the promise has already been  completed with
  # a value or an exception
  def completed?
    @completed
  end

  # Tries to complete the promise with either a value ot exception
  def try_complete(result : Try(T))
    if completed?
      false
    else
      @completed = true
      @result = Some(Try(T)).new result
      @completion_channel.send :completed
      @future = Future(T).new do
        v = nil
        case @result.get
        when Success
          v = @result.get.get
        when Failure
          raise (@result.get.as Failure).error
        end
        v.as T
      end
      true
    end
  end

  # Completes the promise with a value
  def success(value : T)
    unless try_complete Success(T).new(value)
      raise IllegalStateException.new("Promise\#success called on \
          already completed promise")
    end
  end

  # Completes the promise with an exception
  def failure(error : Exception)
    unless try_complete Failure(T).new(error)
      raise IllegalStateException.new("Promise\#failure called on \
          already completed promise")
    end
  end
end

f = Future.new do
  23
end
f.map do |x|
  x + 1
end
