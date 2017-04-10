module CRZ::Prelude
  macro chain(arg, *funcs)
    {% for func, index in funcs %}
      {% i = funcs.size - index - 1%}
      {{funcs[i]}}(
    {% end %}
    {{arg}}
    {% for func in funcs %}
      )
    {% end %}
  end
end