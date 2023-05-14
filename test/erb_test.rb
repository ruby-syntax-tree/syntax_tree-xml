# frozen_string_literal: true

require "test_helper"

module SyntaxTree
  class ERBTest < Minitest::Test
    def test_example1
      directory = File.expand_path("fixture", __dir__)
      unformatted_file = File.join(directory, "example1_unformatted.html.erb")
      formatted_file = File.join(directory, "example1_formatted.html.erb")

      expected = ERB.read(formatted_file)
      actual = ERB.format(ERB.read(unformatted_file))

      assert_equal(actual, expected)
    end
  end
end
