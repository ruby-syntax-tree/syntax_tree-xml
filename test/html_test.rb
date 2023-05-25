# frozen_string_literal: true

require "test_helper"

module SyntaxTree
  class HtmlTest < Minitest::Test
    def test_html_missing_end_tag
      assert_raises(SyntaxTree::ERB::Parser::ParseError) do
        ERB.parse("<h1>Hello World")
      end
    end

    def test_html_incorrect_end_tag
      assert_raises(SyntaxTree::ERB::Parser::ParseError) do
        ERB.parse("<h1>Hello World</h2>")
      end
    end

    def test_html_unmatched_double_quote
      assert_raises(SyntaxTree::ERB::Parser::ParseError) do
        ERB.parse("<div class=\"card-\"\">Hello World</div>")
      end
    end

    def test_html_unmatched_single_quote
      assert_raises(SyntaxTree::ERB::Parser::ParseError) do
        ERB.parse("<div class='card-''>Hello World</div>")
      end
    end

    def test_html_doctype
      parsed = ERB.parse("<!DOCTYPE html>")
      assert_instance_of(SyntaxTree::ERB::Doctype, parsed.elements.first)

      parsed = ERB.parse("<!doctype html>")
      assert_instance_of(SyntaxTree::ERB::Doctype, parsed.elements.first)
    end

    def test_html_comment
      source = "<!-- This is a HTML-comment -->\n"
      parsed = ERB.parse(source)
      elements = parsed.elements
      assert_equal(1, elements.size)
      assert_instance_of(SyntaxTree::ERB::HtmlComment, elements.first)

      formatted = ERB.format(source)
      assert_equal(source, formatted)
    end
  end
end