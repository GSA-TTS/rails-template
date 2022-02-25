# frozen_string_literal: true

require "rails/generators"

module RailsTemplate18f
  module Generators
    class I18nGenerator < ::Rails::Generators::Base
      include Base

      class_option :languages, default: "es,fr,zh", desc: "Comma separated list of supported language short codes"

      desc <<~DESC
        Description:
          Install translation framework and configuration for given languages.
          Always installs configuration for English
      DESC

      def install_gem
        return if gem_installed?("i18n-tasks")
        gem_group :development, :test do
          gem "i18n-tasks", "~> 0.9"
        end
      end

      def install_helper_tasks
        bundle_install do
          run "cp $(i18n-tasks gem-path)/templates/config/i18n-tasks.yml config/"
          run "cp $(i18n-tasks gem-path)/templates/rspec/i18n_spec.rb spec/"
        end
        insert_into_file "config/i18n-tasks.yml", "\n#{indent("- app/assets/builds", 4)}", after: "exclude:"
        uncomment_lines "config/i18n-tasks.yml", "ignore_missing:"
        insert_into_file "config/i18n-tasks.yml", indent(<<~EOM), after: "ignore_missing:\n"
          - 'shared.languages.*'
          - 'shared.header.{title,close,demo_banner,menu}'
        EOM
      end

      def install_translations
        inside "config/locales" do
          template "en.yml"
          languages.each do |lang|
            copy_file "#{lang}.yml"
          end
        end
      end

      def configure_i18n
        application "config.i18n.fallbacks = [:en]"
        available_regex = /^(\s*config.i18n.available_locales).*$/
        if file_content("config/application.rb").match?(available_regex)
          gsub_file "config/application.rb", available_regex, "\\1 = #{supported_languages}"
        else
          application "config.i18n.available_locales = #{supported_languages}"
        end
      end

      def install_nav_helper
        inject_into_module "app/helpers/application_helper.rb", "ApplicationHelper", indent(<<~'EOH')
          def format_active_locale(locale_string)
            link_classes = "usa-nav__link"
            if locale_string.to_sym == I18n.locale
              link_classes = "#{link_classes} usa-current"
            end
            link_to t("shared.languages.#{locale_string}"), root_path(locale: locale_string), class: link_classes
          end
        EOH
      end

      def install_around_action
        return if languages.empty?
        inject_into_class "app/controllers/application_controller.rb", "ApplicationController", indent(<<~EOM)
          around_action :switch_locale

          def switch_locale(&action)
            locale = params[:locale] || I18n.default_locale
            I18n.with_locale(locale, &action)
          end
        EOM
      end

      def install_route
        return if languages.empty?
        return if file_content("config/routes.rb").match?(/scope "\(:locale\)"/)
        regex = /(^.+\.routes\.draw do\s*$)\n(.*)^end$/m
        gsub_file "config/routes.rb", regex, <<~'EOR'
          \1
            scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do
              # Your application routes go here
              \2
            end
          end
        EOR
      end

      private

      def supported_languages
        @supported_languages ||= [:en, *languages]
      end

      def languages
        @languages ||= options[:languages].split(",").map(&:to_sym)
      end
    end
  end
end
