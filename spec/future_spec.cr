require "spec"
require "./spec_helper"

describe "Future" do
  it "creates Future::Success from constructor" do
    o = Future::Success.new 42
    o.value0.should eq 42
    typeof(o).should eq Future::Success(Int32)
    (o.responds_to? :map).should eq true
    (o.responds_to? :bind).should eq true
    (o.responds_to? :ap).should eq true
    (o.responds_to? :>>).should eq true
    (o.responds_to? :<<).should eq true
    (o.responds_to? :>=).should eq true
    (o.responds_to? :*).should eq true
  end

  it "creates Future::Failure from constructor" do
    o = Future::Failure(Int32).new
    typeof(o).should eq Future::Failure(Int32)
    (o.responds_to? :map).should eq true
    (o.responds_to? :bind).should eq true
    (o.responds_to? :ap).should eq true
    (o.responds_to? :>>).should eq true
    (o.responds_to? :<<).should eq true
    (o.responds_to? :>=).should eq true
    (o.responds_to? :*).should eq true
  end

  it "implements of method" do
    o = Future.of(2)
    typeof(o).should eq Future::Success(Int32)
  end

  it "works as a functor" do
    success = Future::Success.new 34
    mapped = success.map do |x|
      x.should eq 34
      x + 1
    end
  end

  it "works as an applicative" do
    successf = Future.of ->(x : Int32) {
      x + 1
    }
    successf12 = Future::Success.of(12)
    successf12.unwrap.should eq 12

    failure = Future::Failure(Int32).new

    f = ->(x : Int32, y : Int32) {
      x + y
    }

    (lift_apply f.call, successf12, Future.of(2)).unwrap.should eq 14
    (lift_apply sum, successf12, Future.of(2)).unwrap.should eq 14

    (lift_apply sum, Future.of(1), Future.of(2), Future.of(3)).unwrap.should eq 6

    (lift_apply sum, Future.of(1), Future::Failure(Int32).new, Future.of(2)).has_value.should eq false
  end

  it "works as a monad2" do
    (Future.spawn(0) { 1 }.bind { |x| Future.spawn(0) { x + 1 } }).unwrap.should eq 2

    mdo({
      x <= Future.spawn(0) { 1 },
      y <= Future.spawn(0) { 2 },
      Future.spawn(0) { x + y },
    }).unwrap.should eq 3

    mdo({
      x <= Future.spawn(0) { 1 },
      a = x + 1,
      y <= Future.spawn(0) { 2 },
      Future.spawn(0) { a + y },
    }).unwrap.should eq 4
    mdo({
      x <= Future.spawn(0) { 1 },
      y <= Future::Failure(Int32).new,
      z <= Future.of(2),
      Future.of(x + y + z),
    }).has_value.should eq false

    mdo({
      x <= Future.of(1),
      y <= mdo({
        a <= Future.spawn(0) { 3 },
        b <= Future.spawn(0) { 3*1 },
        c = 4,
        Future.of(a + b + c),
      }),
      z <= Future.of(2),
      Future.of(x + y + z),
    }).unwrap.should eq 13
  end

  it "works as a monad" do
    (Future.of(1).bind { |x| Future.of(x + 1) }).unwrap.should eq 2
    (Future::Failure(Int32).new.bind { |x| Future.of(x + 1) }).has_value.should eq false
    (Future.of(1).bind { |x| Future::Failure(Int32).new }).has_value.should eq false

    mdo({
      x <= Future.of(1),
      y <= Future.of(2),
      Future.of(x + y),
    }).unwrap.should eq 3

    mdo({
      x <= Future.of(1),
      a = x + 1,
      y <= Future.of(2),
      Future.of(a + y),
    }).unwrap.should eq 4
    mdo({
      x <= Future.of(1),
      y <= Future::Failure(Int32).new,
      z <= Future.of(2),
      Future.of(x + y + z),
    }).has_value.should eq false

    mdo({
      x <= Future.of(1),
      y <= mdo({
        a <= Future.of(3),
        b <= Future.of(3),
        c = 4,
        Future.of(a + b + c),
      }),
      z <= Future.of(2),
      Future.of(x + y + z),
    }).unwrap.should eq 13
  end

  it "implements >> operator" do
    o = Future.of(1) >> Future.of(2)
    o.unwrap.should eq 2

    o = Future.of(1) >> Future::Failure(Int32).new
    o.class.should eq Future::Failure(Int32)

    o = Future::Failure(Int32).new >> Future.of(1)
    o.class.should eq Future::Failure(Int32)
  end

  it "implements << operator" do
    o = Future.of(1) << Future.of(2)
    o.unwrap.should eq 1

    o = Future.of(1) << Future::Failure(Int32).new
    o.class.should eq Future::Failure(Int32)

    o = Future::Failure(Int32).new << Future.of(1)
    o.class.should eq Future::Failure(Int32)
  end
end

def sum(*args)
  result = 0
  args.each { |x| result += x }
  result
end
