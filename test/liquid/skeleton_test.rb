require 'test_helper'

# test the skeleton, including tags such as ifs
class SkeletonTest < Test::Unit::TestCase
  include Liquid

  # test the string rendering method from skeleton
  # skeleton in mind is:
  # A
  # {% if a > 0 %}
  #   B
  #   {% if b > 0 %}
  #     C
  #   {% else %}
  #     D
  #   {% endif %}
  # {% else %}
  #   E{{ c }}
  # {% endif %}
  # {{ c }}
  # F
  # Three rendered string should be:
  # ABC1F
  # ABD2F
  # AE33F
  def test_render_strings
    text = "A-v1--v2--v3--v4--v5-F"
    sections = {
      "s1" => "B",
      "s2" => "C",
      "s3" => "D",
      "s4" => "E-v5-"
    }
    vars = {
      "-v1-" => ["s1", "s1", ""],
      "-v2-" => ["s2", "", ""],
      "-v3-" => ["", "s3", ""],
      "-v4-" => ["", "", "s4"],
      "-v5-" => ["1", "2", "3"]
    }
    t = Template.new
    results = Template.render_strings(text, vars, sections)
    assert_equal results[0], "ABC1F"
    assert_equal results[1], "ABD2F"
    assert_equal results[2], "AE33F"
  end

  def test_render_skeleton_basic
    assert_skeleton_rendered_result "A1", "A{{a}}", {"a" => 1}
    assert_skeleton_rendered_result "A1", "A{{a}}", {}, {"a" => 1}, /a/
    assert_skeleton_rendered_result "A3", "A{{a | plus: 2}}", {}, {"a" => 1}, /a/
    assert_skeleton_rendered_result "A2", "A{{3 | minus: a}}", {}, {"a" => 1}, /a/
    assert_skeleton_rendered_result "A12", "A{{a}}{{b}}", {"b" => 2}, {"a" => 1}, /a/
  end

  def test_render_skeleton_basic_with_substitution_regex
    assert_skeleton_rendered_result "A", "A{{a}}", {}, {"a" => 1}
    assert_skeleton_rendered_result "A2", "A{{a}}{{b}}", {"b" => 2}, {"a" => 1}
  end

  def test_render_skeleton_conditionals
    assert_skeleton_rendered_result "ABD", "A{% if a1 > 0 %}B{% else %}C{% endif %}D", {"a1" => 1}
    assert_skeleton_rendered_result "ACD", "A{% if a1 > 0 %}B{% else %}C{% endif %}D", {"a1" => -1}
    assert_skeleton_rendered_result "ACE", "A{% if a1 > 0 %}B{% elsif a1 < -1 %}C{% else %}D{% endif %}E", {"a1" => -2}
    assert_skeleton_rendered_result "ADE", "A{% if a1 > 0 %}B{% elsif a1 < -1 %}C{% else %}D{% endif %}E", {"a1" => -1}
    assert_skeleton_rendered_result "ABD", "A{% if a1 > 0 %}B{% else %}C{% endif %}D", {}, {"a1" => 1}, /a/
    assert_skeleton_rendered_result "ACD", "A{% if a1 > 0 %}B{% else %}C{% endif %}D", {}, {"a1" => -1}, /a/
    assert_skeleton_rendered_result "ACE", "A{% if a1 > 0 %}B{% elsif a1 < -1 %}C{% else %}D{% endif %}E", {}, {"a1" => -2}, /a/
    assert_skeleton_rendered_result "ADE", "A{% if a1 > 0 %}B{% elsif a1 < -1 %}C{% else %}D{% endif %}E", {}, {"a1" => -1}, /a/
    assert_skeleton_rendered_result "AB2D", "A{% if a1 > 0 %}B{{a2}}{% else %}C{% endif %}D", {}, {"a1" => 1, "a2" => 2}, /a/
  end

  def test_render_skeleton_nested_conditionals
    assert_skeleton_rendered_result "ABCFI", "A{% if a1 > 0 %}B{% if a1 > 5 %}C{% elsif a1 > 1 %}D{% else %}E{% endif %}F{% elsif a1 < -1 %}G{% else %}H{% endif %}I", {"a1" => 6}
    assert_skeleton_rendered_result "ABDFI", "A{% if a1 > 0 %}B{% if a1 > 5 %}C{% elsif a1 > 1 %}D{% else %}E{% endif %}F{% elsif a1 < -1 %}G{% else %}H{% endif %}I", {"a1" => 4}
    assert_skeleton_rendered_result "ABEFI", "A{% if a1 > 0 %}B{% if a1 > 5 %}C{% elsif a1 > 1 %}D{% else %}E{% endif %}F{% elsif a1 < -1 %}G{% else %}H{% endif %}I", {"a1" => 0.5}
    assert_skeleton_rendered_result "AGI", "A{% if a1 > 0 %}B{% if a1 > 5 %}C{% elsif a1 > 1 %}D{% else %}E{% endif %}F{% elsif a1 < -1 %}G{% else %}H{% endif %}I", {"a1" => -2}
    assert_skeleton_rendered_result "AHI", "A{% if a1 > 0 %}B{% if a1 > 5 %}C{% elsif a1 > 1 %}D{% else %}E{% endif %}F{% elsif a1 < -1 %}G{% else %}H{% endif %}I", {"a1" => -0.5}

    assert_skeleton_rendered_result "ABCFI", "A{% if a1 > 0 %}B{% if a1 > 5 %}C{% elsif a1 > 1 %}D{% else %}E{% endif %}F{% elsif a1 < -1 %}G{% else %}H{% endif %}I", {}, {"a1" => 6}, /a/
    assert_skeleton_rendered_result "ABDFI", "A{% if a1 > 0 %}B{% if a1 > 5 %}C{% elsif a1 > 1 %}D{% else %}E{% endif %}F{% elsif a1 < -1 %}G{% else %}H{% endif %}I", {}, {"a1" => 4}, /a/
    assert_skeleton_rendered_result "ABEFI", "A{% if a1 > 0 %}B{% if a1 > 5 %}C{% elsif a1 > 1 %}D{% else %}E{% endif %}F{% elsif a1 < -1 %}G{% else %}H{% endif %}I", {}, {"a1" => 0.5}, /a/
    assert_skeleton_rendered_result "AGI", "A{% if a1 > 0 %}B{% if a1 > 5 %}C{% elsif a1 > 1 %}D{% else %}E{% endif %}F{% elsif a1 < -1 %}G{% else %}H{% endif %}I", {}, {"a1" => -2}, /a/
    assert_skeleton_rendered_result "AHI", "A{% if a1 > 0 %}B{% if a1 > 5 %}C{% elsif a1 > 1 %}D{% else %}E{% endif %}F{% elsif a1 < -1 %}G{% else %}H{% endif %}I", {}, {"a1" => -0.5}, /a/
  end

  def test_render_skeleton_nested_conditionals_with_variables
    assert_skeleton_rendered_result "AB6C6F6I", "A{% if a1 > 0 %}B{{a1}}{% if a1 > 5 %}C{{a1}}{% elsif a1 > 1 %}D{{a1}}{% else %}E{{a1}}{% endif %}F{{a1}}{% elsif a1 < -1 %}G{{a1}}{% else %}H{{a1}}{% endif %}I", {"a1" => 6}
    assert_skeleton_rendered_result "AB4D4F4I", "A{% if a1 > 0 %}B{{a1}}{% if a1 > 5 %}C{{a1}}{% elsif a1 > 1 %}D{{a1}}{% else %}E{{a1}}{% endif %}F{{a1}}{% elsif a1 < -1 %}G{{a1}}{% else %}H{{a1}}{% endif %}I", {"a1" => 4}
    assert_skeleton_rendered_result "AB0.5E0.5F0.5I", "A{% if a1 > 0 %}B{{a1}}{% if a1 > 5 %}C{{a1}}{% elsif a1 > 1 %}D{{a1}}{% else %}E{{a1}}{% endif %}F{{a1}}{% elsif a1 < -1 %}G{{a1}}{% else %}H{{a1}}{% endif %}I", {"a1" => 0.5}
    assert_skeleton_rendered_result "AG-2I", "A{% if a1 > 0 %}B{{a1}}{% if a1 > 5 %}C{{a1}}{% elsif a1 > 1 %}D{{a1}}{% else %}E{{a1}}{% endif %}F{{a1}}{% elsif a1 < -1 %}G{{a1}}{% else %}H{{a1}}{% endif %}I", {"a1" => -2}
    assert_skeleton_rendered_result "AH-0.5I", "A{% if a1 > 0 %}B{{a1}}{% if a1 > 5 %}C{{a1}}{% elsif a1 > 1 %}D{{a1}}{% else %}E{{a1}}{% endif %}F{{a1}}{% elsif a1 < -1 %}G{{a1}}{% else %}H{{a1}}{% endif %}I", {"a1" => -0.5}

    assert_skeleton_rendered_result "AB6C6F6I", "A{% if a1 > 0 %}B{{a1}}{% if a1 > 5 %}C{{a1}}{% elsif a1 > 1 %}D{{a1}}{% else %}E{{a1}}{% endif %}F{{a1}}{% elsif a1 < -1 %}G{{a1}}{% else %}H{{a1}}{% endif %}I", {}, {"a1" => 6}, /a/
    assert_skeleton_rendered_result "AB4D4F4I", "A{% if a1 > 0 %}B{{a1}}{% if a1 > 5 %}C{{a1}}{% elsif a1 > 1 %}D{{a1}}{% else %}E{{a1}}{% endif %}F{{a1}}{% elsif a1 < -1 %}G{{a1}}{% else %}H{{a1}}{% endif %}I", {}, {"a1" => 4}, /a/
    assert_skeleton_rendered_result "AB0.5E0.5F0.5I", "A{% if a1 > 0 %}B{{a1}}{% if a1 > 5 %}C{{a1}}{% elsif a1 > 1 %}D{{a1}}{% else %}E{{a1}}{% endif %}F{{a1}}{% elsif a1 < -1 %}G{{a1}}{% else %}H{{a1}}{% endif %}I", {}, {"a1" => 0.5}, /a/
    assert_skeleton_rendered_result "AG-2I", "A{% if a1 > 0 %}B{{a1}}{% if a1 > 5 %}C{{a1}}{% elsif a1 > 1 %}D{{a1}}{% else %}E{{a1}}{% endif %}F{{a1}}{% elsif a1 < -1 %}G{{a1}}{% else %}H{{a1}}{% endif %}I", {}, {"a1" => -2}, /a/
    assert_skeleton_rendered_result "AH-0.5I", "A{% if a1 > 0 %}B{{a1}}{% if a1 > 5 %}C{{a1}}{% elsif a1 > 1 %}D{{a1}}{% else %}E{{a1}}{% endif %}F{{a1}}{% elsif a1 < -1 %}G{{a1}}{% else %}H{{a1}}{% endif %}I", {}, {"a1" => -0.5}, /a/
  end

end