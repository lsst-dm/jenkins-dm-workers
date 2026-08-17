resource "google_monitoring_dashboard" "jenkins_agent_usage" {
  project = "prompt-proto"
  dashboard_json = jsonencode({
    displayName = "Jenkins Agent Resource Usage"
    gridLayout = {
      columns = 2
      widgets = [
        {
          title = "Agent container CPU (cores used)"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"k8s_container\" metric.type=\"kubernetes.io/container/cpu/core_usage_time\" resource.label.\"namespace_name\"=\"jenkins\" metadata.user_labels.\"app\"=monitoring.regex.full_match(\"idf-agent-ldfc.*\")"
                  aggregation = {
                    alignmentPeriod  = "60s"
                    perSeriesAligner = "ALIGN_RATE"
                  }
                }
              }
            }]
          }
        },
        {
          title = "Agent container memory (bytes used)"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "resource.type=\"k8s_container\" metric.type=\"kubernetes.io/container/memory/used_bytes\" resource.label.\"namespace_name\"=\"jenkins\" metadata.user_labels.\"app\"=monitoring.regex.full_match(\"idf-agent-ldfc.*\")"
                  aggregation = {
                    alignmentPeriod  = "60s"
                    perSeriesAligner = "ALIGN_MEAN"
                  }
                }
              }
            }]
          }
        }
      ]
    }
  })
}
