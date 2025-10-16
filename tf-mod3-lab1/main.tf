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
}

resource "google_compute_network" "tf-mod3-lab1-vpc2" {
  name                    = "tf-mod3-lab1-vpc2"
  auto_create_subnetworks = "false"
}


// Subnets
resource "google_compute_subnetwork" "tf-mod3-lab1-sub1" {
  name          = "tf-mod3-lab1-sub1"
  ip_cidr_range = "172.16.0.0/24"
  region        = "us-central1"
  network       = google_compute_network.tf-mod3-lab1-vpc1.id
}

resource "google_compute_subnetwork" "tf-mod3-lab1-sub2" {
  name          = "tf-mod3-lab1-sub2"
  ip_cidr_range = "172.16.1.0/24"
  region        = "us-east1"
  network       = google_compute_network.tf-mod3-lab1-vpc2.id
}

// Firewalls
// TODO: add vxlan ports
resource "google_compute_firewall" "tf-mod3-lab1-fwrule1" {
  project = "kreye-lab1project-cunetworking"
  name    = "tf-mod3-lab1-fwrule1"
  network = "tf-mod3-lab1-vpc1"
  // need the network created before the firewall rule
  depends_on = [google_compute_network.tf-mod3-lab1-vpc1]

  allow {
    protocol = "tcp"
    ports    = ["22", "1234", "50000"]
  }
  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "tf-mod3-lab1-fwrule2" {
  project = "kreye-lab1project-cunetworking"
  name    = "tf-mod3-lab1-fwrule2"
  network = "tf-mod3-lab1-vpc2"
  // need the network created before the firewall rule
  depends_on = [google_compute_network.tf-mod3-lab1-vpc2]

  allow {
    protocol = "tcp"
    ports    = ["22", "1234", "50000"]
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
  network    = "google_compute_network.tf-mod3-lab1-vpc2"
  depends_on = [google_compute_network.tf-mod3-lab1-vpc2]
}

// NAT
resource "google_computer_router_nat" "nat" {
  name                               = "tf-mod3-lab1-nat"
  router                             = "tf-mod3-lab1-router"
  region                             = google_compute_router.tf-mod3-lab1-router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  depends_on                         = [google_compute_network.tf-mod3-lab1-vpc2, google_compute_router.tf-mod3-lab1-router]
}

// VMs
resource "google_compute_instance" "tf-mod3-lab1-vm1" {
  name         = "tf-mod3-lab1-vm1"
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  depends_on   = [google_compute_network.tf-mod3-lab1-vpc1, google_compute_subnetwork.tf-mod3-lab1-sub1]
  network_interface {
    // This indicates to give a public IP address
    // access_config {
    //  network_tier = "STANDARD"
    // }
    network    = "tf-mod3-lab1-vpc1"
    subnetwork = "tf-mod3-lab1-sub1"
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
  depends_on   = [google_compute_network.tf-mod3-lab1-vpc2, google_compute_subnetwork.tf-mod3-lab1-sub2]
  network_interface {
    // This indicates to give a public IP address
    // access_config {
    //   network_tier = "STANDARD"
    // }
    network    = "tf-mod3-lab1-vpc2"
    subnetwork = "tf-mod3-lab1-sub2"
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
