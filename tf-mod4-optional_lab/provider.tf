
//https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference
provider "google" {
  credentials = file("C:\\Users\\Owner\\Documents\\Non-Vital Keys\\kr-m3-l1-cunetworking-77f6fe95ee4c.json")

  project = "kr-m3-l1-cunetworking"
  region  = "us-central1"
  zone    = "us-central1-c"
}
