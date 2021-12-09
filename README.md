18F-Flavored Rails Project
==========================

## Usage

`rails new <<PATH_TO_PROJECT>> --rc=railsrc`

**Important:** You must not pass `--skip-bundle` or `--skip-webpack-install` to `rails new` or various aspects of the template will be broken

### What railsrc does

```
--skip-active-storage   # don't include ActiveStorage for document upload
--skip-action-text      # don't include ActionText libraries for WYSIWYG editing
--skip-action-cable     # don't include ActionCable websocket implementation
--skip-action-mailbox   # don't include inbound email
--skip-turbolinks       # don't include Turbolinks JS library
--skip-spring           # don't include Spring application preloader
--skip-test             # Skip built in test framework. (RSpec included via template.rb)
--template=template.rb  # add additional configuration from template.rb
--database=postgresql   # default to PostgreSQL
```

You may want to edit that file if you do need some of those frameworks

### What template.rb does

1. Install RSpec
1. Commit the resulting project with git (unless `--skip-git` is passed)
