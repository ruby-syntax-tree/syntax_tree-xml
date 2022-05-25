# frozen_string_literal: true

require "prettier_print"
require "syntax_tree"

require_relative "xml/nodes"
require_relative "xml/parser"
require_relative "xml/visitor"

require_relative "xml/format"
require_relative "xml/pretty_print"

module SyntaxTree
  module XML
    def self.format(source, maxwidth = 80)
      PrettierPrint.format(+"", maxwidth) { |q| parse(source).format(q) }
    end

    def self.parse(source)
      Parser.new(source).parse
    end

    def self.read(filepath)
      File.read(filepath)
    end
  end

  register_handler(".xml", XML)
end
