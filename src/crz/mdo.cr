module CRZ::Monad::Macros
  macro mdo(body)
    {% if ["Assign", "TypeNode", "Splat", "Union", "UninitializedVar", "TypeDeclaration", 
      "Generic", "ClassDef", "Def", "VisibilityModifier", "MultiAssign"].includes? body[body.size - 1].class_name %}
      {{body[body.size-1].raise "Last line of an mdo expression should be an expression."}}
    {% end %}
    {{body[0].args[0]}}.bind do |{{body[0].receiver}}| # 0
    {% for i in 1...body.size - 1 %}
      {% if body[i].class_name == "Assign" %}
          {{body[i].target}} = {{body[i].value}}
      {% else %}
        {% if body[i].class_name == "Call" && body[i].name == "<=" %}
            {{body[i].args[0]}}.bind do |{{body[i].receiver}}| # {{i}}
        {% else %}
          {{body[i].raise "Only <= or = are allowed"}}
        {% end %}
      {% end %}
    {% end %}
        {{body[body.size - 1]}}

    # place end for all monad assignments in body
    {% for i in 1...body.size - 1 %} 
      {% if body[i].class_name == "Call" %}
        end
      {% end %}
    {% end %}
    end # end body[0].bind
  end
end