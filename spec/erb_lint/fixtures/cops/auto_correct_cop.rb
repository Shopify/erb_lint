# frozen_string_literal: true

module RuboCop
  module Cop
    module ErbLint
      class AutoCorrectCop < Cop
        MSG = 'An arbitrary rule has been violated.'
        METHODS_TO_WATCH = %i(auto_correct_me dont_auto_correct_me)

        def on_send(node)
          return unless METHODS_TO_WATCH.include?(node.method_name)

          add_offense(node, location: :selector)
        end
        alias_method :on_csend, :on_send

        def autocorrect(node)
          lambda do |corrector|
            corrector.replace(node.loc.selector, 'safe_method') if node.method_name == :auto_correct_me
          end
        end
      end
    end
  end
end
