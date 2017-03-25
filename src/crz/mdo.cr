module CRZ
  macro mdo(body)
    {% if ["Assign", "TypeNode", "Splat", "Union", "UninitializedVar", "TypeDeclaration", 
      "Generic", "ClassDef", "Def", "VisibilityModifier", "MultiAssign"].includes? body[body.size - 1].class_name %}
      {{body[0].raise "Last line of an mdo expression should be an expression."}}
    {% end %}

    {{body[0].args[0]}}.bind do |{{body[0].receiver}}|
    {% for i in 1...body.size - 1 %}
      {% if body[i].class_name == "Assign" %}
        {{body[0].args[0]}}.bind do |__mdo_generated_{{i}}|
          {{body[i].target}} = {{body[i].value}}
      {% else %}
        {% if body[i].class_name == "Call" && body[i].name == "<=" %}
            {{body[i].args[0]}}.bind do |{{body[i].receiver}}|
        {% else %}
          {{body[i].raise "Only <= or = are allowed"}}
        {% end %}
      {% end %}
    {% end %}
        {{body[body.size - 1]}}
    {% for i in 0...body.size - 2 %}
      end
    {% end %}
    end
  end
end