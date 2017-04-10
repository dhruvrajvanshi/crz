require "./spec_helper"

describe "chain macro" do
  it "chain works on functions" do
    res = chain 1, increment, to_s
    res.should eq "2" 
  end

  it "chain works on procs" do
    res = chain 2, ->(x : Int32) {x*2}.call, ->(x : Int32){x+1}.call
    res.should eq 5
  end
end

def increment(x)
  x + 1
end

def to_s(x)
  x.to_s
end