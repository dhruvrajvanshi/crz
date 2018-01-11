require "spec"
require "./spec_helper"

describe CRZ do
  it "has correct implementation of id" do
    id(1).should eq 1
    id(true).should eq true
    id("asdf").should eq "asdf"
  end

  it "has correct implementation of map" do
    some3 = map ->(x : Int32) {
      x.should eq 2
      x + 1
    }, Option::Some.new(2)
    some3.unwrap.should eq 3
  end
end
