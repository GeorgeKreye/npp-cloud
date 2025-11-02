terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}

// VPCs
resource "google_compute_network" "tf-mod3-lab1-vpc1" {
  name                    = "tf-mod3-lab1-vpc1"
  auto_create_subnetworks = "false"
  project                 = "kr-m3-l1-cunetworking"
}

resource "google_compute_network" "tf-mod3-lab1-vpc2" {
  name                    = "tf-mod3-lab1-vpc2"
  auto_create_subnetworks = "false"
  project                 = "kr-m3-l1-cunetworking"
}

// VPC Peering
resource "google_compute_network_peering" "tf-mod3-lab1-peering1" {
  name         = "tf-mod3-lab1-peering1"
  network      = google_compute_network.tf-mod3-lab1-vpc1.self_link
  peer_network = google_compute_network.tf-mod3-lab1-vpc2.self_link
}

resource "google_compute_network_peering" "tf-mod3-lab1-peering2" {
  name         = "tf-mod3-lab1-peering2"
  network      = google_compute_network.tf-mod3-lab1-vpc2.self_link
  peer_network = google_compute_network.tf-mod3-lab1-vpc1.self_link
}

// Subnets
resource "google_compute_subnetwork" "tf-mod3-lab1-sub1" {
  name          = "tf-mod3-lab1-sub1"
  ip_cidr_range = "172.16.0.0/24"
  region        = "us-central1"
  network       = google_compute_network.tf-mod3-lab1-vpc1.id
  project       = "kr-m3-l1-cunetworking"
}

resource "google_compute_subnetwork" "tf-mod3-lab1-sub2" {
  name          = "tf-mod3-lab1-sub2"
  ip_cidr_range = "172.16.1.0/24"
  region        = "us-east1"
  network       = google_compute_network.tf-mod3-lab1-vpc2.id
  project       = "kr-m3-l1-cunetworking"
}

// Firewalls
resource "google_compute_firewall" "tf-mod3-lab1-fwrule1" {
  project = "kr-m3-l1-cunetworking" 
  name    = "tf-mod3-lab1-fwrule1"
  network = "tf-mod3-lab1-vpc1"
  depends_on = [google_compute_network.tf-mod3-lab1-vpc1]

  allow {
    protocol = "tcp"
    ports    = ["22", "1234"]
  }
  allow {
    protocol = "udp"
    ports    = ["50000"]
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "tf-mod3-lab1-fwrule2" {
  project = "kr-m3-l1-cunetworking" 
  name    = "tf-mod3-lab1-fwrule2"
  network = "tf-mod3-lab1-vpc2"
  depends_on = [google_compute_network.tf-mod3-lab1-vpc2]

  allow {
    protocol = "tcp"
    ports    = ["22", "1234"]
  }
  allow {
    protocol = "udp"
    ports    = ["50000"]
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
}

// Router
resource "google_compute_router" "tf-mod3-lab1-router" {
  name       = "tf-mod3-lab1-router"
  region     = "us-east1"
  network    = google_compute_network.tf-mod3-lab1-vpc2.id
  depends_on = [google_compute_network.tf-mod3-lab1-vpc2]
  project    = "kr-m3-l1-cunetworking" 
}

// Router Interface
resource "google_compute_router_interface" "tf-mod3-lab1-rtrinterface" {
  name       = "tf-mod3-lab1-rtrinterface"
  router     = "tf-mod3-lab1-router"
  region     = google_compute_router.tf-mod3-lab1-router.region
  subnetwork = google_compute_subnetwork.tf-mod3-lab1-sub2.id
  depends_on = [google_compute_router.tf-mod3-lab1-router, google_compute_subnetwork.tf-mod3-lab1-sub2]
  project    = "kr-m3-l1-cunetworking" 
}

// NAT
resource "google_compute_router_nat" "tf-mod3-lab1-nat" {
  name                               = "tf-mod3-lab1-nat"
  router                             = "tf-mod3-lab1-router"
  region                             = google_compute_router.tf-mod3-lab1-router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  depends_on                         = [google_compute_network.tf-mod3-lab1-vpc2, google_compute_router.tf-mod3-lab1-router]
  max_ports_per_vm                   = 64
  project                            = "kr-m3-l1-cunetworking"
}

// Custom Default Route
resource "google_compute_route" "tf-mod3-lab1-nat-route" {
  name             = "tf-mod3-lab1-nat-route"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.tf-mod3-lab1-vpc2.name
  next_hop_gateway = "default-internet-gateway" 
  project          = "kr-m3-l1-cunetworking" 
}

// VMs
resource "google_compute_instance" "tf-mod3-lab1-vm1" {
  name         = "tf-mod3-lab1-vm1"
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  project      = "kr-m3-l1-cunetworking" 
  depends_on   = [google_compute_network.tf-mod3-lab1-vpc1, google_compute_subnetwork.tf-mod3-lab1-sub1]
  network_interface {
    network    = "tf-mod3-lab1-vpc1"
    subnetwork = "tf-mod3-lab1-sub1"
    subnetwork_project = "kr-m3-l1-cunetworking"
  }

  boot_disk {
    initialize_params {
      image = "debian-12-bookworm-v20240312"
    }
  }
  metadata = {
    startup-script = "sudo apt update; sudo apt -y install netcat-traditional ncat;"
  }
}

resource "google_compute_instance" "tf-mod3-lab1-vm2" {
  name         = "tf-mod3-lab1-vm2"
  machine_type = "e2-micro"
  zone         = "us-east1-b"
  project      = "kr-m3-l1-cunetworking" 
  depends_on   = [google_compute_network.tf-mod3-lab1-vpc2, google_compute_subnetwork.tf-mod3-lab1-sub2]
  network_interface {
    network    = "tf-mod3-lab1-vpc2"
    subnetwork = "tf-mod3-lab1-sub2"
    subnetwork_project = "kr-m3-l1-cunetworking"
  }

  boot_disk {
    initialize_params {
      image = "debian-12-bookworm-v20240312"
    }
  }
  metadata = {
    startup-script = "sudo apt update; sudo apt -y install netcat-traditional ncat;"
  }
}
