module CRZ::Monad::Macros
  macro lift_apply(f, *args)
    {% for i in 0...args.size %}
      {{args[i]}}.bind { |arg{{i}}|
    {% end %}

    typeof({{args[0]}}).of(
      {{f.id}}(
        {% for i in 0...args.size - 1 %}
          arg{{i}},
        {% end %}
        arg{{args.size - 1}}
      )
    )

    {% for i in 0...args.size %}
      }
    {% end %}
  end
end
