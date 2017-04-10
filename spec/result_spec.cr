require "spec"
describe Result do
  it "creates Result::Ok from constructor" do
    o = Result::Ok(Int32, String).new 42
    o.value0.should eq 42
    typeof(o).should eq Result::Ok(Int32, String)
    (o.responds_to? :map).should eq true
    (o.responds_to? :bind).should eq true
    (o.responds_to? :ap).should eq true
    (o.responds_to? :>>).should eq true
    (o.responds_to? :<<).should eq true
    (o.responds_to? :>=).should eq true
    (o.responds_to? :*).should eq true
  end

  it "creates Result::Err from constructor" do
    o = Result::Err(Int32, String).new "Error"
    typeof(o).should eq Result::Err(Int32, String)
    (o.responds_to? :map).should eq true
    (o.responds_to? :bind).should eq true
    (o.responds_to? :ap).should eq true
    (o.responds_to? :>>).should eq true
    (o.responds_to? :<<).should eq true
    (o.responds_to? :>=).should eq true
    (o.responds_to? :*).should eq true
  end

  it "implements of method" do
    o = Result(Int32, String).of 2
    typeof(o).should eq Result::Ok(Int32, String)
  end

  it "works as a functor" do
    ok = Result::Ok(Int32, String).new 34
    mapped = ok.map do |x|
      x.should eq 34
      x + 1
    end
    Result.match mapped, Result(Int32, String), {
      [Ok, x] => (x.should eq 35),
      [_]       => (1.should eq 2),
    }

    string_result = mapped.map &.to_s
    Result.match string_result, Result(String, String), {
      [Ok, x] => (x.should eq "35"),
      [_]       => (1.should eq 2),
    }

    err = Result::Err(Int32, String).new "Error"
    mapped = err.map do |x|
      1.should eq 2
      x + 3
    end

    Result.match mapped, Result(Int32, String), {
      [Ok, x] => (1.should eq 2),
      [Err, e]    => (e.should eq "Error"),
    }
  end

  it "works as an applicative" do
    okF = Result::Ok((Int32 -> Int32), String).new ->(x : Int32) {
      x + 1
    }
    ok12 = Result::Ok(Int32, String).new(12)
    ok12.unwrap.should eq 12

    none = Result::Err(Int32, String).new "Err"
    applied = none.ap(okF)
    applied.has_value.should eq false

    noop = Result::Err((Int32 -> Int32), String).new "Err"
    ok12.ap(noop).has_value.should eq false

    f = ->(x : Int32, y : Int32) {
      x + y
    }

    ok1 = Result::Ok(Int32, String).new 1
    ok2 = Result::Ok(Int32, String).new 2
    ok3 = Result::Ok(Int32, String).new 3

    (lift_apply f.call, ok12, ok2).unwrap.should eq 14
    (lift_apply sum, ok12, ok2).unwrap.should eq 14

    (lift_apply sum, ok1, ok2, ok3).unwrap.should eq 6

    (lift_apply sum, ok1, none, ok2).has_value.should eq false
  end

  it "works as a monad" do
    ok1 = Result::Ok(Int32, String).new(1)
    (ok1.bind { |x| Result::Ok(Int32, String).new(x + 1) }).unwrap.should eq 2
    (Result::Err(Int32, String).new("Err").bind { |x| Result(Int32, String).of(x + 1) }).has_value.should eq false
    (ok1.bind { |x| Result::Err(Int32, String).new "Err" }).has_value.should eq false

    ok2 = Result::Ok(Int32, String).new(2)
    ok3 = Result::Ok(Int32, String).new(3)
    mdo({
      x <= ok1,
      y <= mdo({
        a <= ok3,
        b <= ok3,
        c = 4,
        Result(Int32, String).of(a + b + c),
      }),
      z <= ok2,
      Result(Int32, String).of(x + y + z),
    }).unwrap.should eq 13
  end
end

def sum(*args)
  result = 0
  args.each { |x| result += x }
  result
end
