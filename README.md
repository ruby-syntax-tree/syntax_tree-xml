# SyntaxTree::XML

[![Build Status](https://github.com/davidwessman/syntax_tree-erb/actions/workflows/main.yml/badge.svg)](https://github.com/davidwessman/syntax_tree-erb/actions/workflows/main.yml)

[Syntax Tree](https://github.com/ruby-syntax-tree/syntax_tree) support for ERB.

## Work in progress!

This is not ready for production use just yet, still need to work on:

- Comments
- Blocks using `do`
- Blank lines
- Probably more

Currently handles

- ERB tags with and without output
- ERB tags inside strings
- HTML tags with attributes
- HTML tags with and without closing tags
- ERB `if`, `elsif` and `else` statements
- Text output
- Formatting the ruby code inside the ERB tags (using syntax_tree itself)

## Installation

Add this line to your application's Gemfile:

```ruby
gem github: "davidwessman/syntax_tree-erb"
```

## Usage

From code:

```ruby
require "syntax_tree/erb"

pp SyntaxTree::ERB.parse(source) # print out the AST
puts SyntaxTree::ERB.format(source) # format the AST
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/davidwessman/syntax_tree-erb.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
