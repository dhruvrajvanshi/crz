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
                    \{% variant = pattern[0] %}
                      {% if base_type.class_name == "Generic" %}
                        %value.is_a?({{base_class}}::\{{pattern[0]}}(\{{base.type_vars.splat}}))
                      {% else %}
                        %value.is_a?({{base_class}}::\{{pattern[0]}})
                      {% end %}
                        # bind pattern vars
                        \{% num_ifs = 0 %}
                        \{% for j in 1...pattern.size %}
                          \{% if pattern[j].class_name == "Var" %}
                            \{{pattern[j]}} = %value.value\{{j - 1}}
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
              \{% for lhs in cases.keys %}
                \{% if lhs.class_name == "Underscore" %}
                    return \{{cases[lhs]}}
                \{% else %}
                  \{% if lhs.class_name == "Path" %}
                    \{%
                      lhs_class = lhs.names[0]
                     %}
                  \{% else %}
                    \{% if lhs[0].class_name == "Underscore" %}
                      return \{{cases[lhs]}}
                    \{% else %}
                      \{%
                         lhs_class = lhs[0].names[0]
                       %}
                    \{% end %}
                  \{% end %}

                  if %value.is_a? {{base_class}}::\{{lhs_class}}
                    ## bind values
                    \{% if lhs.class_name != "Path" %}
                      \{% for i in 1...lhs.size %}
                        \{% if base.class_name == "Generic" %}
                          \{{lhs[i]}} = %value.as({{base_class}}::\{{lhs_class}}(\{{base.type_vars.splat}})).value\{{i-1}}
                        \{% else %}
                          \{{lhs[i]}} = %value.as({{base_class}}::\{{lhs_class}}).value\{{i-1}}
                        \{% end %}
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
