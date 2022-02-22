apply File.expand_path("test_app_template.rb", __dir__)

def cloud_gov_organization
  "sandbox-gsa"
end

def cloud_gov_staging_space
  "staging"
end

def cloud_gov_production_space
  "prod"
end

def has_active_job?
  false
end

def has_active_storage?
  false
end

directory "terraform"
