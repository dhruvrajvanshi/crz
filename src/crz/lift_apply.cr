module CRZ
  macro lift_apply(args)
    {% for i in 1...args.size %}
      {{args[i]}}.bind { |arg{{i - 1}}|
    {% end %}

    typeof({{args[1]}}).pure(
      {{args[0].id}}(
        {% for i in 1...args.size - 1 %}
          arg{{i - 1}},
        {% end %}
        arg{{args.size - 2}}
      )
    )

    {% for i in 1...args.size %}
      }
    {% end %}
  end
end
