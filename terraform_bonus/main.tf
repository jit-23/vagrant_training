terraform {
  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "19.1.0"
    }
  }
}

provider "gitlab" {
  # Configuration options
}