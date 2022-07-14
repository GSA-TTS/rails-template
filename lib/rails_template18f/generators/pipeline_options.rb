# frozen_string_literal: true

module RailsTemplate18f
  module Generators
    module PipelineOptions
      extend ActiveSupport::Concern
      include CloudGovOptions

      included do
        class_option :terraform, type: :boolean, desc: "Generate actions for planning and applying terraform"
      end

      def terraform?
        options[:terraform].nil? ? terraform_dir_exists? : options[:terraform]
      end

      def update_cicd_oscal_docs(ci_name)
        if oscal_dir_exists?
          update_ca7_oscal_doc
          update_cm2_oscal_doc(ci_name)
          update_cm3_oscal_doc(ci_name)
          update_ra5_oscal_doc
          update_sa11_oscal_doc(ci_name)
          update_sa22_oscal_doc
          update_sc281_oscal_doc(ci_name)
          update_si2_oscal_doc
          update_si10_oscal_doc
          update_sr3_oscal_doc(ci_name)
        end
      end

      private

      def update_ca7_oscal_doc
        insert_into_oscal "ca-7.md", <<~EOS, after: "## Implementation a.\n"
          * #{app_name} DevOps staff review OWASP and Dependency scans every build, or at least weekly.
          * #{app_name} DevOps staff and the GSA ISSO review Web Application vulnerability scans on a weekly basis.
          * #{app_name} Administrators and DevOps staff review changes for potential security impact and engage the #{app_name} ISSO and ISSM who will review or engage assessment staff as needed.
        EOS
      end

      def update_cm2_oscal_doc(ci)
        insert_into_oscal "cm-2.2.md", <<~EOS
          The #{app_name} team develops, documents, and maintains a current baseline for the #{app_name} application
          components under configuration control, managed via git and github.com, and orchestrated using #{ci}
          and the cloud.gov Cloud Foundry CLI.

          Note: All cloud.gov brokered services (including databases) are fully managed by the cloud.gov platform.
          Due to this, the configuration and security of these services are not included in the #{app_name} configuration baseline.
        EOS
      end

      def update_cm3_oscal_doc(ci)
        insert_into_oscal "cm-3.1.md", <<~EOS, after: "## Implementation (f)\n"
          #{app_name} employs #{ci} to execute proposed changes to the information system.
          #{app_name} Administrators and #{app_name} Developers are automatically notified of
          the success or failure of the change execution via the GitHub notification system.
        EOS
      end

      def update_ra5_oscal_doc
        insert_into_oscal "ra-5.md", <<~EOS, after: "## Implementation a.\n"
          Any vulnerabilities in #{app_name} would have to be introduced at time of deployment because #{app_name}
          is a set of cloud.gov managed applications with SSH disabled in Production. #{app_name} monitors for
          vulnerabilities by ensuring that scans for vulnerabilities in the information system and hosted applications occur
          daily and when new code is deployed.

          OWASP ZAP scans are built into the #{app_name} CI/CD pipeline and runs a series of web vulnerability scans before
          a successful deploy can be made to cloud.gov. Any issues or alerts caused by the scan are documented by #{app_name}
          Operations and cause the deployment to fail. Issues are tracked in GitHub. The issue posted will provide information
          on which endpoints are vulnerable and the level of vulnerability, ranging from **False Positive** to **High**.
          The issue also provides a detailed report formatted in html, json, and markdown.

          #{app_name} Administrators are responsible for reporting any new vulnerabilities reported by the OWASP ZAP scan to the #{app_name} ISSO.
        EOS
        insert_into_oscal "ra-5.md", <<~EOS, after: "## Implementation b.\n"
          1. Alerts from each ZAP vulnerability scan are automatically reported in GitHub as an issue on the #{app_name} repository.
          This issue will enumerate each finding and detail the type and severity of the vulnerability. #{app_name} Developers and
          #{app_name} Administrators receive automated alerts via GitHub of the issues to remediate. Scan results are sent to the
          #{app_name} System Owner by #{app_name} Administrators. The vulnerabilities are analyzed and prioritized within GitHub
          based on input from the #{app_name} System Owner and ISSO.
          1. The ZAP report contains vulnerabilities grouped by type and by risk level. The report also provides a detailed report
          formatted in html, json, and markdown. The reported issues also include the CVE item associated with the vulnerability.
          1. Vulnerabilities are classified by ZAP under a level range from **False Positive** to **High**. The impact level is
          used to drive the priority of the effort to remediate.
        EOS
        insert_into_oscal "ra-5.md", <<~EOS, after: "## Implementation c.\n"
          The ZAP vulnerability report contains information about how the attack was made and suggested solutions for each vulnerability found.
          Any static code analysis findings identified during automation as part of the GitHub pull request process must be reviewed, analyzed,
          and resolved by the #{app_name} Developer before the team can merge the pull request.
        EOS
      end

      def update_sa11_oscal_doc(ci)
        insert_into_oscal "sa-11.md", <<~EOS, after: "## Implementation a.\n"
          The CI/CD pipeline utilizes multiple tools to perform static code analysis for security and privacy:

          * **Brakeman** is a static code scanner designed to find security issues in Ruby on Rails code. It can flag potential SQL injection,
          Command Injection, open redirects, and other common vulnerabilities.
          * **bundle-audit** checks Ruby dependencies against a database of known CVE numbers.
          * **yarn audit** checks Javascript dependencies against a database of known CVE numbers.
          * **OWASP ZAP** is a dynamic security scanner that can simulate actual attacks on a running server.

          An additional RAILS_ENV has been created called ci. It inherits from production to ensure that the system being tested is as close as possible to production while allowing for overrides such as bypassing authentication in a secure way.
        EOS
        insert_into_oscal "sa-11.md", <<~EOS, after: "## Implementation b.\n"
          #{ci} runs rspec tests for unit, integration, and regression testing at every code push to github.com and every Pull Request.
        EOS
        insert_into_oscal "sa-11.md", <<~EOS, after: "## Implementation c.\n"
          Test and scan results can be viewed from within #{ci} for every run of the pipeline.

          When #{ci} is run as a result of a Pull Request, the status of the tests and scans are automatically reported as part of the Pull Request.
        EOS
      end

      def update_sa22_oscal_doc
        insert_into_oscal "sa-22.md", <<~EOS, after: "## Implementation a.\n"
          The #{app_name} application is built and supported by the #{app_name} DevOps staff.

          #{app_name} utilizes public open source Ruby and NodeJS components.

          #{app_name} utilizes dependency scanning tools Bundle Audit and Yarn Audit to find vulnerable or insecure dependencies.

          If a vulnerable or insecure dependency is found it will be upgraded or replaced. Additionally the #{app_name} team code
          review processes include a review of the health (up to date, supported, many individuals involved) of direct open source dependencies.
        EOS
        insert_into_oscal "sa-22.md", <<~EOS, after: "## Implementation b.\n"
          There are currently no unsupported system components within #{app_name}. In case an unsupported system component is required
          to maintain #{app_name}, the #{app_name} System Owner will be consulted to make a determination in coordination with the #{app_name} ISSO and ISSM.
        EOS
      end

      def update_sc281_oscal_doc(ci)
        insert_into_oscal "sc-28.1.md", <<~EOS
          As an additional layer of protection, all PII data is encrypted using [Active Record Encryption — Ruby on Rails Guides](https://guides.rubyonrails.org/active_record_encryption.html).
          This encryption is implemented in a using non-deterministic AES-256-GCM through Ruby's openssl library with a 256-bit key and a random initialization vector {rails crypto module}.

          The Data Encryption Key is stored in the credentials.yml file in an encrypted format by Ruby's openssl library using the AES-128-GCM cipher,
          and is built into the application package.

          The credentials.yml decryption key is stored in #{ci} and injected into the running application as an environmental variable. The application then uses this key
          to decrypt the credentials.yml file and obtain the Data Encryption Key.

          A backup of the key is stored by the Lead Developer and System Owner within a keepass database stored in Google Drive.
        EOS
      end

      def update_si2_oscal_doc
        insert_into_oscal "si-2.md", <<~EOS, after: "Implementation a.\n"
          Flaw and vulnerability checks are built into the #{app_name} CI/CD pipeline and automated to ensure compliance.
          Dynamic vulnerability scans are performed against #{app_name} before a successful deployment and reports issues after every scan.
          Compliance is documented in sections SA-11 and RA-5. The #{app_name} DevOps team uses GitHub as the Product Backlog to
          track and prioritize issues related to system flaws.

          The responsibility of remediating flaws and vulnerabilities (once a remediation is available) falls on the #{app_name} Developer,
          who updates the #{app_name} code and deploys fixes as part of the normal development and CI/CD process.
        EOS
        insert_into_oscal "si-2.md", <<~EOS, after: "Implementation b.\n"
          Any flaws or vulnerabilities resolved in #{app_name} result in a GitHub issue for triage via the #{app_name} CM Configuration Control
          process described in CM-2(2). After resolving a vulnerability or flaw in #{app_name}, unit tests and integration tests are updated to
          prevent further inclusion of similar flaws.

          * All GitHub tickets have accompanying Acceptance Criteria that are used to create unit tests.
          * Unit tests are run on the Development environment when new code is pushed.
          * Integration tests are run on the Test environment when the remediation is deployed via the CI/CD process to ensure that the production
          environment does not suffer from any side effects of the vulnerability remediation.
          * Integration tests are run on the Prod environment when the remediation is deployed via the CI/CD process to validate the remediation and application functionality.
          * All findings that are not remediated immediately are tracked in the #{app_name} Plan of Action and Milestones (POAM) by #{app_name} Operations and the #{app_name} ISSO.
        EOS
      end

      def update_si10_oscal_doc
        insert_into_oscal "si-10.md", <<~EOS
          All inputs from the end user are parameterized prior to use to avoid potential sql injection.

          #{app_name} utilizes Brakeman scanner as part of the CI/CD pipeline which further identifies coding practices
          that may lead to application vulnerabilities that are a result of improper input validation.
        EOS
      end

      def update_sr3_oscal_doc(ci)
        insert_into_oscal "sr-3.md", <<~EOS, after: "Implementation b.\n"
          A complete Software Bill of Materials (SBOM) for all Ruby dependencies is automatically
          generated by #{ci} on each push to GitHub as well as on a nightly basis. These can be downloaded
          from the applicable artifact section for each CI job.
        EOS
      end
    end
  end
end
