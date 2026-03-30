# frozen_string_literal: true

require "better_html"
require "ripper"
require "tempfile"

module ERBLint
  module Linters
    # Run selected rubocop cops on Ruby code
    class Rubocop < Linter
      include LinterRegistry

      class ConfigSchema < LinterConfig
        property :only, accepts: array_of?(String)
        property :rubocop_config, accepts: Hash, default: -> { {} }
        property :config_file_path, accepts: String
      end

      self.config_schema = ConfigSchema

      SUFFIX_EXPR = /[[:blank:]]*\Z/
      # copied from Rails: action_view/template/handlers/erb/erubi.rb
      BLOCK_EXPR = /\s*((\s+|\))do|\{)(\s*\|[^|]*\|)?\s*\Z/

      def initialize(file_loader, config)
        super
        @only_cops = @config.only
        custom_config = config_from_path(@config.config_file_path) if @config.config_file_path
        custom_config ||= config_from_hash(@config.rubocop_config)
        @rubocop_config = ::RuboCop::ConfigLoader.merge_with_default(custom_config, "")
        @rubocop_target_ruby_version = @rubocop_config.target_ruby_version
        @rubocop_version_gte_138 = ::RuboCop::Version::STRING.to_f >= 1.38
        @rubocop_global_registry = RuboCop::Cop::Registry.global if @rubocop_version_gte_138
        @cop_classes = build_cop_classes
        @team = build_team
      end

      def run(processed_source)
        snippets = prepare_snippets(processed_source)
        return if snippets.empty?

        if snippets.size == 1
          run_single_snippet(processed_source, snippets[0])
        else
          run_batched_snippets(processed_source, snippets)
        end
      end

      def autocorrect(_processed_source, offense)
        return unless offense.context

        rubocop_correction = offense.context[:rubocop_correction]
        return unless rubocop_correction

        lambda do |corrector|
          corrector.import!(rubocop_correction, offset: offense.context[:offset])
        end
      end

      private

      def run_single_snippet(processed_source, snippet)
        source = rubocop_processed_source(snippet[:aligned_source], processed_source.filename)
        return unless source.valid_syntax?

        activate_team(processed_source, source, snippet[:offset], snippet[:code_node], @team)
      end

      def run_batched_snippets(processed_source, snippets)
        source, snippets_with_offsets = build_combined_source(snippets, processed_source.filename)
        if source&.valid_syntax?
          investigate_batched(processed_source, source, snippets_with_offsets)
          return
        end

        # Combined source invalid — filter and retry
        valid_snippets = snippets.select do |snippet|
          rubocop_processed_source(snippet[:aligned_source], processed_source.filename).valid_syntax?
        end
        return if valid_snippets.empty?

        if valid_snippets.size > 1
          source, snippets_with_offsets = build_combined_source(valid_snippets, processed_source.filename)
          if source&.valid_syntax?
            investigate_batched(processed_source, source, snippets_with_offsets)
            return
          end
        end

        # Final fallback: per-snippet investigation
        valid_snippets.each do |snippet|
          run_single_snippet(processed_source, snippet)
        end
      end

      def build_combined_source(snippets, filename)
        byte_offset = 0
        combined_parts = []

        snippets.each do |snippet|
          snippet[:byte_start] = byte_offset
          combined_parts << snippet[:aligned_source]
          byte_offset += snippet[:aligned_source].bytesize + 1
        end

        source = rubocop_processed_source(combined_parts.join("\n"), filename)
        [source, snippets]
      end

      def descendant_nodes(processed_source)
        processed_source.ast.descendants(:erb)
      end

      def prepare_snippets(processed_source)
        snippets = []
        descendant_nodes(processed_source).each do |erb_node|
          indicator, _, code_node, = *erb_node
          next if indicator&.children&.first == "#"

          original_source = code_node.loc.source
          trimmed_source = original_source.sub(BLOCK_EXPR, "").sub(SUFFIX_EXPR, "")
          alignment_column = code_node.loc.column
          offset = code_node.loc.begin_pos - alignment_column
          aligned_source = "#{" " * alignment_column}#{trimmed_source}"

          # Fast syntax pre-filter using Ripper (rejects ~38% of snippets quickly)
          next unless Ripper.sexp(aligned_source)

          snippets << {
            code_node: code_node,
            aligned_source: aligned_source,
            offset: offset,
          }
        end
        snippets
      end

      def find_snippet_for_byte_pos(snippets, byte_pos)
        # Binary search for the snippet containing this byte position
        lo = 0
        hi = snippets.size - 1
        while lo <= hi
          mid = (lo + hi) / 2
          snippet_start = snippets[mid][:byte_start]
          snippet_end = snippet_start + snippets[mid][:aligned_source].bytesize
          if byte_pos < snippet_start
            hi = mid - 1
          elsif byte_pos >= snippet_end
            lo = mid + 1
          else
            return snippets[mid]
          end
        end
        nil
      end

      def investigate_batched(processed_source, source, snippets)
        report = @team.investigate(source)
        report.offenses.each do |rubocop_offense|
          next if rubocop_offense.disabled?

          offense_byte_pos = rubocop_offense.location.begin_pos
          snippet = find_snippet_for_byte_pos(snippets, offense_byte_pos)
          next unless snippet

          begin_in_snippet = rubocop_offense.location.begin_pos - snippet[:byte_start]
          end_in_snippet = rubocop_offense.location.end_pos - snippet[:byte_start]

          correction = rubocop_offense.corrector if rubocop_offense.corrected?

          offense_range = processed_source
            .to_source_range(begin_in_snippet...end_in_snippet)
            .offset(snippet[:offset])

          # Correction positions are in combined-source space; adjust offset so
          # import! maps them back through snippet-space to ERB-source space.
          correction_offset = snippet[:offset] - snippet[:byte_start]
          add_offense(rubocop_offense, offense_range, correction, correction_offset, snippet[:code_node].loc.range)
        end
      end

      def activate_team(processed_source, source, offset, code_node, team)
        report = team.investigate(source)
        report.offenses.each do |rubocop_offense|
          next if rubocop_offense.disabled?

          correction = rubocop_offense.corrector if rubocop_offense.corrected?

          offense_range = processed_source
            .to_source_range(rubocop_offense.location)
            .offset(offset)

          add_offense(rubocop_offense, offense_range, correction, offset, code_node.loc.range)
        end
      end

      def tempfile_from(filename, content)
        Tempfile.create(File.basename(filename), Dir.pwd) do |tempfile|
          tempfile.write(content)
          tempfile.rewind

          yield(tempfile)
        end
      end

      def rubocop_processed_source(content, filename)
        source = ::RuboCop::ProcessedSource.new(
          content,
          @rubocop_target_ruby_version,
          filename,
        )
        if @rubocop_version_gte_138
          source.registry = @rubocop_global_registry
          source.config = @rubocop_config
        end
        source
      end

      def build_cop_classes
        all_cops = if @only_cops.present?
          ::RuboCop::Cop::Registry.all.select { |cop| cop.match?(@only_cops) }
        else
          ::RuboCop::Cop::Registry.all
        end

        # Filter to only cops that are enabled in the merged config
        enabled_cops = all_cops.select do |cop|
          @rubocop_config.for_cop(cop).fetch("Enabled") { true } != false
        end

        ::RuboCop::Cop::Registry.new(enabled_cops)
      end

      def build_team
        ::RuboCop::Cop::Team.mobilize(
          @cop_classes,
          @rubocop_config,
          extra_details: true,
          display_cop_names: true,
          autocorrect: true,
          auto_correct: true,
          stdin: "",
        )
      end

      def config_from_hash(hash)
        tempfile_from(".erblint-rubocop", hash.to_yaml) do |tempfile|
          config_from_path(tempfile.path)
        end
      end

      def config_from_path(path)
        ::RuboCop::ConfigLoader.load_file(path)
      end

      def add_offense(rubocop_offense, offense_range, correction, offset, bound_range)
        context = if rubocop_offense.corrected?
          { rubocop_correction: correction, offset: offset, bound_range: bound_range }
        end

        super(offense_range, rubocop_offense.message.strip, context, rubocop_offense.severity.name)
      end
    end
  end
end
