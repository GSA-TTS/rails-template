# frozen_string_literal: true

require "rails/generators"

module RailsTemplate18f
  module Generators
    class NewrelicGenerator < ::Rails::Generators::Base
      include Base

      desc <<~DESC
        Description:
          Install NewRelic config for FedRAMP collection
      DESC

      def update_content_security_policy
        csp_file = "config/initializers/content_security_policy.rb"
        gsub_file csp_file, /(policy.script_src .*)$/, '\1, "https://js-agent.newrelic.com", "https://*.nr-data.net"'
        if file_content(csp_file).match?(/policy.connect_src/)
          gsub_file csp_file, /(policy.connect_src .*)$/, '\1, "https://*.nr-data.net"'
        else
          gsub_file csp_file, /((#?)(\s+)policy.script_src .*)$/, "\\1\n\\2\\3policy.connect_src :self, \"https://*.nr-data.net\""
        end
      end

      def install_gem
        gem "newrelic_rpm", "~> 8.4"
      end

      def install_config
        template "config/newrelic.yml"
      end

      def update_cloud_gov_manifest
        insert_into_file "manifest.yml", "    NEW_RELIC_LOG: stdout\n", before: /^\s+processes:/
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
    System_Ext(newrelic, "New Relic", "Monitoring SaaS")
EOB
        insert_into_file boundary_filename, <<~EOB, before: "@enduml"
          Rel(app, newrelic, "reports telemetry (ruby agent)", "tcp (443)")
          Rel(browser, newrelic, "reports ux metrics (javascript agent)", "https (443)")
          Rel(developer, newrelic, "Manage performance", "https (443)")
        EOB
      end

      no_tasks do
        def readme
          <<~EOM
            ## Monitoring with New Relic

            The [New Relic Ruby agent](https://docs.newrelic.com/docs/apm/agents/ruby-agent/getting-started/introduction-new-relic-ruby) has been installed for monitoring this application.

            The config lives at `config/newrelic.yml`, and points to a [FEDRAMP version of the New Relic service as its host](https://docs.newrelic.com/docs/security/security-privacy/compliance/fedramp-compliant-endpoints/). To access the metrics dashboard, you will need to be connected to VPN.

            ### Getting started

            To get started sending metrics via New Relic APM:
            1. Add your New Relic license key to the Rails credentials with key `new_relic_key`.
            1. Optionally, update `app_name` entries in `config/newrelic.yml` with what is registered for your application in New Relic
            1. Comment out the `agent_enabled: false` line in `config/newrelic.yml`
            1. Add the [Javascript snippet provided by New Relic](https://docs.newrelic.com/docs/browser/browser-monitoring/installation/install-browser-monitoring-agent) into `application.html.erb`. It is recommended to vary this based on environment (i.e. include one snippet for staging and another for production).
          EOM
        end
      end
    end
  end
end
