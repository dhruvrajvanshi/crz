require "spec"
describe Nilable do
  it "implements pure method" do
    o = Nilable.pure(2)
    typeof(o).should eq Nilable(Int32)
  end

  it "works as a functor" do
    some = Nilable.pure 34
    mapped = some.map do |x|
      x + 1
    end

    mapped.value.should eq 35

    string_Nilable = mapped.map &.to_s
    string_Nilable.value.should eq "35"

    none = Nilable(Int32).new nil
    mapped = none.map do |x|
      1.should eq 2
      x + 3
    end

    mapped.value.should eq nil
  end

  it "works as an applicative" do
    someF = Nilable.pure ->(x : Int32) {
      x + 1
    }
    some12 = Nilable.pure(12)
    some12.value.should eq 12

    none = Nilable(Int32).new nil
    applied = none.ap(someF)
    applied.value.should eq nil

    noop = Nilable(Int32 -> Int32).new
    some12.ap(noop).value.should eq nil

    f = ->(x : Int32, y : Int32) {
      x + y
    }

    (lift_apply f.call, some12, Nilable.pure(2)).value.should eq 14
    (lift_apply sum, some12, Nilable.pure(2)).value.should eq 14

    (lift_apply sum, Nilable.pure(1), Nilable.pure(2), Nilable.pure(3)).value.should eq 6

    (lift_apply sum, Nilable.pure(1), Nilable(Int32).new, Nilable.pure(2)).value.should eq nil
  end

  it "works as a monad" do
    (Nilable.pure(1).bind { |x| Nilable.pure(x + 1) }).value.should eq 2
    (Nilable(Int32).new.bind { |x| Nilable.pure(x + 1) }).value.should eq nil
    (Nilable.pure(1).bind { |x| Nilable(Int32).new }).value.should eq nil

    mdo({
      x <= Nilable.pure(1),
      y <= Nilable.pure(2),
      Nilable.pure(x + y),
    }).value.should eq 3

    mdo({
      x <= Nilable.pure(1),
      a = x + 1,
      y <= Nilable.pure(2),
      Nilable.pure(a + y),
    }).value.should eq 4
    mdo({
      x <= Nilable.pure(1),
      y <= Nilable(Int32).new,
      z <= Nilable.pure(2),
      Nilable.pure(x + y + z),
    }).value.should eq nil

    mdo({
      x <= Nilable.pure(1),
      y <= mdo({
        a <= Nilable.pure(3),
        b <= Nilable.pure(3),
        c = 4,
        Nilable.pure(a + b + c),
      }),
      z <= Nilable.pure(2),
      Nilable.pure(x + y + z),
    }).value.should eq 13
  end
end

def sum(*args)
  result = 0
  args.each { |x| result += x }
  result
end
