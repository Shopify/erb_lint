# frozen_string_literal: true

require 'spec_helper'
require 'erb_lint/cli'
require 'pp'
require 'fakefs'
require 'fakefs/spec_helpers'

describe ERBLint::CLI do
  include FakeFS::SpecHelpers

  let(:args) { [] }
  let(:cli) { described_class.new(args) }

  around do |example|
    FakeFS do
      example.run
    end
  end

  before do
    allow(ERBLint::LinterRegistry).to(receive(:linters)
      .and_return([ERBLint::Linters::LinterWithErrors,
                   ERBLint::Linters::LinterWithoutErrors,
                   ERBLint::Linters::FinalNewline]))
  end

  module ERBLint
    module Linters
      class LinterWithErrors < Linter
        def run(processed_source)
          add_offense(
            processed_source.to_source_range(1..1),
            'fake message from a fake linter'
          )
        end
      end

      class LinterWithoutErrors < Linter
        def run(_processed_source)
        end
      end
    end
  end

  describe '#run' do
    subject { cli.run }

    context 'with no arguments' do
      it 'shows usage' do
        expect { subject }.to(output(/erblint \[options\] \[file1, file2, ...\]/).to_stdout)
      end

      it 'shows all known linters' do
        expect { subject }.to(output(
          /Known linters are: linter_with_errors, linter_without_errors, final_newline/
        ).to_stdout)
      end

      it 'is successful' do
        expect(subject).to(eq(ERBLint::CLI::STATUS_SUCCESS))
      end
    end

    context 'with --format' do
      context 'when missing argument format' do
        let(:args) { ['--format'] }
        it { expect { subject }.to(output(/missing argument: --format/).to_stderr) }
      end

      context 'when format is empty' do
        let(:args) { ['--format='] }
        it { expect { subject }.to(output(/empty format is not a valid format/).to_stderr) }
      end

      context 'when format value does not exists' do
        let(:args) { ['--format=idonotexists'] }
        it { expect { subject }.to(output(/idonotexists format is not a valid format/).to_stderr) }
      end

      it 'is successful' do
        expect(subject).to(eq(ERBLint::CLI::STATUS_SUCCESS))
      end
    end

    context 'with --version' do
      let(:args) { ['--version'] }
      it { expect { subject }.to(output("#{ERBLint::VERSION}\n").to_stdout) }
    end

    context 'with --help' do
      let(:args) { ['--help'] }

      it 'shows usage' do
        expect { subject }.to(output(/erblint \[options\] \[file1, file2, ...\]/).to_stdout)
      end
      it 'is successful' do
        expect(subject).to(eq(ERBLint::CLI::STATUS_SUCCESS))
      end
    end

    context 'with --config' do
      context 'when file does not exist' do
        let(:args) { ['--config', '.somefile.yml'] }

        it { expect { subject }.to(output(/.somefile.yml: does not exist/).to_stderr) }
        it 'is not successful' do
          expect(subject).to(eq(ERBLint::CLI::STATUS_ERROR))
        end
      end
    end

    context 'with file as argument' do
      context 'when file does not exist' do
        let(:linted_file) { '/path/to/myfile.html.erb' }
        let(:args) { [linted_file] }

        it { expect { subject }.to(output(/#{Regexp.escape(linted_file)}: does not exist/).to_stderr) }
        it { expect(subject).to(eq(ERBLint::CLI::STATUS_ERROR)) }
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
            it { expect { subject }.to(output(/\.erb-lint\.yml not found: using default config/).to_stderr) }
          end
        end

        it 'shows how many files and linters are used' do
          expect { subject }.to(output(/Linting 1 files with 2 linters/).to_stdout)
        end

        context 'when errors are found' do
          context 'with default format' do
            it 'shows all error messages and line numbers' do
              expect { subject }.to(output(Regexp.new(Regexp.escape(<<~EOF))).to_stdout)
                fake message from a fake linter
                In file: /app/views/template.html.erb:1

                Missing a trailing newline at the end of the file.
                In file: /app/views/template.html.erb:1
              EOF
            end

            it 'prints that errors were found to stdout' do
              expect { subject }.to(output(/2 error\(s\) were found in ERB files/).to_stdout)
            end

            it 'is not successful' do
              expect(subject).to(eq(ERBLint::CLI::STATUS_OFFENSES))
            end
          end

          context 'with --format=json' do
            let(:args) { ['--enable-linter', 'linter_with_errors,final_newline', linted_file, '--format=json'] }
            it 'return positive offense count' do
              expect { subject }.to(output(/"offense_count": 2/).to_stdout)
            end

            it 'is not successful' do
              expect(subject).to(eq(ERBLint::CLI::STATUS_OFFENSES))
            end
          end
        end

        context 'when no errors are found' do
          context 'with default format' do
            let(:args) { ['--enable-linter', 'linter_without_errors', linted_file] }

            it 'shows no that errors were found to stdout' do
              expect { subject }.to(output(/No errors were found in ERB files/).to_stdout)
            end

            it 'is successful' do
              expect(subject).to(eq(ERBLint::CLI::STATUS_SUCCESS))
            end
          end

          context 'with --format=json' do
            let(:args) { ['--enable-linter', 'linter_without_errors', linted_file, '--format=json'] }
            it 'return negative offense count' do
              expect { subject }.to(output(/"offense_count": 0/).to_stdout)
            end

            it 'is successful' do
              expect(subject).to(eq(ERBLint::CLI::STATUS_SUCCESS))
            end
          end
        end
      end
    end

    context 'with dir as argument' do
      context 'when dir does not exist' do
        let(:linted_dir) { '/path/to' }
        let(:args) { [linted_dir] }

        it { expect { subject }.to(output(/#{Regexp.escape(linted_dir)}: does not exist/).to_stderr) }
        it { expect(subject).to(eq(ERBLint::CLI::STATUS_ERROR)) }
      end

      context 'when dir exists' do
        let(:linted_dir) { 'app' }

        context 'with no descendant files that match default glob' do
          let(:args) { ['--enable-linter', 'linter_with_errors,final_newline', linted_dir] }

          before do
            FileUtils.mkdir_p(linted_dir)
          end

          it { expect { subject }.to(output(/no files found/).to_stdout) }
        end

        context 'with descendant files that match default glob' do
          let(:linted_file) { 'app/views/template.html.erb' }
          let(:args) { ['--enable-linter', 'linter_with_errors,final_newline', linted_dir] }
          let(:file_content) { "this is a fine file" }

          before do
            FileUtils.mkdir_p(File.dirname(linted_file))
            File.write(linted_file, file_content)
          end

          context 'without --config' do
            context 'when default config does not exist' do
              it { expect { subject }.to(output(/\.erb-lint\.yml not found: using default config/).to_stderr) }
            end
          end

          it 'shows how many files and linters are used' do
            expect { subject }.to(output(/Linting 1 files with 2 linters/).to_stdout)
          end

          context 'when errors are found' do
            it 'shows all error messages and line numbers' do
              expect { subject }.to(output(Regexp.new(Regexp.escape(<<~EOF))).to_stdout)
                fake message from a fake linter
                In file: /app/views/template.html.erb:1

                Missing a trailing newline at the end of the file.
                In file: /app/views/template.html.erb:1
              EOF
            end

            it 'prints that errors were found to stdout' do
              expect { subject }.to(output(/2 error\(s\) were found in ERB files/).to_stdout)
            end

            it 'is not successful' do
              expect(subject).to(eq(ERBLint::CLI::STATUS_OFFENSES))
            end
          end

          context 'when no errors are found' do
            let(:args) { ['--enable-linter', 'linter_without_errors', linted_dir] }

            it 'shows no that errors were found to stderr' do
              expect { subject }.to(output(/No errors were found in ERB files/).to_stdout)
            end

            it 'is successful' do
              expect(subject).to(eq(ERBLint::CLI::STATUS_SUCCESS))
            end
          end
        end
      end
    end

    context 'with unknown argument' do
      let(:args) { ['--foo'] }

      it { expect { subject }.to(output(/invalid option: --foo/).to_stderr) }

      it 'is not successful' do
        expect(subject).to(eq(ERBLint::CLI::STATUS_ERROR))
      end
    end

    context 'with invalid --enable-linters argument' do
      let(:args) { ['--enable-linter', 'foo'] }

      it do
        expect { subject }.to(output(
          /foo: not a valid linter name \(linter_with_errors, linter_without_errors, final_newline\)/
        ).to_stderr)
      end

      it 'is not successful' do
        expect(subject).to(eq(ERBLint::CLI::STATUS_ERROR))
      end
    end
  end
end
