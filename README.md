# ERB Lint [![Build Status](https://travis-ci.org/Shopify/erb-lint.svg?branch=master)](https://travis-ci.org/Shopify/erb-lint)

`erb-lint` is a tool to help lint your ERB or HTML files using the included linters or by writing your own.

## Requirements

* Ruby 2.2.0+ (Runtime)
* Ruby 2.3.0+ (Development)
 - This is due to the use of the tilde-heredoc `<<~` syntax in some tests.

## Installation

```bash
gem install erb_lint
```

...or add the following to your `Gemfile` and run `bundle install`:

```ruby
gem 'erb_lint'
```

## Configuration

Create a `.erb-lint.yml` file in your project, with the following structure:

```yaml
---
linters:
  ErbSafety:
    enabled: true
    better_html_config: .better-html.yml
  Rubocop:
    enabled: true
    rubocop_config:
      inherit_from:
        - .rubocop.yml
```

See below for linter-specific configuration options.

## Usage

This gem provides a command-line interface which can be run like so:

1. Run `erblint [options]` if the gem is installed standalone.
2. Run `bundle exec erblint [options]` if the gem is installed as a Gemfile dependency for your app.

For example, `erblint --lint-all --enable-all-linters` will run all available
linters on all ERB files in the current directory or its descendants (`**/*.html{+*,}.erb`).

## Available linters

`erb-lint` comes with linters on-board:
* `DeprecatedClasses`: warn about deprecated css classes.
* `FinalNewline`: warn about missing newline at the end of a ERB template.
* `ErbSafety`: detects unsafe interpolation of ruby data into various javascript contexts and enforce usage of safe helpers like `.to_json`. See [better-html's readme](https://github.com/Shopify/better-html#testing-for-valid-html-and-erb) for more information.
* `Rubocop`: runs RuboCop rules on ruby statements found in ERB templates.

### DeprecatedClasses

DeprecatedClasses will find all classes used on HTML elements and report any classes that violate the rule set that you provide.

A `rule_set` is specified as a list, each with a set of `deprecated` classes and a corresponding `suggestion` to use as an alternative.

Example configuration:

```yaml
---
linters:
  DeprecatedClasses:
    enabled: true
    exclude:
      - 'app/views/shared/deprecated/**'
    addendum: "See UX wiki for help."
    rule_set:
      - deprecated: ['badge[-_\w]*']
        suggestion: "Use the ui_badge() component instead."
```

You can specify an `addendum` to be added to the end of each violation.
The error message format is: `"Deprecated class ... #{suggestion}"`
or `"Deprecated class ... #{suggestion} #{addendum}"` if an `addendum` is present.

Linter-Specific Option | Description
-----------------------|-----------------------------------------------------------------------------------
`rule_set`             | A list of rules, each with a `deprecated` and `suggestion` option.
`deprecated`           | A list of **regular expressions** which specify the classes deprecated by this rule.
`suggestion`           | A string to be included in the rule's error message. Make this informative and specific to the rule that it is contained in.
`addendum`             | A string to be included at the end of every error message of the rule set. (Optional)

### FinalNewline

Files must have a final newline. This results in better diffs when
adding lines to the file, since SCM systems such as git won't think that you
touched the last line.

You can customize whether or not a final newline exists with the `present`
option.

Example configuration:

```yaml
---
linters:
  FinalNewline:
    enabled: true
```

Linter-Specific Option | Description
-----------------------|---------------------------------------------------------
`present`              | Whether a final newline should be present (default **true**)

### ErbSafety

Runs the checks provided by
[better-html's erb safety test helper](https://github.com/Shopify/better-html#testing-for-valid-html-and-erb).

When using ERB interpolations in javascript contexts, this linter enforces the usage of safe helpers such as `.to_json`.
Any ERB statement that does not call a safe helper is deemed unsafe and a violation is shown.

For example:
```erb
Not allowed ❌
<a onclick="alert(<%= some_data %>)">

Allowed ✅
<a onclick="alert(<%= some_data.to_json %>)">
```

```erb
Not allowed ❌
<script>var myData = <%= some_data %>;</script>

Allowed ✅
<script>var myData = <%= some_data.to_json %>;</script>
```

Example configuration:

```yaml
---
linters:
  ErbSafety:
    enabled: true
    better_html_config: .better-html.yml
```

Linter-Specific Option | Description
-----------------------|---------------------------------------------------------
`better_html_config`   | Name of the configuration file to use for `better-html`. Optional. Valid options and their defaults are described [in better-html's readme](https://github.com/Shopify/better-html#configuration).

### Rubocop

Runs RuboCop on all ruby statements found in ERB templates. The RuboCop configuration that `erb-lint` uses can inherit from
the configuration that the rest of your application uses. `erb-lint` can be configured independently however, as it will often
be necessary to disable specific RuboCop rules that do not apply to ERB files.

Example configuration:

```yaml
---
linters:
  Rubocop:
    enabled: true
    rubocop_config:
      inherit_from:
        - .rubocop.yml
      Layout/InitialIndentation:
        Enabled: false
      Layout/TrailingBlankLines:
        Enabled: false
      Layout/TrailingWhitespace:
        Enabled: false
      Naming/FileName:
        Enabled: false
      Style/FrozenStringLiteralComment:
        Enabled: false
      Metrics/LineLength:
        Enabled: false
      Lint/UselessAssignment:
        Enabled: false
      Rails/OutputSafety:
        Enabled: false
```

The cops disabled in the example configuration above provide a good starting point.

Linter-Specific Option | Description
-----------------------|---------------------------------------------------------
`rubocop_config`       | A valid rubocop configuration hash. Mandatory when this cop is enabled. See [rubocop's manual entry on Configuration](http://rubocop.readthedocs.io/en/latest/configuration/)

## Custom Linters

`erb-lint` allows you to create custom linters specific to your project. It will load linters from the `.erb-linters` directory in the root of your
repository. See the [linters directory](lib/erb_lint/linters) for examples of how to write linters.

```ruby
# .erb-linters/custom_linter.rb

module ERBLint
  module Linters
  class CustomLinter < Linter
    include LinterRegistry

    class ConfigSchema < LinterConfig
      property :custom_message, accepts: String
    end
    self.config_schema = ConfigSchema

    def offenses(processed_source)
      errors = []
      unless processed_source.file_content.include?('this file is fine')
        errors << Offense.new(
          self,
          processed_source.to_source_range(0, processed_source.file_content.size),
          "This file isn't fine. #{@config.custom_message}"
        )
      end
      errors
    end
  end
end
```

By default, this linter would be disabled. You can enable it by adding an entry to `.erb-lint.yml`:

```yaml
---
linters:
  CustomLinter:
    enabled: true
    custom_message: We suggest you change this file.
```

Test your linter by running `erblint`'s command-line interface:

```bash
bundle exec erblint --enable-linters custom_linter --lint-all
```

Running this on a random project might yield this output:

```
Linting 15 files with 1 linters...

This file isn't fine. We suggest you change this file.
In file: app/views/layouts/application.html.erb:1

Errors were found in ERB files
```

To write a linter that can autocorrect offenses it detects, simply add an
`autocorrect` method that returns a callable. The callable is called with an instance of
[`RuboCop::Cop::Corrector`](http://www.rubydoc.info/github/bbatsov/RuboCop/RuboCop/Cop/Corrector)
as argument, and therefore erb-lint correctors work exactly as RuboCop correctors do.

```ruby
def autocorrect(_processed_source, offense)
  lambda do |corrector|
    corrector.insert_after(offense.source_range, "this file is fine")
  end
end
```

## License

This project is released under the [MIT license](LICENSE.txt).
