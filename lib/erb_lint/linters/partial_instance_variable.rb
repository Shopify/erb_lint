# frozen_string_literal: true

module ERBLint
  module Linters
    # Checks for instance variables in partials only
    class PartialInstanceVariable < InstanceVariable
      self.config_schema = ConfigSchema

      def initialize(file_loader, config)
        warn(
          "PartialInstanceVariable is deprecated. "\
          "Please use InstanceVariable with partials_only=true."
        )
        config[:partials_only] = true
        super(file_loader, config)
      end

      private

      def offense_message
        "Instance variable detected in partial."
      end
    end
  end
end
