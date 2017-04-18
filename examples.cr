require "./src/crz"
include CRZ

# # Basic algebraic data type
adt IntList,
  Empty,
  Cons(Int32, IntList)

empty = IntList::Empty.new
listWithJust1 = IntList::Cons.new 1, empty
listWith0And1 = IntList::Cons.new 0, (IntList::Cons.new 1, IntList::Empty.new)
## or
listWith0And1 = IntList::Cons.new 0, listWithJust1

pp empty
pp listWithJust1
pp listWith0And1

head = IntList.match listWithJust1, {
	[Cons, x, xs] => x,
	[Empty] => nil
}

pp head


adt List(A),
	Empty,
	Cons(A, List(A))

empty = List::Empty(Int32).new
cons  = List::Cons.new 1, empty
head = List.match cons, { # Just List won't work here, it has to be concrete type List(Int32)
	[Cons, x, _] => x,
	[_] => nil
}

pp head
option = Option::Some.new(1)
          .map {|x| x+1}
          .map {|x| x.to_s}
          .map {|s| "asdf" + s}
puts option.to_s

def sum(x, y)
  x + y
end

a = lift_apply sum, Option::Some.new(1), Option::Some.new(2)
puts a.to_s

c = mdo({
  x <= Option::Some.new(1),
  y <= Option::Some.new(2),
  Option::Some.new(x + y)
})
puts c.to_s # ==> Some(3)