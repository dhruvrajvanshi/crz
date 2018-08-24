require "spec"
require "./spec_helper"

describe Option do
  it "creates Option::Some from constructor" do
    o = Option::Some.new 42
    o.value0.should eq 42
    typeof(o).should eq Some(Int32)
    (o.responds_to? :map).should eq true
    (o.responds_to? :bind).should eq true
    (o.responds_to? :ap).should eq true
    (o.responds_to? :>>).should eq true
    (o.responds_to? :<<).should eq true
    (o.responds_to? :>=).should eq true
    (o.responds_to? :*).should eq true
  end

  it "creates Option::None from constructor" do
    o = Option::None(Int32).new
    typeof(o).should eq None(Int32)
    (o.responds_to? :map).should eq true
    (o.responds_to? :bind).should eq true
    (o.responds_to? :ap).should eq true
    (o.responds_to? :>>).should eq true
    (o.responds_to? :<<).should eq true
    (o.responds_to? :>=).should eq true
    (o.responds_to? :*).should eq true
  end

  it "implements of method" do
    o = Option.of(2)
    typeof(o).should eq Some(Int32)
  end

  it "works as a functor" do
    some = Some.new 34
    mapped = some.map do |x|
      x.should eq 34
      x + 1
    end
    Option.match mapped, {
      [Some, x] => (x.should eq 35),
      [_]       => (1.should eq 2),
    }

    string_option = mapped.map &.to_s
    Option.match string_option, {
      [Some, x] => (x.should eq "35"),
      [_]       => (1.should eq 2),
    }

    none = Option::None(Int32).new
    mapped = none.map do |x|
      1.should eq 2
      x + 3
    end

    Option.match mapped, {
      [Some, x] => (1.should eq 2),
      [None]    => (1.should eq 1),
    }
  end

  it "works as an applicative" do
    someF = Option.of ->(x : Int32) {
      x + 1
    }
    some12 = Option.of(12)
    some12.unwrap.should eq 12

    none = Option::None(Int32).new
    applied = none.ap(someF)
    applied.has_value.should eq false

    noop = Option::None(Int32 -> Int32).new
    some12.ap(noop).has_value.should eq false

    f = ->(x : Int32, y : Int32) {
      x + y
    }

    (lift_apply f.call, some12, Option.of(2)).unwrap.should eq 14
    (lift_apply sum, some12, Option.of(2)).unwrap.should eq 14

    (lift_apply sum, Option.of(1), Option.of(2), Option.of(3)).unwrap.should eq 6

    (lift_apply sum, Option.of(1), Option::None(Int32).new, Option.of(2)).has_value.should eq false
  end

  it "works as a monad" do
    (Option.of(1).bind { |x| Option.of(x + 1) }).unwrap.should eq 2
    (Option::None(Int32).new.bind { |x| Option.of(x + 1) }).has_value.should eq false
    (Option.of(1).bind { |x| Option::None(Int32).new }).has_value.should eq false

    mdo({
      x <= Option.of(1),
      y <= Option.of(2),
      Option.of(x + y),
    }).unwrap.should eq 3

    mdo({
      x <= Option.of(1),
      a = x + 1,
      y <= Option.of(2),
      Option.of(a + y),
    }).unwrap.should eq 4
    mdo({
      x <= Option.of(1),
      y <= Option::None(Int32).new,
      z <= Option.of(2),
      Option.of(x + y + z),
    }).has_value.should eq false

    mdo({
      x <= Option.of(1),
      y <= mdo({
        a <= Option.of(3),
        b <= Option.of(3),
        c = 4,
        Option.of(a + b + c),
      }),
      z <= Option.of(2),
      Option.of(x + y + z),
    }).unwrap.should eq 13
  end

  it "implements >> operator" do
    o = Option.of(1) >> Option.of(2)
    o.unwrap.should eq 2

    o = Option.of(1) >> None(Int32).new
    o.class.should eq None(Int32)

    o = None(Int32).new >> Option.of(1)
    o.class.should eq None(Int32)
  end

  it "implements << operator" do
    o = Option.of(1) << Option.of(2)
    o.unwrap.should eq 1

    o = Option.of(1) << None(Int32).new
    o.class.should eq None(Int32)

    o = None(Int32).new << Option.of(1)
    o.class.should eq None(Int32)
  end

  it "unwrap_or" do
    Option.of(1).unwrap_or_else(0).should eq 1
    Option::None(Int32).new.unwrap_or_else(0).should eq 0
  end
end

def sum(*args)
  result = 0
  args.each { |x| result += x }
  result
end
