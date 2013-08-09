module Liquid

  # Templates are central to liquid.
  # Interpretating templates is a two step process. First you compile the
  # source code you got. During compile time some extensive error checking is performed.
  # your code should expect to get some SyntaxErrors.
  #
  # After you have a compiled template you can then <tt>render</tt> it.
  # You can use a compiled template over and over again and keep it cached.
  #
  # Example:
  #
  #   template = Liquid::Template.parse(source)
  #   template.render('user_name' => 'bob')
  #
  class Template
    attr_accessor :root
    @@file_system = BlankFileSystem.new

    class << self
      def file_system
        @@file_system
      end

      def file_system=(obj)
        @@file_system = obj
      end

      def register_tag(name, klass)
        tags[name.to_s] = klass
      end

      def tags
        @tags ||= {}
      end

      # Pass a module with filter methods which should be available
      # to all liquid views. Good for registering the standard library
      def register_filter(mod)
        Strainer.global_filter(mod)
      end

      # creates a new <tt>Template</tt> object from liquid source code
      def parse(source)
        template = Template.new
        template.parse(source)
        template
      end
    end

    attr_accessor :separate_variable_regex

    # creates a new <tt>Template</tt> from an array of tokens. Use <tt>Template.parse</tt> instead
    def initialize
    end

    # Parse source code.
    # Returns self for easy chaining
    def parse(source)
      @root = Document.new(tokenize(source))
      self
    end

    def registers
      @registers ||= {}
    end

    def assigns
      @assigns ||= {}
    end

    def instance_assigns
      @instance_assigns ||= {}
    end

    def errors
      @errors ||= []
    end

    # Render takes a hash with local variables.
    #
    # if you use the same filters over and over again consider registering them globally
    # with <tt>Template.register_filter</tt>
    #
    # Following options can be passed:
    #
    #  * <tt>filters</tt> : array with local filters
    #  * <tt>registers</tt> : hash with register variables. Those can be accessed from
    #    filters and tags and might be useful to integrate liquid more with its host application
    #
    def render(*args)
      return '' if @root.nil?
      
      context = extract_context(*args)
      
      begin
        # render the nodelist.
        # for performance reasons we get a array back here. join will make a string out of it
        result = @root.render(context)
        result.respond_to?(:join) ? result.join : result
      ensure
        @errors = context.errors
      end
    end


    def extract_context(*args)
      context = case args.first
      when Liquid::Context
        args.shift
      when Hash
        Context.new([args.shift, assigns], instance_assigns, registers, @rethrow_errors)
      when nil
        Context.new(assigns, instance_assigns, registers, @rethrow_errors)
      else
        raise ArgumentError, "Expect Hash or Liquid::Context as parameter"
      end

      case args.last
      when Hash
        options = args.pop

        if options[:registers].is_a?(Hash)
          self.registers.merge!(options[:registers])
        end

        if options[:filters]
          context.add_filters(options[:filters])
        end

      when Module
        context.add_filters(args.pop)
      when Array
        context.add_filters(args.pop)
      end
      context
    end

    # We are doing this to fully take advantage of features from email providers such as sendgrid
    # It only applies when you are trying to send massive amounts of emails in a batch
    # http://sendgrid.com/docs/API_Reference/SMTP_API/substitution_tags.html
    # http://sendgrid.com/docs/API_Reference/SMTP_API/section_tags.html
    # Note: that not all variables are seperated in hash, only variables that will differ in mass emailing should be.
    # For example the "account" variable will remain the same for all the users of the account. As a result, they should be part of the text template instead of substitution hash.
    # To list a variable to be seperated_varaible, use template.set_separate_variable_regex to set a regex that will be used to match variables. In the case above, "user" should be added to regex
    
    # returns a rendered skeleton text, an hash of variables to be evaluated later (including value for segments), and a hash for segments
    # This only need to happen once for each template, after that each variable that should be hashed can go through the second function for extraction. 
    # This function should pass in a hash of variables that should not be separated in hash, variables such as hash
    def render_skeleton(*args)
      context = extract_context(*args)
      if @separate_variable_regex
        context.separate_variable_regex = @separate_variable_regex
      end

      begin
        @root.render_skeleton(context)
      ensure
        @errors = context.errors
      end
    end

    # After render_skeleton, you can use this method to evaluate the variables extracted.
    # pass in three hashes
    #   variable hash is a hash of key to the Liquid::Variable or Liquid::ConditionalVariable object to be evaluated
    #   static_variable_hash is a hash of variables that stay the same, like {'account' => Account.first}
    #   array_variable_hash is a hash of variable name to array of instances, like {'customer' => Customer.all, 'customer_detail' => CustomerDetail.all}. All arrays are assumed to be of the same length.
    # Each entry in the array_variable_hash's array is added to static variable before evaluating the variables.
    # Output is an hash of variable name to an array of values, for example:
    #     {
    #       'customer_name' => ['Hong', 'Tina'],
    #       'customer_hobby' => ['arbitrary', 'random']
    #     }
    def render_variables(variable_hash, static_variable_hash, array_variable_hash)
      context = Context.new([static_variable_hash, assigns], instance_assigns, registers, @rethrow_errors)
      output_count = array_variable_hash.first[1].length
      result_hash = {}
      variable_hash.each do |key, variable_object|
        values = []
        output_count.times do |i|
          context.stack do
            array_variable_hash.each{|k,v| context[k] = v[i]}
            values << variable_object.render(context).to_s
          end
        end
        result_hash[key] = values
      end
      result_hash
    end

    def render!(*args)
      @rethrow_errors = true; render(*args)
    end

    private

    # Uses the <tt>Liquid::TemplateParser</tt> regexp to tokenize the passed source
    def tokenize(source)
      source = source.source if source.respond_to?(:source)
      return [] if source.to_s.empty?
      tokens = source.split(TemplateParser)

      # removes the rogue empty element at the beginning of the array
      tokens.shift if tokens[0] and tokens[0].empty?

      tokens
    end

  end
end
