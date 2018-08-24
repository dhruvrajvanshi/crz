# CRZ [![Build Status](https://travis-ci.org/dhruvrajvanshi/crz.svg?branch=master)](https://travis-ci.org/dhruvrajvanshi/crz)
CRZ is a functional programming library for the Crystal language.

## Features
* Common monads
  - Option
  - Nilable
  - Result
* Algebraic data types (using macros).
* Automatic generation of `==` and `copy_with` methods like builtin `records` macro.
* Haskell like do notation (more macro goodness).
* Macros for Applicative types.
* Pattern matching

## Goals
* Make working with monads/applicatives/functors as pleasant as possible (using macros if needed).
* Enable type safe error handling in the language (using Result(A, E) type).
* Emulate algebraic data types using macros.
* Make working with algebraic types type safe and easy using pattern matching.

## Changelog
### 1.0.0
Breaking changes:
- `==` method is now overridden for adt variants meaning that it will now use value equality instead of reference equality. i.e.
  `Option::Success.new(1) == Option::Success.new(1)` will always be true.
- `adt_class` macro has been removed. Instead, you
  can simply pass a block containing your custom methods to the `adt` macro.

## Quickstart
Add this to your shard.yml
```yaml
crz:
  git: dhruvrajvanshi/crz
  version: ~> 1.0.0
```

Then run `crystal deps` in your project directory.

```crystal
include CRZ
```
### Algebraic data types
Algebraic data types are a lightweight way of defining data types
that can be one of multiple sub types, each having its own data values.
Think of them as a single abstract base class with multiple subclasses.

CRZ provides macros for creating algebraic types with overloaded equality (`==`)
and `to_s` (TODO) methods.

Define basic algebraic type using adt
```
## A list type for integers
adt IntList, # name of tye new type
  Empty,
  Cons(Int32, IntList)

```

This declares a type Int list, which can either be an empty list
(subtype IntList::Empty), or an IntList::Cons which contains a head
element (Int32 type) and a tail element which is another IntList.
```crystal
# Creating adt values
empty = IntList::Empty.new
listWithJust1 = IntList::Cons.new 1, empty
listWith0And1 = IntList::Cons.new 0, (IntList::Cons.new 1, IntList::Empty.new)
## or
listWith0And1 = IntList::Cons.new 0, listWithJust1
```

#### Named fields
```crystal
adt Point,
  Named { x : Int32, y : Int32 },
    // property x : Int
    // property y : Int

  PartiallyNamed { x: Int32, Int32 },
    // property x : Int32
    // property value1 : Int32

  Unnamed { Int32, Int32 }
    // property value0 : Int32
    // property value1 : Int32
```

In case no name is provided, the name of the property will be
`@valueN`, where `N` is the index of the field for that constructor

#### Accesing values of ADT variants
Each ADT variant (subtype) has instance variables @value0, @value1,
etc according to their index in the data type.
```crystal
head = listWith0And1.value0
```
This method is there but does not utilize the full power of CRZ ADTs.

#### Cloning and copying
Each variant has a `clone` method that makes a copy of that object.

`copy_with` method is like clone but fields can be updated individually.

```crystal
adt Point, P {x : Int32, y : Int32}

Point::P.new(1, 2).copy_with(3, 4) # => Point::P(3, 4)

# Or using field label
Point::P.new(1, 2).copy_with(y: 3) # => Point::P(1, 3)

```
If you don't pass a field to `copy_with`, the one from the current
object is used as a default value. i.e. `copy_with` without any arguments
works like `clone`.


#### Pattern matching
All user defined ADTs allow getting values from them using pattern matching. You can write cases corresponding to each variant in the data type and conditionally perform actions.
Example
```crystal
head = IntList.match listWithJust1, IntList, {
  [Cons, x, xs] => x,
  [Empty] => nil
}
puts head # => 1
```
Notice the comma after the variant name (Cons,). This is required.

Also note that the second argument to .match is the type of the value you're matching over. This is necessary because for generic ADTs, the match macro needs the concrete type of the generic arguments. Otherwise, the binding of generic values in matching can't be done.

You can use [_] pattern as a catch all pattern.

```crystal
head = IntList.match empty, IntList, {
  [Cons, x, xs] => x,
  [_] => nil
}
```
Note that ordering of patterns matters. For example,
```crystal
IntList.match list, IntList, {
  [_] => nil,
  [Cons, x, xs] => x,
  [Empty] => 0
}
```
This will always return nil because ```[_]``` matches everything.


