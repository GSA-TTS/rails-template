# This template is used by spec/support/generators to create files that
# the generators expect to be present.

def source_paths
  [
    "#{__dir__}/../../templates",
    "#{__dir__}/../../lib/generators/rails_template18f/terraform/templates"
  ]
end

template "README.md", force: true
template "manifest.yml"
template "doc/compliance/apps/application.boundary.md"
copy_file "githooks/pre-commit", ".githooks/pre-commit", mode: :preserve
run "mkdir spec"
