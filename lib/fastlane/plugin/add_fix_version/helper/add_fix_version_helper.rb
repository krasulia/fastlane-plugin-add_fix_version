require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class AddFixVersionHelper
      # class methods that you define here become available in your action
      # as `Helper::AddFixVersionHelper.your_method`
      #
      def self.show_message
        UI.message("Hello from the add_fix_version plugin helper!")
      end
    end
  end
end
