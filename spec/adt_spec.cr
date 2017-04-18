require "spec"
require "./spec_helper"
# include CRZ

adt IntList,
  Empty,
  Cons(Int32, IntList)


describe CRZ do
  it "creates constructors for non generic adt" do
    empty = IntList::Empty.new
    cons = IntList::Cons.new 1, empty
    cons.value0.should eq 1
    cons.value1.should eq empty
  end

  it "works with pattern matching" do
    empty = IntList::Empty.new
    cons = IntList::Cons.new 1, empty

    v = IntList.match(empty, {
      [Empty] => 1,
      [_]     => 2,
    })
    v.should eq 1

    IntList.match(empty, {
      [Cons, x, xs] => 2,
      [_]           => 1,
    }).should eq 1

    IntList.match(cons, {
      [Cons, x, xs] => x,
      [_]           => 2,
    }).should eq 1

    IntList.match(cons, {
      [Cons, 0, xs] => 2,
      [_]           => 1,
    }).should eq 1

    IntList.match(cons, {
      [Cons, 0, xs] => 1,
      [Cons, 1, xs] => 2,
      [_]           => 3,
    }).should eq 2

    IntList.match(cons, {
      [Cons, 0, xs] => 1,
      [_]           => 3,      
      [Cons, 1, xs] => 2,
    }).should eq 3

    IntList.match(empty, {
      [Cons, 0, xs] => 1,
      [_]           => 3,      
      [Cons, 1, xs] => 2,
    }).should eq 3

    IntList.match(empty, {
      [Cons, 0, xs] => 1,
      [Cons, _, _] => 2,
      [Empty] => 3
    }).should eq 3
  end
end
