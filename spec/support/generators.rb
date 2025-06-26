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

        def setup_gitlab_ci_destination
          destination destination_path
          before {
            prepare_destination
            generate_gitlab_ci_app
          }
        end

        def setup_github_actions_destination
          destination destination_path
          before {
            prepare_destination
            generate_base_app
            system "mkdir", "-p", File.join(self.class.destination_path, ".github/workflows")
            system "touch", File.join(self.class.destination_path, ".github/workflows/deploy.yml")
            system "touch", File.join(self.class.destination_path, ".github/workflows/rspec.yml")
            system "mkdir", "-p", File.join(self.class.destination_path, "doc/compliance/oscal")
            system "touch", File.join(self.class.destination_path, "/doc/compliance/oscal/trestle-config.yaml")
          }
        end

        def setup_active_storage_destination
          destination destination_path
          before {
            prepare_destination
            generate_storage_app
            system "mkdir", "-p", File.join(self.class.destination_path, "doc/compliance/oscal")
            system "touch", File.join(self.class.destination_path, "/doc/compliance/oscal/trestle-config.yaml")
          }
        end
      end

      def self.included(klass)
        klass.extend(Macros)
      end

      def generate_base_app
        `rails new tmp --template=spec/support/test_app_template.rb #{common_arguments}`
      end

      def generate_gitlab_ci_app
        `rails new tmp --template=spec/support/test_gitlab_app_template.rb #{common_arguments}`
      end

      def generate_storage_app
        `rails new tmp --template=spec/support/test_app_template.rb --skip-test --skip-git --skip-bundle`
      end

      def common_arguments
        "--minimal --skip-active-record --skip-test --skip-git --skip-bundle --skip-rubocop --skip-ci --skip-thruster --skip-kamal --skip-solid"
      end
    end
  end
end

RSpec.configure do |config|
  config.include RailsTemplate18f::Specs::Generators, type: :generator
end
