module RailsTemplate18f
  module Specs
    module Generators
      module Macros
        def destination_path
          File.expand_path("../../tmp", __dir__)
        end

        def setup_default_destination
          destination destination_path
          before {
            prepare_destination
            generate_base_app
          }
        end
      end

      def generate_base_app
        `rails new tmp --template=spec/support/test_app_template.rb --minimal --skip-active-record --skip-test --skip-git --skip-bundle`
      end

      def self.included(klass)
        klass.extend(Macros)
      end
    end
  end
end

RSpec.configure do |config|
  config.include RailsTemplate18f::Specs::Generators, type: :generator
end
