# frozen_string_literal: true

require 'spec_helper'
require 'erb_lint/cli'
require 'pp'
require 'fakefs'
require 'fakefs/spec_helpers'

describe ERBLint::CLI do
  include FakeFS::SpecHelpers

  let(:args) { [] }
  let(:cli) { described_class.new }

  around do |example|
    FakeFS do
      example.run
    end
  end

  before do
    allow(ERBLint::LinterRegistry).to receive(:linters)
      .and_return([ERBLint::Linters::LinterWithErrors,
                   ERBLint::Linters::LinterWithoutErrors,
                   ERBLint::Linters::FinalNewline])
  end

  module ERBLint
    module Linters
      class LinterWithErrors < Linter
        def offenses(processed_source)
          [
            Offense.new(
              self,
              processed_source.to_source_range(1, 1),
              'fake message from a fake linter'
            )
          ]
        end
      end

      class LinterWithoutErrors < Linter
        def offenses(_processed_source)
          []
        end
      end
    end
  end

  describe '#run' do
    subject { cli.run(args) }

    context 'with no arguments' do
      it 'shows usage' do
        expect { subject }.to output(/erblint \[options\] \[file1, file2, ...\]/).to_stdout
      end

      it 'shows all known linters' do
        expect { subject }.to output(
          /Known linters are: linter_with_errors, linter_without_errors, final_newline/
        ).to_stdout
      end

      it 'is successful' do
        expect(subject).to be(true)
      end
    end

    context 'with --version' do
      let(:args) { ['--version'] }
      it { expect { subject }.to output("#{ERBLint::VERSION}\n").to_stdout }
    end

    context 'with --help' do
      let(:args) { ['--help'] }

      it 'shows usage' do
        expect { subject }.to output(/erblint \[options\] \[file1, file2, ...\]/).to_stdout
      end
      it 'is successful' do
        expect(subject).to be(true)
      end
    end

    context 'with --config' do
      context 'when file does not exist' do
        let(:args) { ['--config', '.somefile.yml'] }

        it { expect { subject }.to output(/.somefile.yml: does not exist/).to_stderr }
        it 'is not successful' do
          expect(subject).to be(false)
        end
      end
    end

    context 'with file as argument' do
      context 'when file does not exist' do
        let(:linted_file) { '/path/to/myfile.html.erb' }
        let(:args) { [linted_file] }

        it { expect { subject }.to output(/#{Regexp.escape(linted_file)}: does not exist/).to_stderr }
        it { expect(subject).to be(false) }
      end

      context 'when file exists' do
        let(:linted_file) { 'app/views/template.html.erb' }
        let(:args) { ['--enable-linter', 'linter_with_errors,final_newline', linted_file] }
        let(:file_content) { "this is a fine file" }

        before do
          FileUtils.mkdir_p(File.dirname(linted_file))
          File.write(linted_file, file_content)
        end

        context 'without --config' do
          context 'when default config does not exist' do
            it { expect { subject }.to output(/\.erb-lint\.yml not found: using default config/).to_stderr }
          end
        end

        it 'shows how many files and linters are used' do
          expect { subject }.to output(/Linting 1 files with 2 linters/).to_stdout
        end

        context 'when errors are found' do
          it 'shows all error messages and line numbers' do
            expect { subject }.to output(Regexp.new(Regexp.escape(<<~EOF))).to_stdout
              fake message from a fake linter
              In file: /app/views/template.html.erb:1

              Missing a trailing newline at the end of the file.
              In file: /app/views/template.html.erb:1
            EOF
          end

          it 'prints that errors were found to stdout' do
            expect { subject }.to output(/2 error\(s\) were found in ERB files/).to_stderr
          end

          it 'is not successful' do
            expect(subject).to be(false)
          end
        end

        context 'when no errors are found' do
          let(:args) { ['--enable-linter', 'linter_without_errors', linted_file] }

          it 'shows no that errors were found to stderr' do
            expect { subject }.to output(/No errors were found in ERB files/).to_stdout
          end

          it 'is successful' do
            expect(subject).to be(true)
          end
        end
      end
    end

    context 'with unknown argument' do
      let(:args) { ['--foo'] }

      it { expect { subject }.to output(/invalid option: --foo/).to_stderr }

      it 'is not successful' do
        expect(subject).to be(false)
      end
    end

    context 'with invalid --enable-linters argument' do
      let(:args) { ['--enable-linter', 'foo'] }

      it do
        expect { subject }.to output(
          /foo: not a valid linter name \(linter_with_errors, linter_without_errors, final_newline\)/
        ).to_stderr
      end

      it 'is not successful' do
        expect(subject).to be(false)
      end
    end
  end
end
