module CRZ

  macro adt(base_type, *args)
    {% if base_type.class_name == "Path" %}
      {%
        base_class = base_type.names[0]
        is_generic = false
        generics = [] of ArrayLiteral
      %}
    {% else %}
      {%
        base_class = base_type.name.names[0]
        is_generic = true
        generics = base_type.type_vars
      %}
    {% end %}

    # base class
    abstract class {{base_type}}
      {{ yield }}
      {% for i in 0...args.size %}
        {% if args[i].class_name == "Path" %}
          # case with no fields
          {%
            subclass_name = args[i].names[0]
            members = [] of ArrayLiteral
          %}
        {% else %}
          # case with fields
          {%
            subclass_name = args[i].name
            members = args[i].type_vars
          %}
        {% end %}
        {% if is_generic %}
          {% generic_param_list = "(#{generics.join(", ").id})".id %}
        {% else %}
          {% generic_param_list = "".id %}
        {% end %}
        class {{subclass_name}}{{generic_param_list}} < {{base_type}}
          {% for j in 0...members.size %}
          property value{{j}}
          {% end %}
          def initialize(
            {% for j in 0...members.size %}
            @value{{j}} : {{members[j]}},
            {% end %}
          )
          end

          def ==(other : Other) forall Other
            case other
            when {{subclass_name}}
              {% for arg_i in 0...members.size %}
              return false if @value{{arg_i}} != other.value{{arg_i}}
              {% end %}
              return true
            else
              false
            end
          end

          def clone : {{subclass_name}}{{generic_param_list}}
            {{subclass_name}}{{generic_param_list}}.new(
              {% for j in 0...members.size %}
              @value{{j}},
              {% end %}
            )
          end
        end
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
