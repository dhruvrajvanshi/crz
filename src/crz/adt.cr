module CRZ
  macro adt(base_type, *args)
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

      macro match(val, cases)
        \{% if cases.class_name != "HashLiteral" %}
          \{{cases.raise "SyntaxError: " + "Second argument to match " +
            "should be a HashLiteral containing patterns"
          }}
        \{% end %}
        -> {
          %matcher_func = -> {
            \{% literal_classes = ["NumberLiteral", "StringLiteral", "BoolLiteral", "NilLiteral", "CharLiteral", "SymbolLiteral"] %}
            %value = \{{val}}                      
            case %value
            {% for i in 0...args.size %}
              {% derived = args[i] %}
              {% if derived.class_name == "Path" %}
                {% derived_name = derived.names[0] %}
              {% else %}
                {% derived_name = derived.name %}
              {% end %}
                when {{base_class}}::{{derived_name}}
                  \{% for pattern in cases.keys %}
                    \{% expression = cases[pattern] %}
                    
                    \{% if pattern[0].class_name == "Path" %}
                      \{% if pattern[0].names[0].stringify == {{derived_name.stringify}} %}
                        \{% literals = pattern.select {|p| literal_classes.includes? p.class_name } %}
                        \{% for literal, j in pattern %}
                          \{% if literal_classes.includes? literal.class_name %}
                            if(%value.responds_to?(:value\{{j-1}}) && %value.value\{{j-1}} == \{{literal}})
                          \{% end %}
                        \{% end %}
                        \{% for j in 1...pattern.size %}
                          \{% if pattern[j].class_name == "Var" %}
                            \{{pattern[j]}} = %value.value\{{j - 1}}
                          \{% elsif pattern[j].class_name == "Call" %}
                            \{{pattern[j].id}} = %value.value\{{j - 1}}
                          \{% end %}
                        \{% end %}
                        return \{{expression}}
                        \{% for literal in literals%}
                          end
                        \{% end %}
                      \{% end %}
                    \{% elsif pattern[0].class_name == "Underscore" %}
                      return \{{expression}}
                    \{% else %}
                      \{{pattern[0].raise "Syntax error: " + pattern[0].class_name + " not allowed here."}}
                    \{% end %}
                  \{% end %}
                  raise "Non exhaustive patterns"
            {% end %}
            
            end
            raise "Non exhaustive patterns"
          }
          %matcher_func.call()
        }.call
      end
    end
  end

  macro adt_class(base_type, *args)
    {% cls_dec = args[args.size - 1] %}
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
        {% for i in 0...args.size - 1 %}
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
        \{% if cases.class_name != "HashLiteral" %}
          \{{cases.raise "SyntaxError: " + "Second argument to match " +
            "should be a HashLiteral containing patterns"
          }}
        \{% end %}
        -> {
          %matcher_func = -> {
            \{% literal_classes = ["NumberLiteral", "StringLiteral", "BoolLiteral", "NilLiteral", "CharLiteral", "SymbolLiteral"] %}
            %value = \{{val}}                      
            case %value
            {% for i in 0...args.size-1 %}
              {% derived = args[i] %}
              {% if derived.class_name == "Path" %}
                {% derived_name = derived.names[0] %}
              {% else %}
                {% derived_name = derived.name %}
              {% end %}
                when {{base_class}}::{{derived_name}}
                  \{% for pattern in cases.keys %}
                    \{% expression = cases[pattern] %}
                    
                    \{% if pattern[0].class_name == "Path" %}
                      \{% if pattern[0].names[0].stringify == {{derived_name.stringify}} %}
                        \{% literals = pattern.select {|p| literal_classes.includes? p.class_name } %}
                        \{% for literal, j in pattern %}
                          \{% if literal_classes.includes? literal.class_name %}
                            if(%value.responds_to?(:value\{{j-1}}) && %value.value\{{j-1}} == \{{literal}})
                          \{% end %}
                        \{% end %}
                        \{% for j in 1...pattern.size %}
                          \{% if pattern[j].class_name == "Var" %}
                            \{{pattern[j]}} = %value.value\{{j - 1}}
                          \{% elsif pattern[j].class_name == "Call" %}
                            \{{pattern[j].id}} = %value.value\{{j - 1}}
                          \{% end %}
                        \{% end %}
                        return \{{expression}}
                        \{% for literal in literals%}
                          end
                        \{% end %}
                      \{% end %}
                    \{% elsif pattern[0].class_name == "Underscore" %}
                      return \{{expression}}
                    \{% else %}
                      \{{pattern[0].raise "Syntax error: " + pattern[0].class_name + " not allowed here."}}
                    \{% end %}
                  \{% end %}
                  raise "Non exhaustive patterns"
            {% end %}
            
            end
            raise "Non exhaustive patterns"
          }
          %matcher_func.call()
        }.call
      end
    end
  end
end
