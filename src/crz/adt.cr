module CRZ
  macro adt(base, args)
    {% if base.class_name == "Path" %}
      {% base_class = base.names[0] %}
    {% else %}
      {% base_class = base.name.names[0] %}
    {% end %}

    # base class
    abstract class {{base}}

      {% if base.class_name == "Path" %}
        # non generic base
        {% for i in 0...args.size %}
          {% if args[i].class_name == "Path" %}
            # subclass with no members
            class {{args[i].names[0]}} < {{base}}
              def initialize
              end
            end
          {% else %}
            # subclass with members
            class {{args[i].name}} < {{base}}
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
                {{base.type_vars[0]}}
                {% for j in 1...base.type_vars.size %}
                  , {{base.type_vars[j]}}
                {% end %}
              ) < {{base}}
              def initialize
              end
            end
          {% else %} # intersection type
            class {{args[i].name}}(
                {{base.type_vars[0]}}
                {% for j in 1...base.type_vars.size %}
                  , {{base.type_vars[j]}}
                {% end %}
              ) < {{base}}
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

      macro match(val, cases)
        -> {
          %value = \{{val}}
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

                if %value.is_a? {{base_class}}::\{{lhs_class}}
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
            raise ArgumentError.new("Non exhaustive patterns passed to" + {{base_class.underscore.stringify}} + ".match")
          }
          %matcher_func.call()
        }.call
      end
    end
  end

  macro adt_class(base_type, args, cls_dec)
  {% if base_type.class_name == "Path" %}
    {% base_class = base_type.names[0] %}
  {% else %}
    {% base_class = base_type.name.names[0] %}
  {% end %}


  {{cls_dec}}

  abstract class {{base_type}} < ADT{{base_type}}

    {% if base_type.class_name == "Path" %}
      # non generic base
      {% for i in 0...args.size %}
        {% if args[i].class_name == "Path" %}
          class {{args[i].names[0]}} < {{base_type}}
            def initialize
            end
          end
        {% else %}
          class {{args[i].name}} < {{base_type}}
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
            ) < {{base_type}}
            def initialize
            end
          end
        {% else %} # intersection type
          class {{args[i].name}}(
              {{base_type.type_vars[0]}}
              {% for j in 1...base_type.type_vars.size %}
                , {{base_type.type_vars[j]}}
              {% end %}
            ) < {{base_type}}
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

    macro match(val, cases)
      -> {
        %value = \{{val}}
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

                if %value.is_a? {{base_class}}::\{{lhs_class}}
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
            raise ArgumentError.new("Non exhaustive patterns passed to" + {{base_class.underscore.stringify}} + ".match")
          }
          %matcher_func.call()
        }.call
      end
    end
  end
end