You can also use constants in patterns. For example
```crystal
has0AsHead = IntList.match list, IntList, {
  [Cons, 0, _] => true,
  [_] => false
}
```

You can write statements inside match branches ising Proc literals.
```crystal
IntList.match list, IntList, {
  [Empty] => ->{
    print "here"
    ...
  }.call
}
```
You have to add .call at the end of the proc otherwise, it will be returned as a value instead of being called.

For values with named fields, using a `case` expression is somewhat cleaner.

```crystal
adt X,
  A { a : Int32 },
  B { b : String }

x = X::A.new a: 1
...

case x
when X::A
  # type of x will be narrowed to X::A at compile time
  x.a
else
  # Inferred as X::B
  x.b
end
```

#### Generic ADTs
You can also declare a generic ADTs.
Here's a version of IntList which can be instantiated for any type.
```crystal
adt List(A),
  Empty,
  Cons(A, List(A))

empty = List::Empty(Int32).new # Type annotation is required for empty
cons  = List::Cons.new 1, empty # type annotation isn't required because it is inferred from the first argument
head = List.match cons, List(Int32), { # Just List won't work here, it has to be concrete type List(Int32)
  [Cons, x, _] => x,
  [_] => nil
}
```

#### Adding custom methods
You may need to add methods to your ADTs. This can be done by passing a block to the `adt` macro.
For example, here's a partial implementation of `CRZ::Containers::Option` with a few members excluded for brevity.
```crystal
adt Option(A),
    Some(A),
    None,
    do
      include Monad(A)

      def to_s
        Option.match self, Option(A), {
          [Some, x] => "Some(#{x})",
          [None]    => "None",
        }
      end

      def bind(&block : A -> Option(B)) : Option(B) forall B
        Option.match self, Option(A), {
          [Some, x] => (block.call x),
          [None]    => None(B).new,
        }
      end
      ...
    end
```
Now all Option values have bind and to_s methods defined on them.
```crystal
puts Some.new(1).to_s # => Some(1)
puts None(Int32).new.to_s # => None
```
Notice that the class has to be abstract and the class name has to be
ADT followed by the name of the type you're declaring otherwise, it won't work.

### Container types (Monads)
CRZ defines a few container types which can be used. All of them implement the Monad interface which gives them certain properties that make them really powerful. 
One of them is `CRZ::Option` which can either contain a value or nothing.
```crystal
# Creating an option
a = Option::Some.new 1
none = Option::None(Int32).new

# you can omit base class name due to type aliases
# defined in CRZ namespace
a = Some.new 2
b = None(Int32).new

# pattern matching over Option
Option.match a, Option(Int32), {
  [Some, x] => "Some(#{x})",
  [_] => "None"
} # ==> Some(1)
```
The idea of the optional type is that whichever functions or methods that can only return a value in some cases should return an Option(A).
The Option type allows you to write clean code without unnecessary nil checks.

You can transform Options using the .map method
```crystal
option = Some.new(1) # Some(1)
          .map {|x| x+1}     # Some(2)
          .map {|x| x.to_s}  # Some("2")
          .map {|s| "asdf" + s} # Some("asdf2")
puts option.to_s # ==> Some(asdf2)
```
This allows you to take functions that work on the contained type and apply them to the container. Mapping over Option::None returns an Option::None.
```crystal
None(Int32).new
  .map {|x| x.to_s} # None(String)
```
Notice that mapping changes the type of the Option from Option(Int32) to Option(String).

The .bind method is a bit more powerful than the map method. It allows you to sequence computations that return Option (or any Monad).
Instead of a block of type `A -> B` like map, the bind method takes a block from `A -> Option(B)` and returns Option(B).
For example
```crystal
Some.new(1)
  .bind do |x|
    if x == 0
      None(Int32).new
    else
      Some.new(x)
    end
  end
```
The bind is more powerful than you might think. It allows you to combine arbitrary Monads into a single Monad.

