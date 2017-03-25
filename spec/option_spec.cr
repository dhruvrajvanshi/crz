require "spec"
describe Option do
  it "Creates Option::Some from constructor" do
    o = Option::Some.new 42
    o.value0.should eq 42
    typeof(o).should eq Option::Some(Int32)
  end

  it "Creates Option::None from constructor" do
    o = Option::None(Int32).new
    typeof(o).should eq Option::None(Int32)
  end
end
