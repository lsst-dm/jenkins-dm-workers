# google_container_node_pool.jenkins_controls_standard:
resource "google_container_node_pool" "jenkins_controls_standard" {
  cluster            = google_container_cluster.jenkins_test.name
  initial_node_count = 3
  autoscaling {
    min_node_count = 0
    max_node_count = 3
  }
  location          = google_container_cluster.jenkins_test.location
  max_pods_per_node = 110
  name              = "jenkins-controls-standard"
  node_locations = [
    "us-central1-c",
  ]
  project = "prompt-proto"

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  network_config {
    create_pod_range     = false
    enable_private_nodes = true
    pod_ipv4_cidr_block  = "10.224.0.0/14"
  }

  node_config {
    disk_size_gb                = 100
    disk_type                   = "pd-balanced"
    enable_confidential_storage = false
    image_type                  = "COS_CONTAINERD"
    labels                      = {}
    local_ssd_count             = 0
    logging_variant             = "DEFAULT"
    machine_type                = "n2-standard-4"
    metadata = {
      "disable-legacy-endpoints" = "true"
    }
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]
    preemptible           = false
    resource_labels       = {}
    resource_manager_tags = {}
    service_account       = "default"
    spot                  = false
    tags                  = []

    shielded_instance_config {
      enable_integrity_monitoring = true
      enable_secure_boot          = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
    strategy        = "SURGE"
  }
}

# google_container_node_pool.jenkins_workers_multiarch_c4d:
resource "google_container_node_pool" "jenkins_workers_c4d" {
  cluster            = google_container_cluster.jenkins_test.name
  location           = google_container_cluster.jenkins_test.location
  max_pods_per_node  = 110
  name               = "jenkins-workers-c4d"
  initial_node_count = 4
  autoscaling {
    total_min_node_count = 0
    total_max_node_count = 8
    location_policy      = "ANY"
  }
  node_locations = [
    "us-central1-a",
    "us-central1-b",
    "us-central1-c",
    "us-central1-f",
  ]
  project = "prompt-proto"

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  network_config {
    create_pod_range     = false
    enable_private_nodes = true
    #pod_ipv4_cidr_block  = "10.224.0.0/14"
  }

  node_config {
    disk_size_gb                = 900
    disk_type                   = "hyperdisk-balanced"
    enable_confidential_storage = false
    image_type                  = "COS_CONTAINERD"
    labels = {
      "worktype" = "workers"
    }
    local_ssd_count = 0
    logging_variant = "DEFAULT"
    machine_type    = "c4d-standard-32"
    metadata = {
      "disable-legacy-endpoints" = "true"
    }
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]
    preemptible = false
    resource_labels = {
      "worktype" = "workers"
    }
    resource_manager_tags = {}
    service_account       = "default"
    spot                  = false
    tags                  = []

    shielded_instance_config {
      enable_integrity_monitoring = true
      enable_secure_boot          = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
    strategy        = "SURGE"
  }

  lifecycle {
    ignore_changes = [initial_node_count]
  }
}


# x86 fallback pool. Shares the "worktype=workers" node label with
# jenkins-workers-c4d so x86 agent pods can land here when C4D capacity is
# unavailable (stockout). c4-standard-32 is also hyperdisk-only.
resource "google_container_node_pool" "jenkins_workers_c4_fallback" {
  cluster            = google_container_cluster.jenkins_test.name
  location           = google_container_cluster.jenkins_test.location
  max_pods_per_node  = 110
  name               = "jenkins-workers-c4-fallback"
  initial_node_count = 0
  autoscaling {
    total_min_node_count = 0
    total_max_node_count = 8
    location_policy      = "ANY"
  }
  node_locations = [
    "us-central1-a",
    "us-central1-b",
    "us-central1-c",
    "us-central1-f",
  ]
  project = "prompt-proto"

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  network_config {
    create_pod_range     = false
    enable_private_nodes = true
  }

  node_config {
    disk_size_gb                = 900
    disk_type                   = "hyperdisk-balanced"
    enable_confidential_storage = false
    image_type                  = "COS_CONTAINERD"
    labels = {
      "worktype" = "workers"
    }
    local_ssd_count = 0
    logging_variant = "DEFAULT"
    machine_type    = "c4-standard-32"
    metadata = {
      "disable-legacy-endpoints" = "true"
    }
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]
    preemptible = false
    resource_labels = {
      "worktype" = "workers"
    }
    resource_manager_tags = {}
    service_account       = "default"
    spot                  = false
    tags                  = []

    shielded_instance_config {
      enable_integrity_monitoring = true
      enable_secure_boot          = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
    strategy        = "SURGE"
  }

  lifecycle {
    ignore_changes = [initial_node_count]
  }
}


