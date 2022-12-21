# frozen_string_literal: true

module ERBLint
  module Reporters
    class JunitReporter < Reporter
      def preview; end

      def show
        @output = []
        xml_dump
        puts @output.join("\n")
      end

      private

      def xml_dump
        @output << %{<?xml version="1.0" encoding="UTF-8"?>}
        tests = stats.processed_files.size
        failures = stats.found
        @output << %{<testsuite name="erblint" tests="#{tests}" failures="#{failures}">}
        xml_dump_properties
        xml_dump_examples
        @output << %{</testsuite>\n}
      end

      def xml_dump_properties
        @output << %{<properties>}
        [
          { name: "erb_lint_version", value: ERBLint::VERSION },
          { name: "ruby_engine", value: RUBY_ENGINE },
          { name: "ruby_version", value: RUBY_VERSION },
          { name: "ruby_patchlevel", value: RUBY_PATCHLEVEL.to_s },
          { name: "ruby_platform", value: RUBY_PLATFORM },
        ].each do |property|
          @output << %{<property name="#{property[:name]}" value="#{escape(property[:value])}" />}
        end
        @output << %{</properties>}
      end

      def xml_dump_examples
        processed_files.each do |filename, offenses|
          next xml_dump_example(filename) if offenses.empty?

          offenses.each do |offense|
            xml_dump_failed(filename, offense)
          end
        end
      end

      def xml_dump_failed(filename, offense)
        xml_dump_example(filename) do
          message = escape(offense.message)
          type = escape(offense.simple_name)
          @output << %{<failure message="#{message}" type="#{type}">}
          @output << escape(offense.message)
          @output << %{</failure>}
        end
      end

      def xml_dump_example(filename)
        name = escape(filename.downcase.gsub(/[^a-z\-_]+/, "."))
        file = escape(filename)
        @output << %{<testcase name="#{name}" file="#{file}">}
        yield if block_given?
        @output << %{</testcase>}
      end

      # Inversion of character range from https://www.w3.org/TR/xml/#charsets
      ILLEGAL_REGEXP = Regexp.new(
        "[^".dup <<
        "\u{9}" << # => \t
        "\u{a}" << # => \n
        "\u{d}" << # => \r
        "\u{20}-\u{d7ff}" \
          "\u{e000}-\u{fffd}" \
          "\u{10000}-\u{10ffff}" \
          "]"
      )

      # Replace illegals with a Ruby-like escape
      ILLEGAL_REPLACEMENT = Hash.new do |_, c|
        x = c.ord
        # rubocop:disable Style/FormatString
        if x <= 0xff
          "\\x%02X" % x
        elsif x <= 0xffff
          "\\u%04X" % x
        else
          "\\u{%X}" % x
        end.freeze
        # rubocop:enable Style/FormatString
      end.update(
        "\0" => "\\0",
        "\a" => "\\a",
        "\b" => "\\b",
        "\f" => "\\f",
        "\v" => "\\v",
        "\e" => "\\e",
      ).freeze

      # Discouraged characters from https://www.w3.org/TR/xml/#charsets
      # Plus special characters with well-known entity replacements
      DISCOURAGED_REGEXP = Regexp.new(
        "[".dup <<
        "\u{22}" << # => "
        "\u{26}" << # => &
        "\u{27}" << # => '
        "\u{3c}" << # => <
        "\u{3e}" << # => >
        "\u{7f}-\u{84}" \
          "\u{86}-\u{9f}" \
          "\u{fdd0}-\u{fdef}" \
          "\u{1fffe}-\u{1ffff}" \
          "\u{2fffe}-\u{2ffff}" \
          "\u{3fffe}-\u{3ffff}" \
          "\u{4fffe}-\u{4ffff}" \
          "\u{5fffe}-\u{5ffff}" \
          "\u{6fffe}-\u{6ffff}" \
          "\u{7fffe}-\u{7ffff}" \
          "\u{8fffe}-\u{8ffff}" \
          "\u{9fffe}-\u{9ffff}" \
          "\u{afffe}-\u{affff}" \
          "\u{bfffe}-\u{bffff}" \
          "\u{cfffe}-\u{cffff}" \
          "\u{dfffe}-\u{dffff}" \
          "\u{efffe}-\u{effff}" \
          "\u{ffffe}-\u{fffff}" \
          "\u{10fffe}-\u{10ffff}" \
          "]"
      )

      # Translate well-known entities, or use generic unicode hex entity
      DISCOURAGED_REPLACEMENTS = Hash.new { |_, c| "&#x#{c.ord.to_s(16)};" }.update(
        '"' => "&quot;",
        "&" => "&amp;",
        "'" => "&apos;",
        "<" => "&lt;",
        ">" => "&gt;",
      ).freeze

      def escape(text)
        # Make sure it's utf-8, replace illegal characters with ruby-like
        # escapes, and replace special and discouraged characters with entities
        text
          .to_s
          .encode(Encoding::UTF_8)
          .gsub(ILLEGAL_REGEXP, ILLEGAL_REPLACEMENT)
          .gsub(DISCOURAGED_REGEXP, DISCOURAGED_REPLACEMENTS)
      end
    end
  end
end
