module Liquid

  # If is the conditional block
  #
  #   {% if user.admin %}
  #     Admin user!
  #   {% else %}
  #     Not admin user
  #   {% endif %}
  #
  #    There are {% if count < 5 %} less {% else %} more {% endif %} items than you need.
  #
  #
  class If < Block
    SyntaxHelp = "Syntax Error in tag 'if' - Valid syntax: if [expression]"
    Syntax = /(#{QuotedFragment})\s*([=!<>a-z_]+)?\s*(#{QuotedFragment})?/o
    ExpressionsAndOperators = /(?:\b(?:\s?and\s?|\s?or\s?)\b|(?:\s*(?!\b(?:\s?and\s?|\s?or\s?)\b)(?:#{QuotedFragment}|\S+)\s*)+)/o

    def initialize(tag_name, markup, tokens)
      @blocks = []

      push_block('if', markup)

      super
    end

    def unknown_tag(tag, markup, tokens)
      if ['elsif', 'else'].include?(tag)
        push_block(tag, markup)
      else
        super
      end
    end

    def render(context)
      context.stack do
        @blocks.each do |block|
          if block.evaluate(context)
            return render_all(block.attachment, context)
          end
        end
        ''
      end
    end

    # Same as render above, except variables and sections are preserved in hash. See block.rb for more detail
    # Nesting is tricky because section nesting is not supported in sendgrid. So if we have code:
    # if 
    #   A
    #   if
    #     B
    #   else
    #     C
    #   endif
    #   D
    # else
    #   E
    # endif
    # If nesting section is supported, you can have one key to represent this whole section, and inside the value of the section you can reference another section for the inner conditional.
    # Unfortunately, we have to create string results like this:
    #   sec1 sec2 sec3 sec4 sec5
    # where if the output is ABD
    #   sec1=A sec2=B sec3='' sec4=D sec5=''
    # and if the output is E
    #   sec1='' sec2='' sec3='' sec4='' sec5=E
    # This means we have to walk down each path of the conditional recursively, even when the condition is not satisfied. Messy stuff.
    def render_without_substitution(context)
      context.stack do
        @blocks.each do |block|
          if block.evaluate(context)
            string_output, sub_output, section_output = render_all_without_substitution(block.attachment, context)
            condition_key = block.key # unique key for the condition that evaluates to true
            block_section_key = self.key # unique key for the whole if else block, not just the condition
            section_output[condition_key] = string_output
            sub_output[block_section_key] = condition_key
            return [block_section_key, sub_output, section_output]
          end
        end
        ['', {}, {}]
      end
    end

    private

      def push_block(tag, markup)
        block = if tag == 'else'
          ElseCondition.new
        else

          expressions = markup.scan(ExpressionsAndOperators).reverse
          raise(SyntaxError, SyntaxHelp) unless expressions.shift =~ Syntax

          condition = Condition.new($1, $2, $3)

          while not expressions.empty?
            operator = (expressions.shift).to_s.strip

            raise(SyntaxError, SyntaxHelp) unless expressions.shift.to_s =~ Syntax

            new_condition = Condition.new($1, $2, $3)
            new_condition.send(operator.to_sym, condition)
            condition = new_condition
          end

          condition
        end

        @blocks.push(block)
        @nodelist = block.attach(Array.new)
      end


  end

  Template.register_tag('if', If)
end
