# This template is used by spec/support/generators to create files that
# the generators expect to be present.

def source_paths
  [
    "#{__dir__}/../../templates",
    "#{__dir__}/../../lib/generators/rails_template18f/terraform/templates",
    "#{__dir__}/templates"
  ]
end

def skip_active_storage?
  true
end

def cloud_gov_organization
  "sandbox-gsa"
end

def cloud_gov_staging_space
  "staging"
end

def cloud_gov_production_space
  "production"
end

def terraform_manage_spaces?
  true
end

def has_active_job?
  false
end

def has_active_storage?
  false
end

def use_gitlab_backend?
  false
end

def use_s3_backend?
  false
end

def use_local_backend?
  true
end

def backend_block
  ""
end

directory "terraform"

template "README.md", force: true
copy_file "Brewfile"
copy_file "env", ".env"
copy_file "config/environments/ci.rb"
directory "doc"
copy_file "githooks/pre-commit", ".githooks/pre-commit", mode: :preserve
run "mkdir spec"
create_file "Procfile.dev", "web: rails server\n"
