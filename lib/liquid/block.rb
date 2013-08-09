module Liquid

  class Block < Tag
    IsTag             = /^#{TagStart}/o
    IsVariable        = /^#{VariableStart}/o
    FullToken         = /^#{TagStart}\s*(\w+)\s*(.*)?#{TagEnd}$/o
    ContentOfVariable = /^#{VariableStart}(.*)#{VariableEnd}$/o

    def parse(tokens)
      @nodelist ||= []
      @nodelist.clear

      while token = tokens.shift

        case token
        when IsTag
          if token =~ FullToken

            # if we found the proper block delimitor just end parsing here and let the outer block
            # proceed
            if block_delimiter == $1
              end_tag
              return
            end

            # fetch the tag from registered blocks
            if tag = Template.tags[$1]
              @nodelist << tag.new($1, $2, tokens)
            else
              # this tag is not registered with the system
              # pass it to the current block for special handling or error reporting
              unknown_tag($1, $2, tokens)
            end
          else
            raise SyntaxError, "Tag '#{token}' was not properly terminated with regexp: #{TagEnd.inspect} "
          end
        when IsVariable
          @nodelist << create_variable(token)
        when ''
          # pass
        else
          @nodelist << token
        end
      end

      # Make sure that its ok to end parsing in the current block.
      # Effectively this method will throw and exception unless the current block is
      # of type Document
      assert_missing_delimitation!
    end

    def end_tag
    end

    def unknown_tag(tag, params, tokens)
      case tag
      when 'else'
        raise SyntaxError, "#{block_name} tag does not expect else tag"
      when 'end'
        raise SyntaxError, "'end' is not a valid delimiter for #{block_name} tags. use #{block_delimiter}"
      else
        raise SyntaxError, "Unknown tag '#{tag}'"
      end
    end

    def block_delimiter
      "end#{block_name}"
    end

    def block_name
      @tag_name
    end

    def key
      @key ||= Utils.uuid
    end

    def create_variable(token)
      token.scan(ContentOfVariable) do |content|
        return Variable.new(content.first)
      end
      raise SyntaxError.new("Variable '#{token}' was not properly terminated with regexp: #{VariableEnd.inspect} ")
    end

    def render(context)
      render_all(@nodelist, context)
    end

    def render_skeleton(context)
      render_all_skeleton(@nodelist, context)
    end

    protected

    def assert_missing_delimitation!
      raise SyntaxError.new("#{block_name} tag was never closed")
    end

    def render_all(list, context)
      output = []
      list.each do |token|
        # Break out if we have any unhanded interrupts.
        break if context.has_interrupt?

        begin
          # If we get an Interrupt that means the block must stop processing. An
          # Interrupt is any command that stops block execution such as {% break %} 
          # or {% continue %}
          if token.is_a? Continue or token.is_a? Break
            context.push_interrupt(token.interrupt)
            break
          end

          output << (token.respond_to?(:render) ? token.render(context) : token)
        rescue ::StandardError => e
          output << (context.handle_error(e))
        end
      end

      output.join
    end

    # see template.rb for more detail
    # returns an array of rendered skeleton text, an array of variables to be evaluated later (including value for segments), and a hash for segments
    def render_all_skeleton(list, context)
      output, variables, sections = [], {}, {}
      list.each do |token|
        begin
          if token.respond_to?(:render)
            if token.instance_of?(Variable)
              if token.name =~ context.separate_variable_regex
                variables[token.key] ||= token
                output << token.key
              else
                output << token.render(context).to_s # for the variables that we don't need to separate, simply render it into plain text template
              end
            else
              # recursively render subblock in similar fashions, preserving the substitutions and sections
              string_outputs, var_output, section_output = token.render_skeleton(context)
              output += string_outputs
              sections.merge!(section_output)
              variables.merge!(var_output)
            end
          else
            output << token
          end
        rescue ::StandardError => e
          output << (context.handle_error(e))
        end
      end

      [output, variables, sections]
    end

  end
end
