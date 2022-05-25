# frozen_string_literal: true

module SyntaxTree
  module XML
    class Visitor
      def visit(node)
        node&.accept(self)
      end

      private

      def visit_all(nodes)
        nodes.map { |node| visit(node) }
      end

      def visit_child_nodes(node)
        visit_all(node.child_nodes)
      end

      # Visit a Token node.
      alias visit_token visit_child_nodes

      # Visit a Document node.
      alias visit_document visit_child_nodes

      # Visit a Prolog node.
      alias visit_prolog visit_child_nodes

      # Visit a Doctype node.
      alias visit_doctype visit_child_nodes

      # Visit an ExternalID node.
      alias visit_external_id visit_child_nodes

      # Visit an Element node.
      alias visit_element visit_child_nodes

      # Visit an Element::OpeningTag node.
      alias visit_opening_tag visit_child_nodes

      # Visit an Element::ClosingTag node.
      alias visit_closing_tag visit_child_nodes

      # Visit a Reference node.
      alias visit_reference visit_child_nodes

      # Visit an Attribute node.
      alias visit_attribute visit_child_nodes

      # Visit a CharData node.
      alias visit_char_data visit_child_nodes

      # Visit a Misc node.
      alias visit_misc visit_child_nodes
    end
  end
end
