# frozen_string_literal: true

require "rails/generators"

module RailsTemplate18f
  module Generators
    class I18nJsGenerator < ::Rails::Generators::Base
      include Base

      desc <<~DESC
        Description:
          Install and configure i18n-js gem to provide translations to JS code.

          By default, will only export translations with keys that match `*.js.*`

          To use, add the following to your js code:

          1. `import { i18n } from './i18n';`
          2. `i18n.t('path.to.translation.key')`
      DESC

      def install_gems
        gem "i18n-js", "~> 4.2" unless gem_installed?("i18n-js")
        gem "listen", "~> 3.9", group: :development unless gem_installed?("listen")
        bundle_install do
          run "yarn add i18n-js"
        end
      end

      def configure_translation_yaml
        copy_file "config/i18n-js.yml"
      end

      def configure_asset_pipeline
        copy_file "lib/tasks/i18n.rake"
        copy_file "config/initializers/i18n_js.rb"
        copy_file "app/javascript/i18n/index.js"
      end

      def ignore_generated_file
        unless skip_git?
          append_to_file ".gitignore", <<~EOM

            # Generated by i18n-js
            /app/javascript/i18n/translations.json
          EOM
        end
      end
    end
  end
end
