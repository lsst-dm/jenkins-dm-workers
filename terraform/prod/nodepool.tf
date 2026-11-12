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
    "us-central1-a",
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
      "worktype"                       = "workers"
      "cloud.google.com/compute-class" = "jenkins-workers-x86"
    }
    local_ssd_count = 0
    logging_variant = "DEFAULT"
    machine_type    = "c4d-standard-32"

    taint {
      key    = "cloud.google.com/compute-class"
      value  = "jenkins-workers-x86"
      effect = "NO_SCHEDULE"
    }
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


# x86 fallback pool, priority 2 of the jenkins-workers-x86 ComputeClass: x86 agent
# pods land here when C4D is out of capacity. c4-standard-32 is also hyperdisk-only,
# so it takes the same /j volume spec as C4D.
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
      "worktype"                       = "workers"
      "cloud.google.com/compute-class" = "jenkins-workers-x86"
    }
    local_ssd_count = 0
    logging_variant = "DEFAULT"
    machine_type    = "c4-standard-32"

    taint {
      key    = "cloud.google.com/compute-class"
      value  = "jenkins-workers-x86"
      effect = "NO_SCHEDULE"
    }
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

resource "google_container_node_pool" "jenkins_workers_n4_fallback" {
  cluster            = google_container_cluster.jenkins_test.name
  location           = google_container_cluster.jenkins_test.location
  max_pods_per_node  = 110
  name               = "jenkins-workers-n4-fallback"
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
      "worktype"                       = "workers"
      "cloud.google.com/compute-class" = "jenkins-workers-x86"
    }
    local_ssd_count = 0
    logging_variant = "DEFAULT"
    machine_type    = "n4-standard-32"

    taint {
      key    = "cloud.google.com/compute-class"
      value  = "jenkins-workers-x86"
      effect = "NO_SCHEDULE"
    }
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


# arm64 fallback pool, priority 2 of the jenkins-workers-arm ComputeClass:
# arm agent pods land here when C4A is out of capacity. N4A is Axion, like C4A,
# and accepts hyperdisk-balanced -- which matters because a pod's volume spec is
# fixed before scheduling, so both arm families have to accept the same /j volume.
# This replaced a T2A pool that could take neither Hyperdisk nor Local SSD.
# GKE auto-taints arm nodes with kubernetes.io/arch=arm64:NoSchedule.
resource "google_container_node_pool" "jenkins_workers_n4a_fallback" {
  cluster            = google_container_cluster.jenkins_test.name
  location           = google_container_cluster.jenkins_test.location
  max_pods_per_node  = 110
  name               = "jenkins-workers-n4a-fallback"
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
      "workload"                       = "workers"
      "cloud.google.com/compute-class" = "jenkins-workers-arm"
    }
    local_ssd_count = 0
    logging_variant = "DEFAULT"
    machine_type    = "n4a-standard-32"

    taint {
      key    = "cloud.google.com/compute-class"
      value  = "jenkins-workers-arm"
      effect = "NO_SCHEDULE"
    }
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
      "workload"                       = "workers"
      "cloud.google.com/compute-class" = "jenkins-workers-arm"
    }
    local_ssd_count = 0
    logging_variant = "DEFAULT"
    machine_type    = "c4a-standard-32"

    taint {
      key    = "cloud.google.com/compute-class"
      value  = "jenkins-workers-arm"
      effect = "NO_SCHEDULE"
    }
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

# google_compute_reservation.jenkins_c4a:
resource "google_compute_reservation" "jenkins_c4a" {
    commitment                    = null
    delete_at_time                = null
    description                   = "Jenkins nightly aarch64 capacity floor. Review 2027-04-09."
    name                          = "jenkins-c4a-standard-32"
    project                       = "prompt-proto"
    specific_reservation_required = true
    zone                          = "https://www.googleapis.com/compute/v1/projects/prompt-proto/zones/us-central1-b"

    reservation_sharing_policy {
        service_share_type = "DISALLOW_ALL"
    }

    specific_reservation {
        count                    = 1
        source_instance_template = null

        instance_properties {
            location_hint    = null
            machine_type     = "c4a-standard-32"
            min_cpu_platform = null
        }
    }
}

