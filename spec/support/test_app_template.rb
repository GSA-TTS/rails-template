# This template is used by spec/support/generators to create files that
# the generators expect to be present.

def source_paths
  [
    "#{__dir__}/../../templates",
    "#{__dir__}/../../lib/generators/rails_template18f/terraform/templates"
  ]
end

def skip_active_job?
  false
end

def skip_active_storage?
  true
end

template "README.md", force: true
copy_file "env", ".env"
template "manifest.yml"
directory "doc"
copy_file "githooks/pre-commit", ".githooks/pre-commit", mode: :preserve
run "mkdir spec"
directory "config/deployment"
create_file "Procfile.dev", "web: rails server\n"
