
//https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference
provider "google" {
  credentials = file("C:/Users/Owner/Documents/Non-Vital Keys/kreye-lab1project-cunetworking-6a96bdaba6ff.json")

  project = "kreye-lab1project-cunetworking"
  region  = "us-central1"
  zone    = "us-central1-c"
}