# arm64 fallback pool. Shares the "workload=workers" node label with
# jenkins-workers-multiarch-c4a so arm agent pods can land here when C4A
# capacity is unavailable. T2A runs in us-central1-a/b/f (not -c) and
# supports pd-balanced boot disks only (no hyperdisk). GKE auto-taints arm
# nodes with kubernetes.io/arch=arm64:NoSchedule.
resource "google_container_node_pool" "jenkins_workers_t2a_fallback" {
  cluster            = google_container_cluster.jenkins_test.name
  location           = google_container_cluster.jenkins_test.location
  max_pods_per_node  = 110
  name               = "jenkins-workers-t2a-fallback"
  initial_node_count = 0
  autoscaling {
    total_min_node_count = 0
    total_max_node_count = 8
    location_policy      = "ANY"
  }
  node_locations = [
    "us-central1-a",
    "us-central1-b",
    "us-central1-f",
  ]
  project = "prompt-proto"

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  network_config {
    create_pod_range     = false
    enable_private_nodes = true
  }

  node_config {
    disk_size_gb                = 900
    disk_type                   = "pd-balanced"
    enable_confidential_storage = false
    image_type                  = "COS_CONTAINERD"
    labels = {
      "workload" = "workers"
    }
    local_ssd_count = 0
    logging_variant = "DEFAULT"
    machine_type    = "t2a-standard-32"
    metadata = {
      "disable-legacy-endpoints" = "true"
    }
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]
    preemptible           = false
    resource_labels       = {}
    resource_manager_tags = {}
    service_account       = "default"
    spot                  = false
    tags                  = []

    shielded_instance_config {
      enable_integrity_monitoring = true
      enable_secure_boot          = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
    strategy        = "SURGE"
  }

  lifecycle {
    ignore_changes = [initial_node_count]
  }
}


# google_container_node_pool.jenkins_workers_multiarch_c4a:
resource "google_container_node_pool" "jenkins_workers_multiarch_c4a" {
  cluster            = google_container_cluster.jenkins_test.name
  location           = google_container_cluster.jenkins_test.location
  max_pods_per_node  = 110
  name               = "jenkins-workers-multiarch-c4a"
  initial_node_count = 9
  autoscaling {
    total_min_node_count = 0
    total_max_node_count = 8
    location_policy      = "ANY"
  }
  node_locations = [
    "us-central1-a",
    "us-central1-b",
    "us-central1-c",
    "us-central1-f",
  ]
  project = "prompt-proto"

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  network_config {
    create_pod_range     = false
    enable_private_nodes = true
    #pod_ipv4_cidr_block  = "10.224.0.0/14"
  }

  node_config {
    disk_size_gb                = 900
    disk_type                   = "hyperdisk-balanced"
    enable_confidential_storage = false
    image_type                  = "COS_CONTAINERD"
    labels = {
      "workload" = "workers"
    }
    local_ssd_count = 0
    logging_variant = "DEFAULT"
    machine_type    = "c4a-standard-32"
    metadata = {
      "disable-legacy-endpoints" = "true"
    }
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]
    preemptible           = false
    resource_labels       = {}
    resource_manager_tags = {}
    service_account       = "default"
    spot                  = false
    tags                  = []

    shielded_instance_config {
      enable_integrity_monitoring = true
      enable_secure_boot          = true
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
    strategy        = "SURGE"
  }

  lifecycle {
    ignore_changes = [initial_node_count]
  }
}
