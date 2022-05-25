# frozen_string_literal: true

module SyntaxTree
  module XML
    class Format < Visitor
      attr_reader :q

      def initialize(q)
        @q = q
      end

      # Visit a Token node.
      def visit_token(node)
        q.text(node.value.strip)
      end

      # Visit a Document node.
      def visit_document(node)
        child_nodes =
          node
            .child_nodes
            .select do |child_node|
              case child_node
              in Misc[value: Token[type: :whitespace]]
                false
              else
                true
              end
            end
            .sort_by(&:location)

        q.seplist(child_nodes, -> { q.breakable(force: true) }) do |child_node|
          visit(child_node)
        end

        q.breakable(force: true)
      end

      # Visit a Prolog node.
      def visit_prolog(node)
        q.group do
          visit(node.opening)

          if node.attributes.any?
            q.indent do
              q.breakable("")
              q.seplist(node.attributes, -> { q.breakable }) do |child_node|
                visit(child_node)
              end
            end
          end

          q.breakable
          visit(node.closing)
        end
      end

      # Visit a Doctype node.
      def visit_doctype(node)
        q.group do
          visit(node.opening)
          q.text(" ")
          visit(node.name)

          if node.external_id
            q.text(" ")
            visit(node.external_id)
          end

          visit(node.closing)
        end
      end

      # Visit an ExternalID node.
      def visit_external_id(node)
        q.group do
          q.group do
            visit(node.type)

            if node.public_id
              q.indent do
                q.breakable
                visit(node.public_id)
              end
            end
          end

          q.indent do
            q.breakable
            visit(node.system_id)
          end
        end
      end

      # Visit an Element node.
      def visit_element(node)
        inner_nodes =
          node.content&.select do |child_node|
            case child_node
            in CharData[value: Token[type: :whitespace]]
              false
            in CharData[value: Token[value:]] if value.strip.empty?
              false
            else
              true
            end
          end

        case inner_nodes
        in nil
          visit(node.opening_tag)
        in []
          visit(
            Element::OpeningTag.new(
              opening: node.opening_tag.opening,
              name: node.opening_tag.name,
              attributes: node.opening_tag.attributes,
              closing:
                Token.new(
                  type: :close,
                  value: "/>",
                  location: node.opening_tag.closing.location
                ),
              location: node.opening_tag.location
            )
          )
        in [CharData[value: Token[type: :text, value:]]]
          q.group do
            visit(node.opening_tag)
            q.indent do
              q.breakable("")
              format_text(q, value)
            end

            q.breakable("")
            visit(node.closing_tag)
          end
        else
          q.group do
            visit(node.opening_tag)
            q.indent do
              q.breakable("")

              inner_nodes.each_with_index do |child_node, index|
                if index != 0
                  q.breakable(force: true)

                  end_line = inner_nodes[index - 1].location.end_line
                  start_line = child_node.location.start_line
                  q.breakable(force: true) if (start_line - end_line) >= 2
                end

                case child_node
                in CharData[value: Token[type: :text, value:]]
                  format_text(q, value)
                else
                  visit(child_node)
                end
              end
            end

            q.breakable(force: true)
            visit(node.closing_tag)
          end
        end
      end

      # Visit an Element::OpeningTag node.
      def visit_opening_tag(node)
        q.group do
          visit(node.opening)
          visit(node.name)

          if node.attributes.any?
            q.indent do
              q.breakable
              q.seplist(node.attributes, -> { q.breakable }) do |child_node|
                visit(child_node)
              end
            end
          end

          q.breakable(node.closing.value == "/>" ? " " : "")
          visit(node.closing)
        end
      end

      # Visit an Element::ClosingTag node.
      def visit_closing_tag(node)
        q.group do
          visit(node.opening)
          visit(node.name)
          visit(node.closing)
        end
      end

      # Visit a Reference node.
      def visit_reference(node)
        visit(node.value)
      end

      # Visit an Attribute node.
      def visit_attribute(node)
        q.group do
          visit(node.key)
          visit(node.equals)
          visit(node.value)
        end
      end

      # Visit a CharData node.
      def visit_char_data(node)
        lines = node.value.value.strip.split("\n")

        q.seplist(lines, -> { q.breakable(indent: false) }) do |line|
          q.text(line)
        end
      end

      # Visit a Misc node.
      def visit_misc(node)
        visit(node.value)
      end

      private

      # Format a text by splitting nicely at newlines and spaces.
      def format_text(q, value)
        q.seplist(
          value.strip.split("\n"),
          -> { q.breakable(force: true, indent: false) }
        ) do |line|
          q.seplist(
            line.split(/\b(?: +)\b/),
            -> { q.group { q.breakable } }
          ) { |segment| q.text(segment) }
        end
      end
    end
  end
end