### Sequencing with mdo macro
What if you have multiple Option types and you want to apply some
computation to their contents without having to manually unwrap their
contents using pattern matching?. There's a way to operate over monads
using normal functions and expressions.
You can do that using mdo macro inspired by Haskell's do notation.
```crystal
c = mdo({
  x <= Some.new(1),
  y <= Some.new(2),
  Some.new(x + y)
})
puts c # ==> Some(3)
```
Here, <= isn't the comparison operator. It's job is to bind the
value contained in the monad on it's RHS to the variable on it's left.
Think of it as an assignment for monads. Make sure that the RHS value
for <= inside a mdo block is a monad. Any assignments made like this
can be used in the rest of the mdo body.
You can also use regular assignments in the mdo block to assign regular values.
```crystal
c = mdo({
  x <= some_option,
  ...
  y <= another_option,
  a = x+y,
  ...
  Some.new(a)
})
```
If an Option::None is bound anywhere in the mdo body, it short
circuits the entire block and returns a Nothing. The contained type of the nothing will still be
the contained type of the last expression in the block.
```crystal
c = mdo({
  x <= some_option,
  ...
  y <= none_option,
  ...
  ...
})
puts c.to_s # ==> None
```

Think of what you'd have to do to achieve this result without using mdo or bind.
Instead of this,
```crystal
# instead of this
c = mdo({
  x <= a,
  y <= b,
  Some.new(x + y)
})
```
You'd have to write this
```crystal
Option.match a, Option(Int32), {
  [Some, x] => Option.match b, Option(Int32), {
    [Some, y] => Some.new(x+y),
    [None] => None(Int32).new
  },
  [None] => None(Int32).new
}
```
This is harder to read and doesn't scale well to more variables. If you have 10
Option values, you'd have to nest 10 pattern matches.
If you used regular nillable values that the language provides, then it would
turn into nested nil checks which is the same thing.

Always have a monadic value as the last expression of the mdo block. If you don't,
the return type of mdo block will be (A | None(A)).

Remember when I said .bind method is really powerful? An mdo block is transformed
into nested binds during macro expansion.

There's an even cleaner way to write combination of monads.

### lift_apply macro
Suppose you have a function like
```crystal
def sum(x, y)
  x + y
end
```
and you want to apply this function to two monads instead of two values.
You can use an mdo block but an even cleaner way is to write
```
lift_apply sum, Some.new(1), Some.new(2)
```
You can also use a proc
```
lift_apply proc.call, monad1, monad2, ...
```
Just like mdo, this is also converted into nested .bind calls during macro expansion.

It is advisable to keep your values inside monads for as long as possible and match
over them at the end. You already know how to use regular functions over monadic values.

### Other operators on monads
All monads implement these methods
* .of
* ```>>```
* ```<<```

To create a monad from a single value, use the .of method
```crystal
Option.of(2) # => Some(2)
Result(Int32, String).of(2) # => Ok(2)
```

To sequence two monads, discarding the value of the first monad, use the operator ```>>```
```crystal
Option.of(2) >> Option.of(3) # => Some(3)
None(Int32).new >> Option.of(3) # => None
Option.of(2) >> None(Int32).new # => None
```

To sequence two monads, discarding the value of the second
monad, use the ```<<``` operator.
```crystal
Option.of(2) << Option.of(3) # => Some(2)
```

### Implementing your own monads
To implement your own monadic types, you have to include the Monad(T) module in your class, and you have to implement
the .of, bind and map methods (you can omit the map method if
your monad takes only one generic type argument). of method
is a static method, so, it is named self.of.
For example, Option type is defined as
```crystal
adt_class Option(A),
    Some(A), None,
    abstract class ADTOption(A)
      include Monad(A)

      def self.of(value : T) : Option(T) forall T
        Option::Some.new(value)
      end

      def bind(&block : A -> Option(B)) : Option(B) forall B
        Option.match self, Option(A), {
          [Some, x] => (block.call x),
          [None]    => Option::None(B).new,
        }
      end
    end
```
In case your type requires more than 1 generic argument, you
can implement the map method in a straightforward way using
the bind and of methods.
```crystal
class YourType(A1, A2)
  include Monad(A1)

  ...

  def map(&block : A1 -> B) : YourType(B, A2) forall B
    bind do |x|
      YourType(B, A2).of(block.call x)
    end
  end
end

# or, in case your monad is based on the second generic arg,
class YourType(A1, A2)
  include Monad(A2)

  ...

  def map(&block : A2 -> B) : YourType(A1, B) forall B
    bind do |x|
      YourType(A1, B).of(block.call x)
    end
  end
end
```
Any monads you define will be compatible with mdo and
lift_apply macros.