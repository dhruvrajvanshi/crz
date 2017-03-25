require "./src/crz"
include CRZ

# # Basic algebraic data type
adt IntList, {
  Empty,
  Cons(Int32, IntList),
}

pp IntList::Empty.new
