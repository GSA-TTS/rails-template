terraform {
  required_version = "~> 1.10"
  required_providers {
    cloudfoundry = {
      source  = "cloudfoundry/cloudfoundry"
      version = "1.5.0"
    }
  }

  backend "s3" {
    encrypt           = true
    use_lockfile      = true
    use_fips_endpoint = true
    region            = "us-gov-west-1"
  }
}

provider "cloudfoundry" {}
