# google_container_cluster.jenkins_test:
resource "google_container_cluster" "jenkins_test" {
  cluster_ipv4_cidr                        = "10.224.0.0/14"
  datapath_provider                        = "LEGACY_DATAPATH"
  default_max_pods_per_node                = 110
  deletion_protection                      = true
  enable_cilium_clusterwide_network_policy = false
  enable_intranode_visibility              = false
  enable_kubernetes_alpha                  = false
  enable_l4_ilb_subsetting                 = false
  enable_legacy_abac                       = false
  enable_multi_networking                  = false
  enable_shielded_nodes                    = true
  enable_tpu                               = false
  initial_node_count                       = 0
  location                                 = "us-central1-c"
  logging_service                          = "logging.googleapis.com/kubernetes"
  monitoring_service                       = "monitoring.googleapis.com/kubernetes"
  name                                     = "jenkins-test"
  network                                  = "projects/prompt-proto/global/networks/prompt-proto-net"
  networking_mode                          = "VPC_NATIVE"
  node_locations                           = []
  project                                  = "prompt-proto"
  #resource_labels                          = {}
  subnetwork = "projects/prompt-proto/regions/us-central1/subnetworks/prompt-proto-sub-1"
  node_pool_auto_config {
    resource_manager_tags = {}
  }
  addons_config {
    dns_cache_config {
      enabled = false
    }
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
    gcs_fuse_csi_driver_config {
      enabled = true
    }
    horizontal_pod_autoscaling {
      disabled = true
    }
    http_load_balancing {
      disabled = false
    }
    network_policy_config {
      disabled = true
    }
  }

  #    authenticator_groups_config {}


  cluster_autoscaling {
    autoscaling_profile = "BALANCED"
    enabled             = false
  }

  database_encryption {
    state = "DECRYPTED"
  }

  default_snat_status {
    disabled = false
  }

  # ip_allocation_policy {
  #   cluster_ipv4_cidr_block       = "10.224.0.0/14"
  #   cluster_secondary_range_name  = "gke-jenkins-test-pods-ed1f94bc"
  #   services_ipv4_cidr_block      = "10.228.0.0/20"
  #   services_secondary_range_name = "gke-jenkins-test-services-ed1f94bc"
  #   stack_type                    = "IPV4"

  #   pod_cidr_overprovision_config {
  #     disabled = false
  #   }
  # }

  logging_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "WORKLOADS",
    ]
  }

  maintenance_policy {
    recurring_window {
      end_time   = "2024-02-12T02:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
      start_time = "2024-02-11T18:00:00Z"
    }
  }

  master_auth {

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  monitoring_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
    ]
  }

  network_policy {
    enabled  = false
    provider = "PROVIDER_UNSPECIFIED"
  }


  node_pool_defaults {
    node_config_defaults {
      logging_variant = "DEFAULT"
    }
  }

  notification_config {
    pubsub {
      enabled = false
    }
  }

  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "172.16.0.0/28"
    #peering_name            = "gke-n1bc6bb6fdb9c3005cbb-3f9a-057e-peer"
    #private_endpoint        = "172.16.0.2"
    #public_endpoint         = "34.122.218.154"

    master_global_access_config {
      enabled = false
    }
  }

  release_channel {
    channel = "REGULAR"
  }

  security_posture_config {
    mode               = "MODE_UNSPECIFIED"
    vulnerability_mode = "VULNERABILITY_MODE_UNSPECIFIED"
  }

  service_external_ips_config {
    enabled = false
  }

  workload_identity_config {
    workload_pool = "prompt-proto.svc.id.goog"
  }
}
