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
    def render_skeleton(context)
      output, variables, sections = [], {}, {}
      context.stack do
        @blocks.each do |block|
          string_output, var_output, section_output = render_all_skeleton(block.attachment, context)
          if section_output && section_output.length != 0
            # this means there is nested conditional in the string_output array
            # we need to process through all of them to create intermediate segments
            # for example, output could be ['textA', 'textB', 'sectionA', 'sectionB', 'textC']
            # we will need to create two new sections, one to represent 'textAtextB', one to represent 'textC'
            string_so_far = ''
            current_segment = string_output.shift
            while current_segment
              next_segment = string_output.shift
              if current_segment.instance_of?(ConditionalSection) || !next_segment
                string_so_far += current_segment if !next_segment # we are at the end, add current segment
                # we either encountered a conditioanl section or the end, which means we have to package the string we got so far into a new section
                if string_so_far != ''
                  variable_key = Utils.uuid
                  section_value_key = Utils.uuid
                  sections[section_value_key] = string_so_far
                  variables[variable_key] = ConditionalVariable.new(block, @blocks, section_value_key)
                  output << ConditionalSection.new(variable_key)
                  # reset the string so far
                  string_so_far = ''
                end
              end
              if current_segment.instance_of?(ConditionalSection)
                # now we have to add the block condition into the conditional variables
                var_output[current_segment].add_conditions(block, @blocks)
                output << current_segment
              else
                string_so_far += current_segment
              end
              current_segment = next_segment
            end
            sections.merge!(section_output)
            variables.merge!(var_output)
          else
            # there is no nested conditionals involved here, base case scenario in the recursion
            output << ConditionalSection.new(block.key)
            sections[block.value_key] = string_output.join
            variables.merge!(var_output)
            variables[block.key] = ConditionalVariable.new(block, @blocks, block.value_key)
          end
        end
      end
      [output, variables, sections]
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
