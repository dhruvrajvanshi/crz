module CRZ
  macro adt(base_type, args)
    {% if base_type.class_name == "Path" %}
      {% base_class = base_type.names[0] %}
    {% else %}
      {% base_class = base_type.name.names[0] %}
    {% end %}

    # base class
    abstract class {{base_type}}

      {% if base_type.class_name == "Path" %}
        # non generic base
        {% for i in 0...args.size %}
          {% if args[i].class_name == "Path" %}
            # subclass with no members
            class {{args[i].names[0]}} < {{base_type}}
              def initialize
              end
            end
          {% else %}
            # subclass with members
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

      macro match(val, base, cases)
        -> {
          %value = \{{val}}
          %matcher_func = -> {
            \{% literal_classes = ["NumberLiteral", "StringLiteral", "BoolLiteral", "NilLiteral", "CharLiteral", "SymbolLiteral"] %}
            \{% for pattern, i in cases.keys %}
              \{% if pattern.class_name == "ArrayLiteral" %}
                if
                  \{% if pattern[0].class_name == "Underscore"%}
                    (true) # wildcard pattern; always match
                    return \{{cases[pattern]}}
                  \{% else %}
                      {% if base_type.class_name == "Generic" %}
                        %value.is_a?({{base_class}}::\{{pattern[0]}}(\{{base.type_vars.splat}}))
                      {% else %}
                        %value.is_a?({{base_class}}::\{{pattern[0]}})
                      {% end %}
                        # bind pattern vars
                        \{% for j in 1...pattern.size %}
                          \{% if pattern[j].class_name == "Var" %}
                            {% if base_type.class_name == "Generic" %}
                              \{{pattern[j]}} = %value.as({{base_class}}::\{{pattern[0]}}(\{{base.type_vars.splat}})).value\{{j - 1}}
                            {% else %}
                              \{{pattern[j]}} = %value.as({{base_class}}::\{{pattern[0]}}).value\{{j - 1}}
                            {% end %}
                          \{% elsif pattern[j].class_name == "Call" %}
                            {% if base_type.class_name == "Generic" %}
                              \{{pattern[j].id}} = %value.as({{base_class}}::\{{pattern[0]}}(\{{base.type_vars.splat}})).value\{{j - 1}}
                            {% else %}
                              \{{pattern[j].id}} = %value.as({{base_class}}::\{{pattern[0]}}).value\{{j - 1}}
                            {% end %}
                          \{% end %}
                        \{% end %}
                        \{% literals = pattern.select {|p| literal_classes.includes? p.class_name } %}
                        \{% for literal, j in pattern %}
                          \{% if literal_classes.includes? literal.class_name %}
                            if(%value.value\{{j-1}} == \{{literal}})
                          \{% end %}
                        \{% end %}
                        return \{{cases[pattern]}}
                        \{% for literal in literals%}
                          end
                        \{% end %}
                  \{% end %}
                end # end of pattern branch
              \{% else %}
                \{% pattern.raise "Pattern should be an Array." %}
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

      macro match(val, base, cases)
        -> {
          %value = \{{val}}
          %matcher_func = -> {
            \{% literal_classes = ["NumberLiteral", "StringLiteral", "BoolLiteral", "NilLiteral", "CharLiteral", "SymbolLiteral"] %}
            \{% for pattern, i in cases.keys %}
              \{% if pattern.class_name == "ArrayLiteral" %}
                if
                  \{% if pattern[0].class_name == "Underscore"%}
                    (true) # wildcard pattern; always match
                    return \{{cases[pattern]}}
                  \{% else %}
                      {% if base_type.class_name == "Generic" %}
                        %value.is_a?({{base_class}}::\{{pattern[0]}}(\{{base.type_vars.splat}}))
                      {% else %}
                        %value.is_a?({{base_class}}::\{{pattern[0]}})
                      {% end %}
                        # bind pattern vars
                        \{% for j in 1...pattern.size %}
                          \{% if pattern[j].class_name == "Var" %}
                            {% if base_type.class_name == "Generic" %}
                              \{{pattern[j]}} = %value.as({{base_class}}::\{{pattern[0]}}(\{{base.type_vars.splat}})).value\{{j - 1}}
                            {% else %}
                              \{{pattern[j]}} = %value.as({{base_class}}::\{{pattern[0]}}).value\{{j - 1}}
                            {% end %}
                          \{% elsif pattern[j].class_name == "Call" %}
                            {% if base_type.class_name == "Generic" %}
                              \{{pattern[j].id}} = %value.as({{base_class}}::\{{pattern[0]}}(\{{base.type_vars.splat}})).value\{{j - 1}}
                            {% else %}
                              \{{pattern[j].id}} = %value.as({{base_class}}::\{{pattern[0]}}).value\{{j - 1}}
                            {% end %}
                          \{% end %}
                        \{% end %}
                        \{% literals = pattern.select {|p| literal_classes.includes? p.class_name } %}
                        \{% for literal, j in pattern %}
                          \{% if literal_classes.includes? literal.class_name %}
                            if(%value.value\{{j-1}} == \{{literal}})
                          \{% end %}
                        \{% end %}
                        return \{{cases[pattern]}}
                        \{% for literal in literals%}
                          end
                        \{% end %}
                  \{% end %}
                end # end of pattern branch
              \{% else %}
                \{% pattern.raise "Pattern should be an Array." %}
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
