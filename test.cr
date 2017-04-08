abstract class Option(T)
  def self._Some(value : A) forall A
    Some.new(value)
  end
  class Some(T) < Option(T)
    property value0
    def initialize(@value0 : T)
    end
  end
end

puts Option._Some(23)