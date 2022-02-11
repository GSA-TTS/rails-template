# This template is used by spec/support/generators to create files that
# the generators expect to be present. Currently, that is just
# The format of the README

def source_paths
  ["#{__dir__}/../../templates"]
end

## Start of app customizations
template "README.md", force: true
