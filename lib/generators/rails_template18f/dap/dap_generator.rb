# frozen_string_literal: true

require "rails/generators"

module RailsTemplate18f
  module Generators
    class DapGenerator < ::Rails::Generators::Base
      include Base

      class_option :agency_code, default: "GSA", desc: "Agency code to track DAP metrics"

      desc <<~DESC
        Description:
          Install JS snippet for Digital Analytics Program (DAP)
      DESC

      def update_content_security_policy
        csp_file = "config/initializers/content_security_policy.rb"
        gsub_file csp_file, /(policy.img_src .*)$/, '\1, "https://www.google-analytics.com"'
        gsub_file csp_file, /(policy.script_src .*)$/, '\1, "https://dap.digitalgov.gov", "https://www.google-analytics.com"'
        if file_content(csp_file).match?(/policy.connect_src/)
          gsub_file csp_file, /(policy.connect_src .*)$/, '\1, "https://dap.digitalgov.gov", "https://www.google-analytics.com"'
        else
          gsub_file csp_file, /((#?)(\s+)policy.script_src .*)$/, "\\1\n\\2\\3policy.connect_src :self, \"https://dap.digitalgov.gov\", \"https://www.google-analytics.com\""
        end
      end

      def install_js_snippet
        insert_into_file "app/views/layouts/application.html.erb", <<EODAP, before: /^\s+<\/head>/

    <% if Rails.env.production? %>
      <!-- We participate in the US government's analytics program. See the data at analytics.usa.gov. -->
      <%= javascript_include_tag "https://dap.digitalgov.gov/Universal-Federated-Analytics-Min.js?agency=#{options[:agency_code]}", async: true, id:"_fed_an_ua_tag" %>
    <% end %>
EODAP
      end

      def update_readme
        insertion_regex = /^## Documentation$/
        if file_content("README.md").match?(insertion_regex)
          insert_into_file "README.md", readme, before: insertion_regex
        else
          append_to_file "README.md", readme
        end
      end

      def update_boundary_diagram
        boundary_filename = "doc/compliance/apps/application.boundary.md"
        insert_into_file boundary_filename, <<EOB, after: "Boundary(gsa_saas, \"GSA-authorized SaaS\") {\n"
    System_Ext(dap, "DAP", "Analytics collection")
EOB
        insert_into_file boundary_filename, <<~EOB, before: "@enduml"
          Rel(browser, dap, "reports usage", "https (443)")
          Rel(developer, dap, "View traffic statistics", "https GET (443)")
        EOB
      end

      no_tasks do
        def readme
          <<~EOM
            ## Analytics

            Digital Analytics Program (DAP) code has been included for the Production environment, associated with #{options[:agency_code]}.

            If #{app_name.titleize} is for another agency, update the agency line in `app/views/layouts/application.html.erb`

          EOM
        end
      end
    end
  end
end
