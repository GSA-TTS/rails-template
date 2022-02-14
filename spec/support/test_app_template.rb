# This template is used by spec/support/generators to create files that
# the generators expect to be present.

def source_paths
  ["#{__dir__}/../../templates"]
end

template "README.md", force: true
template "doc/compliance/apps/application.boundary.md"
