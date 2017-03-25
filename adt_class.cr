macro adt_module(base_type, args, cls_dec)
  {% if base_type.class_name == "Path" %}
    {% base_class = base_type.names[0] %}
  {% else %}
    {% base_class = base_type.name.names[0] %}
  {% end %}
  macro match_{{base_class.underscore}}(val, cases)
    %value = \{{val}}
    -> {
      %matcher_func = -> {
        \{% for lhs in cases.keys %}
          \{% if lhs.class_name == "Underscore" %}
              return \{{cases[lhs]}}
          \{% else %}
            \{% if lhs.class_name == "Path" %}
              \{%
                lhs_class = lhs.names[0]
               %}
            \{% else %}
              \{%
                 lhs_class = lhs[0].names[0]
               %}
            \{% end %}

            if \{{val}}.is_a? {{base_class}}::\{{lhs_class}}
              ## bind values
              \{% if lhs.class_name != "Path" %}
                \{% for i in 1...lhs.size %}
                  \{{lhs[i]}} = %value.as({{base_class}}::\{{lhs_class}}).value\{{i-1}}
                \{% end %}
              \{% end %}
              return \{{cases[lhs]}}
            end
          \{% end %}
        \{% end %}
        raise ArgumentError.new("Non exhaustive patterns passed to match_" + {{base_class.underscore.stringify}})
      }
      %matcher_func.call()
    }.call
  end

  {{cls_dec.id}}

  module {{base_type}}
    {% if base_type.class_name == "Path" %}
      # non generic base
      {% for i in 0...args.size %}
        {% if args[i].class_name == "Path" %}
          class {{args[i].names[0]}}
              include {{base_type}}
            def initialize
            end
          end
        {% else %}
          class {{args[i].name}}
              include {{base_type}}
            {% for j in 0...args[i].type_vars.size %}
              property value{{j}}
            {% end %}
            def initialize(
              {% for j in 0...args[i].type_vars.size - 1 %}
                @value{{j}} : {{args[i].type_vars[j]}},
              {% end %}
              @value{{args[i].type_vars.size - 1}} : {{args[i].type_vars[args[i].type_vars.size - 1]}}
            )
            end
          end
        {% end %}
      {% end %}
    {% else %}
      # generic base
      {% for i in 0...args.size %}
        {% if args[i].class_name == "Path" %} # constructor with no value types
          class {{args[i].names[0]}}(
              {{base_type.type_vars[0]}}
              {% for j in 1...base_type.type_vars.size %}
                , {{base_type.type_vars[j]}}
              {% end %}
            )
            include {{base_type}}
            def initialize
            end
          end
        {% else %} # intersection type
          class {{args[i].name}}(
              {{base_type.type_vars[0]}}
              {% for j in 1...base_type.type_vars.size %}
                , {{base_type.type_vars[j]}}
              {% end %}
            )
            include {{base_type}}
            {% for j in 0...args[i].type_vars.size %}
              property value{{j}}
            {% end %}
            def initialize(
              {% for j in 0...args[i].type_vars.size - 1 %}
                @value{{j}} : {{args[i].type_vars[j]}},
              {% end %}
              @value{{args[i].type_vars.size - 1}} : {{args[i].type_vars[args[i].type_vars.size - 1]}}
            )
            end
          end
        {% end %}
      {% end %}
    {% end %}
  end
end
