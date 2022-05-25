# frozen_string_literal: true

module SyntaxTree
  module XML
    # A Location represents a position for a node in the source file.
    class Location
      attr_reader :start_char, :end_char, :start_line, :end_line

      def initialize(start_char:, end_char:, start_line:, end_line:)
        @start_char = start_char
        @end_char = end_char
        @start_line = start_line
        @end_line = end_line
      end

      def deconstruct_keys(keys)
        {
          start_char: start_char,
          end_char: end_char,
          start_line: start_line,
          end_line: end_line
        }
      end

      def to(other)
        Location.new(
          start_char: start_char,
          start_line: start_line,
          end_char: other.end_char,
          end_line: other.end_line
        )
      end

      def <=>(other)
        start_char <=> other.start_char
      end
    end

    # A parent node that contains a bit of shared functionality.
    class Node
      def format(q)
        Format.new(q).visit(self)
      end

      def pretty_print(q)
        PrettyPrint.new(q).visit(self)
      end
    end

    # A Token is any kind of lexical token from the source. It has a type, a
    # value which is a subset of the source, and an index where it starts in
    # the source.
    class Token < Node
      attr_reader :type, :value, :location

      def initialize(type:, value:, location:)
        @type = type
        @value = value
        @location = location
      end

      def accept(visitor)
        visitor.visit_token(self)
      end

      def child_nodes
        []
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { type: type, value: value, location: location }
      end
    end

    # The Document node is the top of the syntax tree. It contains an optional
    # prolog, an optional doctype declaration, any number of optional
    # miscellenous elements like comments, whitespace, or processing
    # instructions, and a root element.
    class Document < Node
      attr_reader :prolog, :miscs, :doctype, :element, :location

      def initialize(prolog:, miscs:, doctype:, element:, location:)
        @prolog = prolog
        @miscs = miscs
        @doctype = doctype
        @element = element
        @location = location
      end

      def accept(visitor)
        visitor.visit_document(self)
      end

      def child_nodes
        [prolog, *miscs, doctype, element].compact
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        {
          prolog: prolog,
          miscs: miscs,
          doctype: doctype,
          element: element,
          location: location
        }
      end
    end

    # The prolog to the document includes an XML declaration which opens the
    # tag, any number of attributes, and a closing of the tag.
    class Prolog < Node
      attr_reader :opening, :attributes, :closing, :location

      def initialize(opening:, attributes:, closing:, location:)
        @opening = opening
        @attributes = attributes
        @closing = closing
        @location = location
      end

      def accept(visitor)
        visitor.visit_prolog(self)
      end

      def child_nodes
        [opening, *attributes, closing]
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        {
          opening: opening,
          attributes: attributes,
          closing: closing,
          location: location
        }
      end
    end

    # A document type declaration is a special kind of tag that specifies the
    # type of the document. It contains an opening declaration, the name of
    # the document type, an optional external identifier, and a closing of the
    # tag.
    class DocType < Node
      attr_reader :opening, :name, :external_id, :closing, :location

      def initialize(opening:, name:, external_id:, closing:, location:)
        @opening = opening
        @name = name
        @external_id = external_id
        @closing = closing
        @location = location
      end

      def accept(visitor)
        visitor.visit_doctype(self)
      end

      def child_nodes
        [opening, name, external_id, closing].compact
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        {
          opening: opening,
          name: name,
          external_id: external_id,
          closing: closing,
          location: location
        }
      end
    end

    # An external ID is a child of a document type declaration. It represents
    # the location where the external identifier is located. It contains a
    # type (either system or public), an optional public id literal, and the
    # system literal.
    class ExternalID < Node
      attr_reader :type, :public_id, :system_id, :location

      def initialize(type:, public_id:, system_id:, location:)
        @type = type
        @public_id = public_id
        @system_id = system_id
      end

      def accept(visitor)
        visitor.visit_external_id(self)
      end

      def child_nodes
        [type, public_id, system_id].compact
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        {
          type: type,
          public_id: public_id,
          system_id: system_id,
          location: location
        }
      end
    end

    # An element is a child of the document. It contains an opening tag, any
    # optional content within the tag, and a closing tag. It can also
    # potentially contain an opening tag that self-closes, in which case the
    # content and closing tag will be nil.
    class Element < Node
      # The opening tag of an element. It contains the opening character (<),
      # the name of the element, any optional attributes, and the closing
      # token (either > or />).
      class OpeningTag < Node
        attr_reader :opening, :name, :attributes, :closing, :location

        def initialize(opening:, name:, attributes:, closing:, location:)
          @opening = opening
          @name = name
          @attributes = attributes
          @closing = closing
          @location = location
        end

        def accept(visitor)
          visitor.visit_opening_tag(self)
        end

        def child_nodes
          [opening, name, *attributes, closing]
        end

        alias deconstruct child_nodes

        def deconstruct_keys(keys)
          {
            opening: opening,
            name: name,
            attributes: attributes,
            closing: closing,
            location: location
          }
        end
      end

      # The closing tag of an element. It contains the opening character (<),
      # the name of the element, and the closing character (>).
      class ClosingTag < Node
        attr_reader :opening, :name, :closing, :location

        def initialize(opening:, name:, closing:, location:)
          @opening = opening
          @name = name
          @closing = closing
          @location = location
        end

        def accept(visitor)
          visitor.visit_closing_tag(self)
        end

        def child_nodes
          [opening, name, closing]
        end

        alias deconstruct child_nodes

        def deconstruct_keys(keys)
          { opening: opening, name: name, closing: closing, location: location }
        end
      end

      attr_reader :opening_tag, :content, :closing_tag, :location

      def initialize(opening_tag:, content:, closing_tag:, location:)
        @opening_tag = opening_tag
        @content = content
        @closing_tag = closing_tag
        @location = location
      end

      def accept(visitor)
        visitor.visit_element(self)
      end

      def child_nodes
        [opening_tag, *content, closing_tag].compact
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        {
          opening_tag: opening_tag,
          content: content,
          closing_tag: closing_tag,
          location: location
        }
      end
    end

    # A Reference is either a character or entity reference. It contains a
    # single value that is the token it contains.
    class Reference < Node
      attr_reader :value, :location

      def initialize(value:, location:)
        @value = value
        @location = location
      end

      def accept(visitor)
        visitor.visit_reference(self)
      end

      def child_nodes
        [value]
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { value: value, location: location }
      end
    end

    # An Attribute is a key-value pair within a tag. It contains the key, the
    # equals sign, and the value.
    class Attribute < Node
      attr_reader :key, :equals, :value, :location

      def initialize(key:, equals:, value:, location:)
        @key = key
        @equals = equals
        @value = value
        @location = location
      end

      def accept(visitor)
        visitor.visit_attribute(self)
      end

      def child_nodes
        [key, equals, value]
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { key: key, equals: equals, value: value, location: location }
      end
    end

    # A CharData contains either plain text or whitespace within an element.
    # It wraps a single token value.
    class CharData < Node
      attr_reader :value, :location

      def initialize(value:, location:)
        @value = value
        @location = location
      end

      def accept(visitor)
        visitor.visit_char_data(self)
      end

      def child_nodes
        [value]
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { value: value, location: location }
      end
    end

    # A Misc is a catch-all for miscellaneous content outside the root tag of
    # the XML document. It contains a single token which can be either a
    # comment, a processing instruction, or whitespace.
    class Misc < Node
      attr_reader :value, :location

      def initialize(value:, location:)
        @value = value
        @location = location
      end

      def accept(visitor)
        visitor.visit_misc(self)
      end

      def child_nodes
        [value]
      end

      alias deconstruct child_nodes

      def deconstruct_keys(keys)
        { value: value, location: location }
      end
    end
  end
end
