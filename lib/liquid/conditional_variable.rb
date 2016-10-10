module Liquid

  # Holds a conditional variable, used for section substitution variables, only used in skeleton extraction
  class ConditionalVariable

    attr_accessor :conditions, :negative_conditions, :value
    def initialize(positive, total, value)
      self.conditions = []
      self.negative_conditions = []
      self.value = value
      add_conditions(positive, total)
    end
    
    def add_positive_condition(c)
      self.conditions << c
    end

    def add_negative_conditions(cs)
      self.negative_conditions += cs
    end

    # pass in a single condition, which may be "else" type, and an array of all conditions in the same if/else block, which will be added to negative if the first condition is 'else'
    def add_conditions(positive, total)
      index = total.index(positive)
      add_negative_conditions(total[0..index-1]) if index != 0 # all conditions preceding the current positive condition needs to be negative
      if !positive.instance_of? ElseCondition
        add_positive_condition(positive)
      end
    end

    def render(context)
      if conditions.map{|x| x.evaluate(context)}.all? && !negative_conditions.map{|x| x.evaluate(context)}.any?
        value
      else
        ''
      end
    end
  end
end
