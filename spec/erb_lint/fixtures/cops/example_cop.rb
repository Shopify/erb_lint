# frozen_string_literal: true

module RuboCop
  module Cop
    module ErbLint
      class ArbitraryRule < Cop
        MSG = 'An arbitrary rule has been violated.'

        def on_send(node)
          add_offense(node, location: :expression) if node.command?(:banned_method)
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end
