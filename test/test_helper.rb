#!/usr/bin/env ruby

require 'test/unit'
require 'test/unit/assertions'
begin
  require 'ruby-debug'
rescue LoadError
  puts "Couldn't load ruby-debug. gem install ruby-debug if you need it."
end
require File.join(File.dirname(__FILE__), '..', 'lib', 'liquid')


module Test
  module Unit
    module Assertions
      include Liquid

      def assert_template_result(expected, template, assigns = {}, message = nil)
        assert_equal expected, Template.parse(template).render(assigns)
      end

      def assert_template_result_matches(expected, template, assigns = {}, message = nil)
        return assert_template_result(expected, template, assigns, message) unless expected.is_a? Regexp

        assert_match expected, Template.parse(template).render(assigns)
      end

      # parse the template skeleton, render the variables, and reconstruct the end message with substitutions and variables
      def assert_skeleton_rendered_result(expected, template, static_assigns = {}, variable_assigns = {}, separate_variable_regex = nil)
        variable_assigns = variable_assigns.merge(static_assigns)
        # extract skeleton
        t = Template.parse(template)
        t.separate_variable_regex = separate_variable_regex if separate_variable_regex
        text, vars, sections = t.render_skeleton(static_assigns)
        # render variable values
        var_array_hash = {}
        variable_assigns.each do |key, value|
          var_array_hash[key] = [value]
        end
        rendered_vars = t.render_variables(vars, static_assigns, var_array_hash)
        results = Template.render_strings(text, rendered_vars, sections)
        assert_equal expected, results.first
      end

    end # Assertions
  end # Unit
end # Test
