# frozen_string_literal: true

module SyntaxTree
  module XML
    class Parser
      NAME_START =
        "[:a-zA-Z_\u{2070}-\u{218F}\u{2C00}-\u{2FEF}\u{3001}-\u{D7FF}\u{F900}-\u{FDCF}\u{FDF0}-\u{FFFD}]"

      NAME_CHAR =
        "[#{NAME_START}-\\.\\d\u{00B7}\u{0300}-\u{036F}\u{203F}-\u{2040}]"

      NAME = "#{NAME_START}(?:#{NAME_CHAR})*"

      # This is the parent class of any kind of errors that will be raised by
      # the parser.
      class ParseError < StandardError
      end

      # This error occurs when a certain token is expected in a certain place
      # but is not found. Sometimes this is handled internally because some
      # elements are optional. Other times it is not and it is raised to end the
      # parsing process.
      class MissingTokenError < ParseError
      end

      attr_reader :source, :tokens

      def initialize(source)
        @source = source
        @tokens = make_tokens
      end

      def parse
        parse_document
      end

      private

      def make_tokens
        Enumerator.new do |enum|
          index = 0
          line = 1
          state = %i[outside]

          while index < source.length
            case state.last
            in :outside
              case source[index..]
              when /\A(?: |\t|\n|\r\n)+/m
                # whitespace
                enum.yield :whitespace, $&, index, line
                line += $&.count("\n")
              when /\A<!--(.|\r?\n)*?-->/m
                # comments
                # <!-- this is a comment -->
                enum.yield :comment, $&, index, line
                line += $&.count("\n")
              when /\A<!\[CDATA\[(.|\r?\n)*?\]\]>/m
                # character data tags
                # <![CDATA[<message>Welcome!</message>]]>
                enum.yield :cdata, $&, index, line
                line += $&.count("\n")
              when /\A<!DOCTYPE/
                # document type tags
                # <!DOCTYPE
                enum.yield :doctype, $&, index, line
                state << :inside
              when /\A<!.+?>/
                # document type definition tags
                # <!ENTITY nbsp "&#xA0;">
                enum.yield :dtd, $&, index, line
              when /\A<\?xml[ \t\r\n]/
                # xml declaration opening
                # <?xml
                enum.yield :xml_decl, $&, index, line
                state << :inside
                line += $&.count("\n")
              when %r{\A</}
                # the beginning of a closing tag
                # </
                enum.yield :slash_open, $&, index, line
                state << :inside
              when /\A<\?#{NAME}.+?\?>/
                # a processing instruction
                # <?xml-stylesheet type="text/xsl" href="style.xsl" ?>
                enum.yield :processing_instruction, $&, index, line
              when /\A</
                # the beginning of an opening tag
                # <
                enum.yield :open, $&, index, line
                state << :inside
              when /\A&#{NAME};/
                # entity reference
                # &amp;
                enum.yield :entity_reference, $&, index, line
              when /\A&#(?:\d+|x[a-fA-F0-9]+);/
                # character reference
                # &#1234;
                enum.yield :character_reference, $&, index, line
              when /\A[^<&]+/
                # plain text content
                # abc
                enum.yield :text, $&, index, line
              else
                raise ParseError,
                      "Unexpected character at #{index}: #{source[index]}"
              end
            in :inside
              case source[index..]
              when /\A[ \t\r\n]+/
                # whitespace
                line += $&.count("\n")
              when /\A>/
                # the end of a tag
                # >
                enum.yield :close, $&, index, line
                state.pop
              when /\A\?>/
                # the end of a tag
                # ?>
                enum.yield :special_close, $&, index, line
                state.pop
              when %r{\A/>}
                # the end of a self-closing tag
                enum.yield :slash_close, $&, index, line
                state.pop
              when %r{\A/}
                # a forward slash
                # /
                enum.yield :slash, $&, index, line
              when /\A=/
                # an equals sign
                # =
                enum.yield :equals, $&, index, line
              when /\A(?:"[^<"]*"|'[<^']*')/
                # a quoted string
                # "abc"
                enum.yield :string, $&, index, line
              when /\A#{NAME}/
                # a name
                # abc
                enum.yield :name, $&, index, line
              else
                raise ParseError,
                      "Unexpected character at #{index}: #{source[index]}"
              end
            end

            index += $&.length
          end

          enum.yield :EOF, nil, index, line
        end
      end

      # If the next token in the list of tokens matches the expected type, then
      # we're going to create a new Token, advance the token enumerator, and
      # return the new Token. Otherwise we're going to raise a
      # MissingTokenError.
      def consume(expected)
        type, value, index, line = tokens.peek

        if expected != type
          raise MissingTokenError, "expected #{expected} got #{type}"
        end

        tokens.next

        Token.new(
          type: type,
          value: value,
          location:
            Location.new(
              start_char: index,
              end_char: index + value.length,
              start_line: line,
              end_line: line + value.count("\n")
            )
        )
      end

      # We're going to yield to the block which should attempt to consume some
      # number of tokens. If any of them are missing, then we're going to return
      # nil from this block.
      def maybe
        yield
      rescue MissingTokenError
      end

      # We're going to attempt to parse everything by yielding to the block. If
      # nothing is returned by the block, then we're going to raise an error.
      # Otherwise we'll return the value returned by the block.
      def atleast
        result = yield
        raise MissingTokenError if result.nil?
        result
      end

      # We're going to attempt to parse with the block many times. We'll stop
      # parsing once we get an error back from the block.
      def many
        items = []

        loop do
          begin
            items << yield
          rescue MissingTokenError
            break
          end
        end

        items
      end

      def parse_document
        prolog = maybe { parse_prolog }
        miscs = many { parse_misc }

        doctype = maybe { parse_doctype }
        miscs += many { parse_misc }

        element = parse_element
        miscs += many { parse_misc }

        parts = [prolog, *miscs, doctype, element].compact

        Document.new(
          prolog: prolog,
          miscs: miscs,
          doctype: doctype,
          element: element,
          location: parts.first.location.to(parts.last.location)
        )
      end

      def parse_prolog
        opening = consume(:xml_decl)
        attributes = many { parse_attribute }
        closing = consume(:special_close)

        Prolog.new(
          opening: opening,
          attributes: attributes,
          closing: closing,
          location: opening.location.to(closing.location)
        )
      end

      def parse_doctype
        opening = consume(:doctype)
        name = consume(:name)
        external_id = maybe { parse_external_id }
        closing = consume(:close)

        DocType.new(
          opening: opening,
          name: name,
          external_id: external_id,
          closing: closing,
          location: opening.location.to(closing.location)
        )
      end

      def parse_external_id
        type = consume(:name)
        public_id = consume(:string) if type.value == "PUBLIC"
        system_id = consume(:string)

        ExternalID.new(
          type: type,
          public_id: public_id,
          system_id: system_id,
          location: type.location.to(system_id.location)
        )
      end

      def parse_content
        many do
          atleast do
            maybe { parse_element } || maybe { parse_chardata } ||
              maybe { parse_reference } || maybe { consume(:cdata) } ||
              maybe { consume(:processing_instruction) } ||
              maybe { consume(:comment) }
          end
        end
      end

      def parse_opening_tag
        opening = consume(:open)
        name = consume(:name)
        attributes = many { parse_attribute }
        closing =
          atleast do
            maybe { consume(:close) } || maybe { consume(:slash_close) }
          end

        Element::OpeningTag.new(
          opening: opening,
          name: name,
          attributes: attributes,
          closing: closing,
          location: opening.location.to(closing.location)
        )
      end

      def parse_closing_tag
        opening = consume(:slash_open)
        name = consume(:name)
        closing = consume(:close)

        Element::ClosingTag.new(
          opening: opening,
          name: name,
          closing: closing,
          location: opening.location.to(closing.location)
        )
      end

      def parse_element
        opening_tag = parse_opening_tag

        if opening_tag.closing.value == ">"
          content = parse_content
          closing_tag = parse_closing_tag

          Element.new(
            opening_tag: opening_tag,
            content: content,
            closing_tag: closing_tag,
            location: opening_tag.location.to(closing_tag.location)
          )
        else
          Element.new(
            opening_tag: opening_tag,
            content: nil,
            closing_tag: nil,
            location: opening_tag.location
          )
        end
      end

      def parse_reference
        value =
          atleast do
            maybe { consume(:entity_reference) } ||
              maybe { consume(:character_reference) }
          end

        Reference.new(value: value, location: value.location)
      end

      def parse_attribute
        key = consume(:name)
        equals = consume(:equals)
        value = consume(:string)

        Attribute.new(
          key: key,
          equals: equals,
          value: value,
          location: key.location.to(value.location)
        )
      end

      def parse_chardata
        value =
          atleast { maybe { consume(:text) } || maybe { consume(:whitespace) } }

        CharData.new(value: value, location: value.location)
      end

      def parse_misc
        value =
          atleast do
            maybe { consume(:comment) } ||
              maybe { consume(:processing_instruction) } ||
              maybe { consume(:whitespace) }
          end

        Misc.new(value: value, location: value.location)
      end
    end
  end
end
