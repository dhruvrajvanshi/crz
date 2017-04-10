module CRZ::Prelude
  def id(a : A) forall A
    a
  end

  def map(f : (A -> B), a : Functor(A)) : Functor(B) forall A, B
    a.map &f
  end
end
