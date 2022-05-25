# frozen_string_literal: true

require "test_helper"

module SyntaxTree
  class XMLTest < Minitest::Test
    def test_formatting
      directory = File.expand_path("fixture", __dir__)

      expected = XML.read(File.join(directory, "formatted.xml"))
      actual = XML.format(XML.read(File.join(directory, "unformatted.xml")))

      assert_equal(expected, actual)
    end
  end
end
