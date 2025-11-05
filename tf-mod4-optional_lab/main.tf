terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

// Network
resource "google_compute_network" "tf-mod4-olab-network" {
  name    = "tf-mod4-olab-network"
  project = "kr-m3-l1-cunetworking"
}

// Frontend subnet
resource "google_compute_subnetwork" "tf-mod4-olab-frontend" {
  name          = "tf-mod4-olab-frontend"
  project       = "kr-m3-l1-cunetworking"
  ip_cidr_range = "192.168.0.0/24"
  region        = "us-central1"
  network       = google_compute_network.tf-mod4-olab-network.name
  depends_on    = [google_compute_network.tf-mod4-olab-network]
}

// Backend subnet
resource "google_compute_subnetwork" "tf-mod4-olab-backend" {
  name          = "tf-mod4-olab-backend"
  project       = "kr-m3-l1-cunetworking"
  ip_cidr_range = "192.168.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.tf-mod4-olab-network.name
  depends_on    = [google_compute_network.tf-mod4-olab-network]
}

// External application load balancer
resource "google_compute_address" "tf-mod4-olab-exalb-entryaddr" { // Entry address
  name    = "tf-mod4-olab-exalb-entryaddr"
  project = "kr-m3-l1-cunetworking"
  region  = "us-central1"
}
resource "google_compute_url_map" "tf-mod4-olab-exalb-urlmap" { // URL map
  name            = "tf-mod4-olab-exalb-urlmap"
  project         = "kr-m3-l1-cunetworking"
  default_service = ""
}
resource "google_compute_target_http_proxy" "tf-mod4-olab-exalb-proxy" { // Proxy
  name       = "tf-mod4-olab-exalb-proxy"
  project    = "kr-m3-l1-cunetworking"
  url_map    = google_compute_url_map.tf-mod4-olab-exalb-urlmap.id
  depends_on = [google_compute_url_map.tf-mod4-olab-exalb-urlmap]
}
resource "google_compute_forwarding_rule" "tf-mod4-olab-exalb-fwdrule" { // Forwarding rule
  name                  = "tf-mod4-olab-exalb-fwdrule"
  project               = "kr-m3-l1-cunetworking"
  network               = google_compute_network.tf-mod4-olab-network.id
  region                = "us-central1"
  ip_address            = google_compute_address.tf-mod4-olab-exalb-entryaddr.address
  port_range            = "80"
  target                = google_compute_target_http_proxy.tf-mod4-olab-exalb-proxy.id
  load_balancing_scheme = "EXTERNAL"
  depends_on            = [google_compute_network.tf-mod4-olab-network, google_compute_address.tf-mod4-olab-exalb-entryaddr, google_compute_target_http_proxy.tf-mod4-olab-exalb-proxy]
}

// Internal network load balancer
resource "google_compute_forwarding_rule" "tf-mod4-olab-inlb-fwdrule" {
  name                  = "tf-mod4-olab-inlb-fwdrule"
  project               = "kr-m3-l1-cunetworking"
  network               = google_compute_network.tf-mod4-olab-network.id
  region                = "us-central1"
  port_range            = "8080"
  load_balancing_scheme = "INTERNAL"
  ip_address            = "192.168.1.1"
  depends_on = [google_compute_network.tf-mod4-olab-network]
}

// Frontend service
// TODO: Find proper way to set up
# resource "?" "tf-mod4-olab-ftndservice" {
#   name = "tf-mod4-olab-ftndservice"
# }

// Backend service
resource "google_compute_region_backend_service" "tf-mod4-olab-bkndservice" {
  name                  = "tf-mod4-olab-bkndservice"
  project               = "kr-m3-l1-cunetworking"
  region                = "us-central1"
  port_name             = "HTTP"
  protocol              = "HTTP"
  load_balancing_scheme = "INTERNAL"
  backend {
    group = google_compute_instance_group.tf-mod4-olab-bkndinstances.id
  }
}

// Frontend VMs
resource "google_compute_instance_group" "tf-mod4-olab-ftndinstances" {
  name       = "tf-mod4-olab-ftndinstances"
  project    = "kr-m3-l1-cunetworking"
  zone       = "us-central1-a"
  network    = google_compute_network.tf-mod4-olab-network.id
  depends_on = [google_compute_network.tf-mod4-olab-network]
  named_port {
    name = "HTTP"
    port = "80"
  }
}

// Backend VMs
resource "google_compute_instance_group" "tf-mod4-olab-bkndinstances" {
  name       = "tf-mod4-olab-bkndinstances"
  project    = "kr-m3-l1-cunetworking"
  zone       = "us-central1-a"
  network    = google_compute_network.tf-mod4-olab-network.id
  depends_on = [google_compute_network.tf-mod4-olab-network]
  named_port {
    name = "HTTP"
    port = "8080"
  }
}
