# SyntaxTree::XML

[![Build Status](https://github.com/ruby-syntax-tree/syntax_tree-xml/actions/workflows/main.yml/badge.svg)](https://github.com/ruby-syntax-tree/syntax_tree-xml/actions/workflows/main.yml)
[![Gem Version](https://img.shields.io/gem/v/syntax_tree-xml.svg)](https://rubygems.org/gems/syntax_tree-xml)

[Syntax Tree](https://github.com/ruby-syntax-tree/syntax_tree) support for XML.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "syntax_tree-xml"
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install syntax_tree-xml

## Usage

From code:

```ruby
require "syntax_tree/xml"

pp SyntaxTree::XML.parse(source) # print out the AST
puts SyntaxTree::XML.format(source) # format the AST
```

From the CLI:

```sh
$ stree ast --plugins=xml file.xml
(document
  (misc "\n"),
  (element
    (opening_tag "<", "message", ">"),
    (char_data "\n" + "  "),
    (element (opening_tag "<", "hello", ">"), (char_data "Hello"), (closing_tag "</", "hello", ">")),
    (char_data "\n" + "  "),
    (element (opening_tag "<", "world", ">"), (char_data "World"), (closing_tag "</", "world", ">")),
    (char_data "\n"),
    (closing_tag "</", "message", ">")
  )
)
```

or

```sh
$ stree format --plugins=xml file.xml
<message>
  <hello>Hello</hello>
  <world>World</world>
</message>
```

or

```sh
$ stree write --plugins=xml file.xml
file.xml 1ms
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ruby-syntax-tree/syntax_tree-xml.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
