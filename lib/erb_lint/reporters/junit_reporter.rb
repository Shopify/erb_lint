# frozen_string_literal: true

require "rexml/document"
require "rexml/formatters/pretty"

module ERBLint
  module Reporters
    class JunitReporter < Reporter
      def preview; end

      def show
        puts xml_dump
      end

      def xml_dump
        xml = REXML::Document.new
        xml.context[:attribute_quote] = :quote
        xml.context[:prologue_quote] = :quote
        xml << REXML::XMLDecl.new("1.0", "UTF-8")
        tests = stats.processed_files.size
        failures = stats.found
        testsuite_element = REXML::Element.new("testsuite")
        testsuite_element.add_attribute("name", "erblint")
        testsuite_element.add_attribute("tests", tests.to_s)
        testsuite_element.add_attribute("failures", failures.to_s)
        xml.add_element(testsuite_element)

        xml_dump_properties(testsuite_element)
        xml_dump_examples(testsuite_element)

        formatted_xml_string = StringIO.new
        REXML::Formatters::Pretty.new.write(xml, formatted_xml_string)

        formatted_xml_string.string
      end

      def xml_dump_properties(testsuite_element)
        properties_element = REXML::Element.new("properties")
        testsuite_element.add_element(properties_element)

        [
          { name: "erb_lint_version", value: ERBLint::VERSION },
          { name: "ruby_engine", value: RUBY_ENGINE },
          { name: "ruby_version", value: RUBY_VERSION },
          { name: "ruby_patchlevel", value: RUBY_PATCHLEVEL.to_s },
          { name: "ruby_platform", value: RUBY_PLATFORM },
        ].each do |property|
          property_element = REXML::Element.new("property")
          property_element.add_attribute("name", property[:name].to_s)
          property_element.add_attribute("value", property[:value].to_s)
          properties_element.add_element(property_element)
        end
      end

      def xml_dump_examples(testsuite_element)
        processed_files.each do |filename, offenses|
          next xml_dump_example(testsuite_element, filename) if offenses.empty?

          offenses.each do |offense|
            xml_dump_failed(testsuite_element, filename, offense)
          end
        end
      end

      def xml_dump_failed(testsuite_element, filename, offense)
        xml_dump_example(testsuite_element, filename, offense) do |testcase_element|
          message = offense.message
          type = offense.simple_name

          failure_element = REXML::Element.new("failure")
          failure_element.add_attribute("message", message.to_s)
          failure_element.add_attribute("type", type.to_s)
          failure_element.add_text(offense.message)
          testcase_element.add_element(failure_element)
        end
      end

      def xml_dump_example(testsuite_element, filename, offense = nil)
        name = filename.downcase.gsub(/[^a-z\-_]+/, ".")
        file = filename

        testcase_element = REXML::Element.new("testcase")
        testcase_element.add_attribute("name", name.to_s)
        testcase_element.add_attribute("file", file.to_s)
        testsuite_element.add_element(testcase_element)

        yield testcase_element if block_given?
      end
    end
  end
end