# google_container_node_pool.jenkins_workers_n4a64_fallback:
resource "google_container_node_pool" "jenkins_workers_n4a64_fallback" {
    cluster                     = "jenkins-test"
    initial_node_count          = 0
    location                    = "us-central1-c"
    max_pods_per_node           = 110
    name                        = "jenkins-workers-n4a64-fallback"
    name_prefix                 = null
    node_count                  = 0
    node_locations              = [
        "us-central1-a",
        "us-central1-b",
        "us-central1-c",
        "us-central1-f",
    ]
    project                     = "prompt-proto"
    version                     = "1.35.8-gke.1380001"

    autoscaling {
        location_policy      = "ANY"
        max_node_count       = 0
        min_node_count       = 0
        total_max_node_count = 8
        total_min_node_count = 0
    }

    management {
        auto_repair  = true
        auto_upgrade = true
    }

    network_config {
        create_pod_range     = false
        enable_private_nodes = true
        pod_ipv4_cidr_block  = "10.224.0.0/14"
        pod_range            = "gke-jenkins-test-pods-ed1f94bc"
    }

    node_config {
        boot_disk_kms_key           = null
        disk_size_gb                = 900
        disk_type                   = "hyperdisk-balanced"
        enable_confidential_storage = false
        flex_start                  = false
        image_type                  = "COS_CONTAINERD"
        labels                      = {
            "cloud.google.com/compute-class" = "jenkins-workers-arm"
            "workload"                       = "workers"
        }
        local_ssd_count             = 0
        local_ssd_encryption_mode   = null
        logging_variant             = "DEFAULT"
        machine_type                = "n4a-highmem-64"
        max_run_duration            = null
        metadata                    = {
            "disable-legacy-endpoints" = "true"
        }
        min_cpu_platform            = null
        node_group                  = null
        oauth_scopes                = [
            "https://www.googleapis.com/auth/devstorage.read_only",
            "https://www.googleapis.com/auth/logging.write",
            "https://www.googleapis.com/auth/monitoring",
            "https://www.googleapis.com/auth/service.management.readonly",
            "https://www.googleapis.com/auth/servicecontrol",
            "https://www.googleapis.com/auth/trace.append",
        ]
        preemptible                 = false
        resource_labels             = {
            "goog-gke-node-pool-provisioning-model" = "on-demand"
        }
        service_account             = "default"
        spot                        = false
        tags                        = []

        boot_disk {
            disk_type              = "hyperdisk-balanced"
            provisioned_iops       = 0
            provisioned_throughput = 0
            size_gb                = 900
        }

        kubelet_config {
            allowed_unsafe_sysctls                 = []
            container_log_max_files                = 0
            container_log_max_size                 = null
            cpu_cfs_quota                          = false
            cpu_cfs_quota_period                   = null
            cpu_manager_policy                     = null
            eviction_max_pod_grace_period_seconds  = 0
            image_gc_high_threshold_percent        = 0
            image_gc_low_threshold_percent         = 0
            image_maximum_gc_age                   = null
            image_minimum_gc_age                   = null
            insecure_kubelet_readonly_port_enabled = "TRUE"
            max_parallel_image_pulls               = 2
            pod_pids_limit                         = 0
            single_process_oom_kill                = false
        }

        shielded_instance_config {
            enable_integrity_monitoring = true
            enable_secure_boot          = true
        }

        taint {
            effect = "NO_SCHEDULE"
            key    = "cloud.google.com/compute-class"
            value  = "jenkins-workers-arm"
        }

        windows_node_config {
            osversion = "OS_VERSION_UNSPECIFIED"
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

# google_container_node_pool.jenkins_workers_c4a_reserved:
resource "google_container_node_pool" "jenkins_workers_c4a_reserved" {
    cluster                     = "jenkins-test"
    initial_node_count          = 0
    location                    = "us-central1-c"
    max_pods_per_node           = 110
    name                        = "jenkins-workers-c4a-reserved"
    name_prefix                 = null
    node_count                  = 0
    node_locations              = [
        "us-central1-b",
    ]
    project                     = "prompt-proto"
    version                     = "1.35.8-gke.1796000"

    autoscaling {
        location_policy      = "ANY"
        max_node_count       = 0
        min_node_count       = 0
        total_max_node_count = 1
        total_min_node_count = 0
    }

    management {
        auto_repair  = true
        auto_upgrade = true
    }

    network_config {
        create_pod_range     = false
        enable_private_nodes = true
        pod_ipv4_cidr_block  = "10.224.0.0/14"
        pod_range            = "gke-jenkins-test-pods-ed1f94bc"
    }

    node_config {
        boot_disk_kms_key           = null
        disk_size_gb                = 900
        disk_type                   = "hyperdisk-balanced"
        enable_confidential_storage = false
        flex_start                  = false
        image_type                  = "COS_CONTAINERD"
        labels                      = {
            "cloud.google.com/compute-class" = "jenkins-workers-arm-reserved"
            "workload"                       = "workers"
        }
        local_ssd_count             = 0
        local_ssd_encryption_mode   = null
        logging_variant             = "DEFAULT"
        machine_type                = "c4a-standard-32"
        max_run_duration            = null
        metadata                    = {
            "disable-legacy-endpoints" = "true"
        }
        min_cpu_platform            = null
        node_group                  = null
        oauth_scopes                = [
            "https://www.googleapis.com/auth/devstorage.read_only",
            "https://www.googleapis.com/auth/logging.write",
            "https://www.googleapis.com/auth/monitoring",
            "https://www.googleapis.com/auth/service.management.readonly",
            "https://www.googleapis.com/auth/servicecontrol",
            "https://www.googleapis.com/auth/trace.append",
        ]
        preemptible                 = false
        resource_labels             = {
            "goog-gke-node-pool-provisioning-model" = "reservation"
        }
        service_account             = "default"
        spot                        = false
        tags                        = []

        boot_disk {
            disk_type              = "hyperdisk-balanced"
            provisioned_iops       = 0
            provisioned_throughput = 0
            size_gb                = 900
        }

        kubelet_config {
            allowed_unsafe_sysctls                 = []
            container_log_max_files                = 0
            container_log_max_size                 = null
            cpu_cfs_quota                          = false
            cpu_cfs_quota_period                   = null
            cpu_manager_policy                     = null
            eviction_max_pod_grace_period_seconds  = 0
            image_gc_high_threshold_percent        = 0
            image_gc_low_threshold_percent         = 0
            image_maximum_gc_age                   = null
            image_minimum_gc_age                   = null
            insecure_kubelet_readonly_port_enabled = "TRUE"
            max_parallel_image_pulls               = 2
            pod_pids_limit                         = 0
            single_process_oom_kill                = false
        }

        reservation_affinity {
            consume_reservation_type = "SPECIFIC_RESERVATION"
            key                      = "compute.googleapis.com/reservation-name"
            values                   = [
                "jenkins-c4a-standard-32",
            ]
        }

        shielded_instance_config {
            enable_integrity_monitoring = true
            enable_secure_boot          = true
        }

        taint {
            effect = "NO_SCHEDULE"
            key    = "cloud.google.com/compute-class"
            value  = "jenkins-workers-arm-reserved"
        }

        windows_node_config {
            osversion = "OS_VERSION_UNSPECIFIED"
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