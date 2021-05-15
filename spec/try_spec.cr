require "spec"
# require "./spec_helper"

describe "Try" do
  it "creates Try::Success from constructor" do
    o = Try::Success.new 42
    o.value0.should eq 42
    typeof(o).should eq Try::Success(Int32)
    (o.responds_to? :map).should eq true
    (o.responds_to? :bind).should eq true
    (o.responds_to? :ap).should eq true
    (o.responds_to? :>>).should eq true
    (o.responds_to? :<<).should eq true
    (o.responds_to? :>=).should eq true
    (o.responds_to? :*).should eq true
  end

  it "creates Try::Failure from constructor" do
    o = Try::Failure(Int32).new
    typeof(o).should eq Try::Failure(Int32)
    (o.responds_to? :map).should eq true
    (o.responds_to? :bind).should eq true
    (o.responds_to? :ap).should eq true
    (o.responds_to? :>>).should eq true
    (o.responds_to? :<<).should eq true
    (o.responds_to? :>=).should eq true
    (o.responds_to? :*).should eq true
  end

  it "implements of method" do
    o = Try.of(2)
    typeof(o).should eq Try::Success(Int32)
  end

  it "works as a functor" do
    success = Try::Success.new 34
    mapped = success.map do |x|
      x.should eq 34
      x + 1
    end
  end

  it "works as an applicative" do
    successf = Try.of ->(x : Int32) {
      x + 1
    }
    successf12 = Try::Success.of(12)
    successf12.unwrap.should eq 12

    failure = Try::Failure(Int32).new

    f = ->(x : Int32, y : Int32) {
      x + y
    }

    (lift_apply f.call, successf12, Try.of(2)).unwrap.should eq 14
    (lift_apply sum, successf12, Try.of(2)).unwrap.should eq 14

    (lift_apply sum, Try.of(1), Try.of(2), Try.of(3)).unwrap.should eq 6

    (lift_apply sum, Try.of(1), Try::Failure(Int32).new, Try.of(2)).has_value.should eq false
  end

  it "works as a monad2" do
    (Try.try { 1 }.bind { |x| Try.try { x + 1 } }).unwrap.should eq 2

    mdo({
      x <= Try.try { 1 },
      y <= Try.try { 2 },
      Try.try { x + y },
    }).unwrap.should eq 3

    mdo({
      x <= Try.try { 1 },
      a = x + 1,
      y <= Try.try { 2 },
      Try.try { a + y },
    }).unwrap.should eq 4
    mdo({
      x <= Try.try { 1 },
      y <= Try::Failure(Int32).new,
      z <= Try.of(2),
      Try.of(x + y + z),
    }).has_value.should eq false

    mdo({
      x <= Try.of(1),
      y <= mdo({
        a <= Try.try { 3 },
        b <= Try.try { 3*1 },
        c = 4,
        Try.of(a + b + c),
      }),
      z <= Try.of(2),
      Try.of(x + y + z),
    }).unwrap.should eq 13
  end

  it "works as a monad" do
    (Try.of(1).bind { |x| Try.of(x + 1) }).unwrap.should eq 2
    (Try::Failure(Int32).new.bind { |x| Try.of(x + 1) }).has_value.should eq false
    (Try.of(1).bind { |x| Try::Failure(Int32).new }).has_value.should eq false

    mdo({
      x <= Try.of(1),
      y <= Try.of(2),
      Try.of(x + y),
    }).unwrap.should eq 3

    mdo({
      x <= Try.of(1),
      a = x + 1,
      y <= Try.of(2),
      Try.of(a + y),
    }).unwrap.should eq 4
    mdo({
      x <= Try.of(1),
      y <= Try::Failure(Int32).new,
      z <= Try.of(2),
      Try.of(x + y + z),
    }).has_value.should eq false

    mdo({
      x <= Try.of(1),
      y <= mdo({
        a <= Try.of(3),
        b <= Try.of(3),
        c = 4,
        Try.of(a + b + c),
      }),
      z <= Try.of(2),
      Try.of(x + y + z),
    }).unwrap.should eq 13
  end

  it "implements >> operator" do
    o = Try.of(1) >> Try.of(2)
    o.unwrap.should eq 2

    o = Try.of(1) >> Try::Failure(Int32).new
    o.class.should eq Try::Failure(Int32)

    o = Try::Failure(Int32).new >> Try.of(1)
    o.class.should eq Try::Failure(Int32)
  end

  it "implements << operator" do
    o = Try.of(1) << Try.of(2)
    o.unwrap.should eq 1

    o = Try.of(1) << Try::Failure(Int32).new
    o.class.should eq Try::Failure(Int32)

    o = Try::Failure(Int32).new << Try.of(1)
    o.class.should eq Try::Failure(Int32)
  end
end

def sum(*args)
  result = 0
  args.each { |x| result += x }
  result
end
