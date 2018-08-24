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
