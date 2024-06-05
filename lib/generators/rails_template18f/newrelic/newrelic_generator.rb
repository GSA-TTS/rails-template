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
        return if gem_installed?("newrelic_rpm")
        gem "newrelic_rpm", "~> 9.10"
        bundle_install
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

      def update_oscal_doc
        if oscal_dir_exists?
          insert_into_oscal "si-4.md", <<~EOS, after: "## Implementation a.\n"
            New Relic is used for the purposes of monitoring and analyzing #{app_name} application data. New Relic monitors each application within #{app_name} for
            basic container utilization (CPU, memory, disk) as a baseline of provided metrics. New Relic dashboards are used by #{app_name} operations to obtain
            near real-time views into the metrics obtained from each application. New Relic provides application metrics that give insight into request/response rates,
            failure rates, etc. New Relic uses this data to detect anomalies (such as potential unauthorized activity) and alerts the #{app_name} team via <<INSERT NOTIFICATION CHANNEL>>
            in the GSA Slack. Example: a spike in failed requests may indicate an unauthorized user has entered the system and is attempting to phish for PII.

            1. A subset of relevant specific metrics #{app_name} is constantly monitoring include:
              * Abnormal cpu, memory, and disk utilization (defined in New Relic alerting rules)
              * Number of incoming requests
              * Request response time
              * Application crashes (for any reason)
              * Response status codes (high numbers of failing requests would be abnormal)
              * Applications (by name)
              * Abnormally high request rates
            1. Metrics that can be audited within #{app_name} include:
              * SSH Sessions (disabled in production under normal circumstances)
            1. A subset of relevant incidents #{app_name} will use these metrics to protect against include:
              * Unauthorized Access / Intrusion to #{app_name} as an Administrator
              * Denial of Service (DoS)
              * Improper Usage
              * Malicious Code
              * System Uptime
              * High Resource Usage

            When suspicious activity is encountered #{app_name} Operations audit the event through the cloud.gov logs provided at logs.fr.cloud.gov
            (a Kibana instance allowing users to access, filter, and search their cloud.gov logs. These logs are retained automatically by cloud.gov for 180 days after creation.
          EOS
          insert_into_oscal "si-4.md", "The #{app_name} application logs events to stdout and stderr which are ingested by cloud.gov and New Relic.", after: "## Implementation c.\n"
          insert_into_oscal "si-4.md", "#{app_name} Operations are responsible for monitoring the New Relic dashboards that report on specific application events and performing follow-up investigations where necessary.", after: "## Implementation d.\n"
          insert_into_oscal "si-4.2.md", <<~EOS
            #{app_name} is monitored using New Relic Application Performance Monitoring (APM),
            Synthetics and Logs, which detects and alerts on abnormal responses from #{app_name} applications.
          EOS
        end
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
