require "spec"
require "./spec_helper"
# include CRZ

adt IntList,
  Empty,
  Cons(Int32, IntList)


adt IntResult,
  Error,
  Success(Int32)

adt Res(T, E),
  Error(E),
  Success(T),
  Empty

adt Res(T, E),
  Error(E),
  Success(T),
  Empty


adt Pair(A, B), Pair(A, B)


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

    v = IntList.match(empty, IntList, {
      [Empty] => 1,
      [_]     => 2,
    })
    v.should eq 1

    IntList.match(empty, IntList, {
      [Cons, x, xs] => 2,
      [_]           => 1,
    }).should eq 1

    IntList.match(cons, IntList, {
      [Cons, x, xs] => x,
      [_]           => 2,
    }).should eq 1

    IntList.match(cons, IntList, {
      [Cons, 0, xs] => 2,
      [_]           => 1,
    }).should eq 1

    IntList.match(cons, IntList, {
      [Cons, 0, xs] => 1,
      [Cons, 1, xs] => 2,
      [_]           => 3,
    }).should eq 2
  end

  it "generates equality for non generic adts" do
    r1 = IntResult::Error.new
    r2 = IntResult::Error.new
    r1.should eq r2

    IntResult::Success.new(1).should eq IntResult::Success.new(1)
    (IntResult::Success.new(1) == IntResult::Success.new(2))
      .should eq false

    (IntResult::Success.new(1) == IntResult::Error)
      .should eq false

    IntList::Cons.new(1, IntList::Empty.new)
      .should eq IntList::Cons.new(1, IntList::Empty.new)
  end

  it "generates equality for generic adts" do
    r1 = Res::Error(String, String).new "1"
    r2 = Res::Error(String, String).new "1"
    r1.should eq r2

    r3 = Res::Empty(String, String).new
    r4 = Res::Empty(String, String).new
    r3.should eq r4

    Res::Empty(String, Int32).new.should eq Res::Empty(String, String).new

    Res::Success(Int32, Int32).new(1).should eq Res::Success(Int32, Int32).new(1)
    (Res::Success(Int32, Int32).new(1) == Res::Success(Int32, Int32).new(2))
      .should eq false
  end

  it "generates equality for adt classes" do
    Option.of(1).should eq Option.of(1)
    (Option.of(1) == Option.of(2)).should eq false
    Option::None(Int32).new.should eq Option::None(Int32).new
    (Option::None(Int32).new == Option::Some.new(1)).should eq false
  end

  it "generates clone method" do
    Pair::Pair.new(1, 2).clone.should eq Pair::Pair.new(1, 2)
  end
end
