# frozen_string_literal: true

module RuboCop
  module Cop
    module ErbLint
      class AutoCorrectCop < Cop
        MSG = 'An arbitrary rule has been violated.'

        def on_send(node)
          add_offense(node, location: :selector) if node.command?(:banned_method)
        end
        alias_method :on_csend, :on_send

        def autocorrect(node)
          lambda do |corrector|
            corrector.replace(node.loc.selector, 'safe_method')
          end
        end
      end
    end
  end
end
