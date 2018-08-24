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
        {% elsif args[i].is_a?(ArrayLiteral) %}
          {%
            subclass_name = args[i].stringify.split('{')[0].strip.id
            members = args[i].map do |m|
              if m.is_a?(Path)
                m.id
              else
                m.type
              end
            end
          %}
        {% else %}
          # case with fields
          {%
            subclass_name = args[i].name
            members = args[i].type_vars
          %}
        {% end %}

        {%
          member_names = [] of String
        %}
        {% if args[i].is_a?(ArrayLiteral) %}
          {% for j in 0...args[i].size %}
            {% if args[i][j].is_a?(TypeDeclaration) %}
              # {{ member_names << args[i][j].var }}
            {% else %}
              # {{ member_names << "value#{j}".id }}
            {% end %}
          {% end %}
        {% else %}
          {% for j in 0...members.size %}
            # next line has to be commented because
            # << method returns the array causing it to
            # be included in the generated class. Commenting it
            # out is a simple hack to prevent it from happening
            # {{ member_names << "value#{j}".id }}
          {% end %}
        {% end %}
            
        {% if is_generic %}
          {% generic_param_list = "(#{generics.join(", ").id})".id %}
        {% else %}
          {% generic_param_list = "".id %}
        {% end %}

        class {{subclass_name}}{{generic_param_list}} < {{base_type}}
          {% for j in 0...members.size %}
          property {{member_names[j]}} : {{members[j]}}
          {% end %}
          def initialize(
            {% for j in 0...members.size %}
            {{"@#{member_names[j]}".id}} : {{members[j]}},
            {% end %}
          )
          end

          def ==(other : Other) forall Other
            case other
            when {{subclass_name}}
              {% for arg_i in 0...member_names.size %}
              return false if @{{member_names[arg_i]}} != other.{{member_names[arg_i]}}
              {% end %}
              return true
            else
              false
            end
          end

          def clone : {{subclass_name}}{{generic_param_list}}
            {{subclass_name}}{{generic_param_list}}.new(
              {{*member_names.map {|m| "@#{m}".id}}}
            )
          end

          def copy_with({{
            *member_names.map do |member|
              "#{member} = @#{member}".id
            end
          }}) : {{subclass_name}}{{generic_param_list}}
            {{subclass_name}}{{generic_param_list}}.new({{
              *member_names
            }})
          end
        end
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
              {% if derived.is_a?(Path) %}
                {% derived_name = derived.names[0] %}
              {% elsif derived.is_a?(ArrayLiteral) %}
                {% derived_name = derived[0].var %}
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
