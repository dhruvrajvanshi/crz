module CRZ
  macro ap(call)
    {% if call.class_name != "Call" %}
      {{call.raise "First argument to ap must be a function name"}}
    {% end %}
    {% for i in 0..call.args.size - 1 %}
      {{call.args[i]}}.bind { |arg{{i}}|
    {% end %}

    typeof({{call.args[0]}}).pure(
      {{call.name}}(
        {% for i in 0..call.args.size - 2 %}
          arg{{i}},
        {% end %}
        arg{{call.args.size - 1}}
      )
    )

    {% for i in 0...call.args.size %}
      }
    {% end %}
  end
end
