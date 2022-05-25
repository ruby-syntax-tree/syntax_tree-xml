# frozen_string_literal: true

module SyntaxTree
  module XML
    class PrettyPrint < Visitor
      attr_reader :q

      def initialize(q)
        @q = q
      end

      # Visit a Token node.
      def visit_token(node)
        q.pp(node.value)
      end

      # Visit a Document node.
      def visit_document(node)
        visit_node("document", node)
      end

      # Visit a Prolog node.
      def visit_prolog(node)
        visit_node("prolog", node)
      end

      # Visit a Doctype node.
      def visit_doctype(node)
        visit_node("doctype", node)
      end

      # Visit an ExternalID node.
      def visit_external_id(node)
        visit_node("external_id", node)
      end

      # Visit an Element node.
      def visit_element(node)
        visit_node("element", node)
      end

      # Visit an Element::OpeningTag node.
      def visit_opening_tag(node)
        visit_node("opening_tag", node)
      end

      # Visit an Element::ClosingTag node.
      def visit_closing_tag(node)
        visit_node("closing_tag", node)
      end

      # Visit a Reference node.
      def visit_reference(node)
        visit_node("reference", node)
      end

      # Visit an Attribute node.
      def visit_attribute(node)
        visit_node("attribute", node)
      end

      # Visit a CharData node.
      def visit_char_data(node)
        visit_node("char_data", node)
      end

      # Visit a Misc node.
      def visit_misc(node)
        visit_node("misc", node)
      end

      private

      # A generic visit node function for how we pretty print nodes.
      def visit_node(type, node)
        q.group do
          q.text("(#{type}")
          q.nest(2) do
            q.breakable
            q.seplist(node.child_nodes) { |child_node| visit(child_node) }
          end
          q.breakable("")
          q.text(")")
        end
      end
    end
  end
end
