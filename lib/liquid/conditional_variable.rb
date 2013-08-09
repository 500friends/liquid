module Liquid

  # Holds a conditional variable, used for section substitution variables, only used in skeleton extraction
  class ConditionalVariable

    attr_accessor :condition, :negative_conditions, :value
    def initialize(condition, negative_conditions, value)
      self.condition = condition
      # negative_conditions is an array of conditions that needs to evaluate to false to hold true, used in cases of "else" in the if clauses
      self.negative_conditions = negative_conditions
      self.value = value
    end

    def render(context)
      if condition
        condition.evaluate(context) ? value : ''
      else
        negative_conditions.map{|x| x.evaluate(context)}.any? ? '' : value
      end
    end
  end
end
