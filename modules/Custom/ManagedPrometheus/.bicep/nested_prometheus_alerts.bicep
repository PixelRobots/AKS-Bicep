param location string = resourceGroup().location

@description('Cluster name')
param AKSClusterName string

@description('Action Group ResourceId')
param actionGroupResourceId string

@description('ResourceId of Azure monitor workspace to associate to')
param azureMonitorWorkspaceResourceId string


resource recommendedAlerts 'Microsoft.AlertsManagement/prometheusRuleGroups@2023-03-01' = {
  name: 'RecommendedCIAlerts-${AKSClusterName}'
  location: location
  properties: {
    description: 'Kubernetes Alert RuleGroup-RecommendedCIAlerts - 0.1'
    scopes: [
      azureMonitorWorkspaceResourceId
    ]
    clusterName: AKSClusterName
    enabled: true
    interval: 'PT5M'
    rules: [
      {
        alert: 'Average CPU usage per container is greater than 95%'
        expression: 'sum (rate(container_cpu_usage_seconds_total{image!="", container_name!="POD"}[5m])) by (pod,cluster,container,namespace) / sum(container_spec_cpu_quota{image!="", container_name!="POD"}/container_spec_cpu_period{image!="", container_name!="POD"}) by (pod,cluster,container,namespace) > .95'
        for: 'PT5M'
        annotations: {
          description: 'Average CPU usage per container is greater than 95%'
        }
        enabled: true
        severity: 4
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT15M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
      }
      {
        alert: 'Average Memory usage per container is greater than 95%.'
        expression: '(container_memory_working_set_bytes{container!="", image!="", container_name!="POD"} / on(namespace,cluster,pod,container) group_left kube_pod_container_resource_limits{resource="memory", node!=""}) > .95'
        for: 'PT10M'
        annotations: {
          description: 'Average Memory usage per container is greater than 95%'
        }
        enabled: true
        severity: 4
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
      }
      {
        alert: 'Number of OOM killed containers is greater than 0'
        expression: 'sum by (cluster,container,namespace)(kube_pod_container_status_last_terminated_reason{reason="OOMKilled"}) > 0'
        for: 'PT5M'
        annotations: {
          description: 'Number of OOM killed containers is greater than 0'
        }
        enabled: true
        severity: 4
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
      }
      {
        alert: 'Average PV usage is greater than 80%'
        expression: 'sum by (namespace,cluster,container,pod)(kubelet_volume_stats_used_bytes{job="kubelet"}) / sum by (namespace,cluster,container,pod)(kubelet_volume_stats_capacity_bytes{job="kubelet"})  >.8'
        for: 'PT5M'
        annotations: {
          description: 'Average PV usage is greater than 80%'
        }
        enabled: true
        severity: 4
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT15M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
      }
      {
        alert: 'Pod container restarted in last 1 hour'
        expression: 'sum by (namespace, pod, container, cluster) (kube_pod_container_status_restarts_total{job="kube-state-metrics", namespace="kube-system"}) > 0 '
        for: 'PT15M'
        annotations: {
          description: 'Pod container restarted in last 1 hour'
        }
        enabled: true
        severity: 4
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
      }
      {
        alert: 'Node is not ready.'
        expression: 'sum by (namespace,cluster,node)(kube_node_status_condition{job="kube-state-metrics",condition="Ready",status!="true", node!=""}) > 0'
        for: 'PT15M'
        annotations: {
          description: 'Node has been unready for more than 15 minutes '
        }
        enabled: true
        severity: 4
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT15M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
      }
      {
        alert: 'Ready state of pods is less than 80%. '
        expression: 'sum by (cluster,namespace,deployment)(kube_deployment_status_replicas_ready) / sum by (cluster,namespace,deployment)(kube_deployment_spec_replicas) <.8 or sum by (cluster,namespace,deployment)(kube_daemonset_status_number_ready) / sum by (cluster,namespace,deployment)(kube_daemonset_status_desired_number_scheduled) <.8 '
        for: 'PT5M'
        annotations: {
          description: 'Ready state of pods is less than 80%.'
        }
        enabled: true
        severity: 4
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT15M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
      }
      {
        alert: 'Job did not complete in time'
        expression: 'sum by(namespace,cluster)(kube_job_spec_completions{job="kube-state-metrics"}) - sum by(namespace,cluster)(kube_job_status_succeeded{job="kube-state-metrics"})  > 0 '
        for: 'PT360M'
        annotations: {
          description: 'Number of stale jobs older than six hours is greater than 0'
        }
        enabled: true
        severity: 4
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT15M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
      }
      {
        alert: 'Average node CPU utilization is greater than 80%'
        expression: '(  (1 - rate(node_cpu_seconds_total{job="node", mode="idle"}[5m]) ) / ignoring(cpu) group_left count without (cpu)( node_cpu_seconds_total{job="node", mode="idle"}) ) > .8 '
        for: 'PT5M'
        annotations: {
          description: 'Average node CPU utilization is greater than 80%'
        }
        enabled: true
        severity: 4
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT15M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
      }
      {
        alert: 'Working set memory for a node is greater than 80%.'
        expression: '1 - avg by (namespace,cluster,job)(node_memory_MemAvailable_bytes{job="node"}) / avg by (namespace,cluster,job)(node_memory_MemTotal_bytes{job="node"}) > .8'
        for: 'PT5M'
        annotations: {
          description: 'Working set memory for a node is greater than 80%.'
        }
        enabled: true
        severity: 4
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT15M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
      }
      {
        alert: 'Number of pods in failed state are greater than 0.'
        expression: 'sum by (cluster, namespace, pod) (kube_pod_status_phase{phase="failed"}) > 0'
        for: 'PT5M'
        annotations: {
          description: 'Number of pods in failed state are greater than 0'
        }
        enabled: true
        severity: 4
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT15M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
      }
    ]
  }
}

resource NodeDiskAlerts 'Microsoft.AlertsManagement/prometheusRuleGroups@2023-03-01' = {
  name: 'AKS-Nodes-DiskSpace'
  location: location
  properties: {
    description: 'Kubernetes Alert RuleGroup-communityCIAlerts - 0.1'
    scopes: [
      azureMonitorWorkspaceResourceId
    ]
    clusterName: AKSClusterName
    enabled: true
    interval: 'PT1M'
    rules: [
      {
        alert: 'NodeFilesystemSpaceFillingUp'
        expression: 'avg by (namespace,cluster,job,device,instance,mountpoint)(node_filesystem_avail_bytes{job="node",fstype!=""}) / avg by (namespace,cluster,job,device,instance,mountpoint)(node_filesystem_size_bytes{job="node",fstype!=""}) * 100 < 40 and avg by (namespace,cluster,job,device,instance,mountpoint)(predict_linear(node_filesystem_avail_bytes{job="node",fstype!=""}[6h], 24*60*60)) < 0 and avg by (namespace,cluster,job,device,instance,mountpoint)(node_filesystem_readonly{job="node",fstype!=""}) == 0'
        for: 'PT15M'
        annotations: {
          description: 'An extrapolation algorithm predicts that disk space usage for node {{ $labels.instance }} on device {{ $labels.device }} in {{ $labels.cluster}} will run out of space within the upcoming 24 hours. For more information on this alert, please refer to this [link](https://github.com/prometheus-operator/runbooks/blob/main/content/runbooks/node/NodeFilesystemSpaceFillingUp.md).'
        }
        labels: {
          severity: 'warning'
        }
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
      }
      {
        alert: 'NodeFilesystemSpaceUsageFull85Pct'
        expression: '1 - avg by (namespace,cluster,job,device,instance,mountpoint)(node_filesystem_avail_bytes{job="node"}) / avg by (namespace,cluster,job,device,instance,mountpoint)(node_filesystem_size_bytes{job="node"}) > .85'
        for: 'PT15M'
        annotations: {
          description: 'Disk space usage for node {{ $labels.instance }} on device {{ $labels.device }} in {{ $labels.cluster}} is greater than 85%. For more information on this alert, please refer to this [link](https://github.com/prometheus-operator/runbooks/blob/main/content/runbooks/node/NodeFilesystemAlmostOutOfSpace.md).'
        }
        labels: {
          severity: 'warning'
        }
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
      }
    ]

  }
}

resource kubernetes_apps 'Microsoft.AlertsManagement/prometheusRuleGroups@2023-03-01' = {
  name: 'kubernetes-apps'
  location: location
  properties: {
    interval: 'PT1M'
    scopes: [
      azureMonitorWorkspaceResourceId
    ]
    clusterName: AKSClusterName
    rules: [
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubePodCrashLooping'
        annotations: {
          description: 'Pod {{ $labels.namespace }}/{{ $labels.pod }} ({{ $labels.container }}) is in waiting state (reason: "CrashLoopBackOff").'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubepodcrashlooping'
          summary: 'Pod is crash looping.'
        }
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        expression: 'max_over_time(kube_pod_container_status_waiting_reason{reason="CrashLoopBackOff", job="kube-state-metrics"}[5m]) >= 1\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubePodNotReady'
        annotations: {
          description: 'Pod {{ $labels.namespace }}/{{ $labels.pod }} has been in a non-ready state for longer than 15 minutes.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubepodnotready'
          summary: 'Pod has been in a non-ready state for more than 15 minutes.'
        }
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        expression: 'sum by (namespace, pod, cluster) (\n  max by(namespace, pod, cluster) (\n    kube_pod_status_phase{job="kube-state-metrics", phase=~"Pending|Unknown|Failed"}\n  ) * on(namespace, pod, cluster) group_left(owner_kind) topk by(namespace, pod, cluster) (\n    1, max by(namespace, pod, owner_kind, cluster) (kube_pod_owner{owner_kind!="Job"})\n  )\n) > 0\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeDeploymentGenerationMismatch'
        annotations: {
          description: 'Deployment generation for {{ $labels.namespace }}/{{ $labels.deployment }} does not match, this indicates that the Deployment has failed but has not been rolled back.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubedeploymentgenerationmismatch'
          summary: 'Deployment generation mismatch due to possible roll-back'
        }
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        expression: 'kube_deployment_status_observed_generation{job="kube-state-metrics"}\n  !=\nkube_deployment_metadata_generation{job="kube-state-metrics"}\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeDeploymentReplicasMismatch'
        annotations: {
          description: 'Deployment {{ $labels.namespace }}/{{ $labels.deployment }} has not matched the expected number of replicas for longer than 15 minutes.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubedeploymentreplicasmismatch'
          summary: 'Deployment has not matched the expected number of replicas.'
        }
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        expression: '(\n  kube_deployment_spec_replicas{job="kube-state-metrics"}\n    >\n  kube_deployment_status_replicas_available{job="kube-state-metrics"}\n) and (\n  changes(kube_deployment_status_replicas_updated{job="kube-state-metrics"}[10m])\n    ==\n  0\n)\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeStatefulSetReplicasMismatch'
        annotations: {
          description: 'StatefulSet {{ $labels.namespace }}/{{ $labels.statefulset }} has not matched the expected number of replicas for longer than 15 minutes.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubestatefulsetreplicasmismatch'
          summary: 'Deployment has not matched the expected number of replicas.'
        }
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        expression: '(\n  kube_statefulset_status_replicas_ready{job="kube-state-metrics"}\n    !=\n  kube_statefulset_status_replicas{job="kube-state-metrics"}\n) and (\n  changes(kube_statefulset_status_replicas_updated{job="kube-state-metrics"}[10m])\n    ==\n  0\n)\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeStatefulSetGenerationMismatch'
        annotations: {
          description: 'StatefulSet generation for {{ $labels.namespace }}/{{ $labels.statefulset }} does not match, this indicates that the StatefulSet has failed but has not been rolled back.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubestatefulsetgenerationmismatch'
          summary: 'StatefulSet generation mismatch due to possible roll-back'
        }
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        expression: 'kube_statefulset_status_observed_generation{job="kube-state-metrics"}\n  !=\nkube_statefulset_metadata_generation{job="kube-state-metrics"}\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeStatefulSetUpdateNotRolledOut'
        annotations: {
          description: 'StatefulSet {{ $labels.namespace }}/{{ $labels.statefulset }} update has not been rolled out.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubestatefulsetupdatenotrolledout'
          summary: 'StatefulSet update has not been rolled out.'
        }
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        expression: '(\n  max without (revision) (\n    kube_statefulset_status_current_revision{job="kube-state-metrics"}\n      unless\n    kube_statefulset_status_update_revision{job="kube-state-metrics"}\n  )\n    *\n  (\n    kube_statefulset_replicas{job="kube-state-metrics"}\n      !=\n    kube_statefulset_status_replicas_updated{job="kube-state-metrics"}\n  )\n)  and (\n  changes(kube_statefulset_status_replicas_updated{job="kube-state-metrics"}[5m])\n    ==\n  0\n)\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeDaemonSetRolloutStuck'
        annotations: {
          description: 'DaemonSet {{ $labels.namespace }}/{{ $labels.daemonset }} has not finished or progressed for at least 15 minutes.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubedaemonsetrolloutstuck'
          summary: 'DaemonSet rollout is stuck.'
        }
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        expression: '(\n  (\n    kube_daemonset_status_current_number_scheduled{job="kube-state-metrics"}\n     !=\n    kube_daemonset_status_desired_number_scheduled{job="kube-state-metrics"}\n  ) or (\n    kube_daemonset_status_number_misscheduled{job="kube-state-metrics"}\n     !=\n    0\n  ) or (\n    kube_daemonset_status_updated_number_scheduled{job="kube-state-metrics"}\n     !=\n    kube_daemonset_status_desired_number_scheduled{job="kube-state-metrics"}\n  ) or (\n    kube_daemonset_status_number_available{job="kube-state-metrics"}\n     !=\n    kube_daemonset_status_desired_number_scheduled{job="kube-state-metrics"}\n  )\n) and (\n  changes(kube_daemonset_status_updated_number_scheduled{job="kube-state-metrics"}[5m])\n    ==\n  0\n)\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeContainerWaiting'
        annotations: {
          description: 'pod/{{ $labels.pod }} in namespace {{ $labels.namespace }} on container {{ $labels.container}} has been in waiting state for longer than 1 hour.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubecontainerwaiting'
          summary: 'Pod container waiting longer than 1 hour'
        }
        for: 'PT1H'
        labels: {
          severity: 'warning'
        }
        expression: 'sum by (namespace, pod, container, cluster) (kube_pod_container_status_waiting_reason{job="kube-state-metrics"}) > 0\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeDaemonSetNotScheduled'
        annotations: {
          description: '{{ $value }} Pods of DaemonSet {{ $labels.namespace }}/{{ $labels.daemonset }} are not scheduled.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubedaemonsetnotscheduled'
          summary: 'DaemonSet pods are not scheduled.'
        }
        for: 'PT10M'
        labels: {
          severity: 'warning'
        }
        expression: 'kube_daemonset_status_desired_number_scheduled{job="kube-state-metrics"}\n  -\nkube_daemonset_status_current_number_scheduled{job="kube-state-metrics"} > 0\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeDaemonSetMisScheduled'
        annotations: {
          description: '{{ $value }} Pods of DaemonSet {{ $labels.namespace }}/{{ $labels.daemonset }} are running where they are not supposed to run.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubedaemonsetmisscheduled'
          summary: 'DaemonSet pods are misscheduled.'
        }
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        expression: 'kube_daemonset_status_number_misscheduled{job="kube-state-metrics"} > 0\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeJobNotCompleted'
        annotations: {
          description: 'Job {{ $labels.namespace }}/{{ $labels.job_name }} is taking more than {{ "43200" | humanizeDuration }} to complete.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubejobnotcompleted'
          summary: 'Job did not complete in time'
        }
        labels: {
          severity: 'warning'
        }
        expression: 'time() - max by(namespace, job_name, cluster) (kube_job_status_start_time{job="kube-state-metrics"}\n  and\nkube_job_status_active{job="kube-state-metrics"} > 0) > 43200\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeJobFailed'
        annotations: {
          description: 'Job {{ $labels.namespace }}/{{ $labels.job_name }} failed to complete. Removing failed job after investigation should clear this alert.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubejobfailed'
          summary: 'Job failed to complete.'
        }
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        expression: 'kube_job_failed{job="kube-state-metrics"}  > 0\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeHpaReplicasMismatch'
        annotations: {
          description: 'HPA {{ $labels.namespace }}/{{ $labels.horizontalpodautoscaler  }} has not matched the desired number of replicas for longer than 15 minutes.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubehpareplicasmismatch'
          summary: 'HPA has not matched desired number of replicas.'
        }
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        expression: '(kube_horizontalpodautoscaler_status_desired_replicas{job="kube-state-metrics"}\n  !=\nkube_horizontalpodautoscaler_status_current_replicas{job="kube-state-metrics"})\n  and\n(kube_horizontalpodautoscaler_status_current_replicas{job="kube-state-metrics"}\n  >\nkube_horizontalpodautoscaler_spec_min_replicas{job="kube-state-metrics"})\n  and\n(kube_horizontalpodautoscaler_status_current_replicas{job="kube-state-metrics"}\n  <\nkube_horizontalpodautoscaler_spec_max_replicas{job="kube-state-metrics"})\n  and\nchanges(kube_horizontalpodautoscaler_status_current_replicas{job="kube-state-metrics"}[15m]) == 0\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeHpaMaxedOut'
        annotations: {
          description: 'HPA {{ $labels.namespace }}/{{ $labels.horizontalpodautoscaler  }} has been running at max replicas for longer than 15 minutes.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubehpamaxedout'
          summary: 'HPA is running at max replicas'
        }
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        expression: 'kube_horizontalpodautoscaler_status_current_replicas{job="kube-state-metrics"}\n  ==\nkube_horizontalpodautoscaler_spec_max_replicas{job="kube-state-metrics"}\n'
      }
    ]
  }
}

resource kubernetes_resources 'Microsoft.AlertsManagement/prometheusRuleGroups@2023-03-01' = {
  name: 'kubernetes-resources'
  location: location
  properties: {
    interval: 'PT1M'
    scopes: [
      azureMonitorWorkspaceResourceId
    ]
    clusterName: AKSClusterName
    rules: [
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeCPUOvercommit'
        annotations: {
          description: 'Cluster has overcommitted CPU resource requests for Pods by {{ $value }} CPU shares and cannot tolerate node failure.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubecpuovercommit'
          summary: 'Cluster has overcommitted CPU resource requests.'
        }
        for: 'PT10M'
        labels: {
          severity: 'warning'
        }
        expression: 'sum(namespace_cpu:kube_pod_container_resource_requests:sum{}) - (sum(kube_node_status_allocatable{resource="cpu", job="kube-state-metrics"}) - max(kube_node_status_allocatable{resource="cpu", job="kube-state-metrics"})) > 0\nand\n(sum(kube_node_status_allocatable{resource="cpu", job="kube-state-metrics"}) - max(kube_node_status_allocatable{resource="cpu", job="kube-state-metrics"})) > 0\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeMemoryOvercommit'
        annotations: {
          description: 'Cluster has overcommitted memory resource requests for Pods by {{ $value | humanize }} bytes and cannot tolerate node failure.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubememoryovercommit'
          summary: 'Cluster has overcommitted memory resource requests.'
        }
        for: 'PT10M'
        labels: {
          severity: 'warning'
        }
        expression: 'sum(namespace_memory:kube_pod_container_resource_requests:sum{}) - (sum(kube_node_status_allocatable{resource="memory", job="kube-state-metrics"}) - max(kube_node_status_allocatable{resource="memory", job="kube-state-metrics"})) > 0\nand\n(sum(kube_node_status_allocatable{resource="memory", job="kube-state-metrics"}) - max(kube_node_status_allocatable{resource="memory", job="kube-state-metrics"})) > 0\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeCPUQuotaOvercommit'
        annotations: {
          description: 'Cluster has overcommitted CPU resource requests for Namespaces.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubecpuquotaovercommit'
          summary: 'Cluster has overcommitted CPU resource requests.'
        }
        for: 'PT5M'
        labels: {
          severity: 'warning'
        }
        expression: 'sum(min without(resource) (kube_resourcequota{job="kube-state-metrics", type="hard", resource=~"(cpu|requests.cpu)"}))\n  /\nsum(kube_node_status_allocatable{resource="cpu", job="kube-state-metrics"})\n  > 1.5\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeMemoryQuotaOvercommit'
        annotations: {
          description: 'Cluster has overcommitted memory resource requests for Namespaces.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubememoryquotaovercommit'
          summary: 'Cluster has overcommitted memory resource requests.'
        }
        for: 'PT5M'
        labels: {
          severity: 'warning'
        }
        expression: 'sum(min without(resource) (kube_resourcequota{job="kube-state-metrics", type="hard", resource=~"(memory|requests.memory)"}))\n  /\nsum(kube_node_status_allocatable{resource="memory", job="kube-state-metrics"})\n  > 1.5\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeQuotaAlmostFull'
        annotations: {
          description: 'Namespace {{ $labels.namespace }} is using {{ $value | humanizePercentage }} of its {{ $labels.resource }} quota.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubequotaalmostfull'
          summary: 'Namespace quota is going to be full.'
        }
        for: 'PT15M'
        labels: {
          severity: 'info'
        }
        expression: 'kube_resourcequota{job="kube-state-metrics", type="used"}\n  / ignoring(instance, job, type)\n(kube_resourcequota{job="kube-state-metrics", type="hard"} > 0)\n  > 0.9 < 1\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeQuotaFullyUsed'
        annotations: {
          description: 'Namespace {{ $labels.namespace }} is using {{ $value | humanizePercentage }} of its {{ $labels.resource }} quota.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubequotafullyused'
          summary: 'Namespace quota is fully used.'
        }
        for: 'PT15M'
        labels: {
          severity: 'info'
        }
        expression: 'kube_resourcequota{job="kube-state-metrics", type="used"}\n  / ignoring(instance, job, type)\n(kube_resourcequota{job="kube-state-metrics", type="hard"} > 0)\n  == 1\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeQuotaExceeded'
        annotations: {
          description: 'Namespace {{ $labels.namespace }} is using {{ $value | humanizePercentage }} of its {{ $labels.resource }} quota.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubequotaexceeded'
          summary: 'Namespace quota has exceeded the limits.'
        }
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        expression: 'kube_resourcequota{job="kube-state-metrics", type="used"}\n  / ignoring(instance, job, type)\n(kube_resourcequota{job="kube-state-metrics", type="hard"} > 0)\n  > 1\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'CPUThrottlingHigh'
        annotations: {
          description: '{{ $value | humanizePercentage }} throttling of CPU in namespace {{ $labels.namespace }} for container {{ $labels.container }} in pod {{ $labels.pod }}.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-cputhrottlinghigh'
          summary: 'Processes experience elevated CPU throttling.'
        }
        for: 'PT15M'
        labels: {
          severity: 'info'
        }
        expression: 'sum(increase(container_cpu_cfs_throttled_periods_total{container!="", }[5m])) by (container, pod, namespace)\n  /\nsum(increase(container_cpu_cfs_periods_total{}[5m])) by (container, pod, namespace)\n  > ( 25 / 100 )\n'
      }
    ]
  }
}

resource kubernetes_storage 'Microsoft.AlertsManagement/prometheusRuleGroups@2023-03-01' = {
  name: 'kubernetes-storage'
  location: location
  properties: {
    interval: 'PT1M'
    scopes: [
      azureMonitorWorkspaceResourceId
    ]
    clusterName: AKSClusterName
    rules: [
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubePersistentVolumeFillingUp'
        annotations: {
          description: 'The PersistentVolume claimed by {{ $labels.persistentvolumeclaim }} in Namespace {{ $labels.namespace }} is only {{ $value | humanizePercentage }} free.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubepersistentvolumefillingup'
          summary: 'PersistentVolume is filling up.'
        }
        for: 'PT1M'
        labels: {
          severity: 'critical'
        }
        expression: '(\n  kubelet_volume_stats_available_bytes{job="kubelet"}\n    /\n  kubelet_volume_stats_capacity_bytes{job="kubelet"}\n) < 0.03\nand\nkubelet_volume_stats_used_bytes{job="kubelet"} > 0\nunless on(namespace, persistentvolumeclaim)\nkube_persistentvolumeclaim_access_mode{ access_mode="ReadOnlyMany"} == 1\nunless on(namespace, persistentvolumeclaim)\nkube_persistentvolumeclaim_labels{label_excluded_from_alerts="true"} == 1\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubePersistentVolumeFillingUp'
        annotations: {
          description: 'Based on recent sampling, the PersistentVolume claimed by {{ $labels.persistentvolumeclaim }} in Namespace {{ $labels.namespace }} is expected to fill up within four days. Currently {{ $value | humanizePercentage }} is available.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubepersistentvolumefillingup'
          summary: 'PersistentVolume is filling up.'
        }
        for: 'PT1H'
        labels: {
          severity: 'warning'
        }
        expression: '(\n  kubelet_volume_stats_available_bytes{job="kubelet"}\n    /\n  kubelet_volume_stats_capacity_bytes{job="kubelet"}\n) < 0.15\nand\nkubelet_volume_stats_used_bytes{job="kubelet"} > 0\nand\npredict_linear(kubelet_volume_stats_available_bytes{job="kubelet"}[6h], 4 * 24 * 3600) < 0\nunless on(namespace, persistentvolumeclaim)\nkube_persistentvolumeclaim_access_mode{ access_mode="ReadOnlyMany"} == 1\nunless on(namespace, persistentvolumeclaim)\nkube_persistentvolumeclaim_labels{label_excluded_from_alerts="true"} == 1\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubePersistentVolumeInodesFillingUp'
        annotations: {
          description: 'The PersistentVolume claimed by {{ $labels.persistentvolumeclaim }} in Namespace {{ $labels.namespace }} only has {{ $value | humanizePercentage }} free inodes.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubepersistentvolumeinodesfillingup'
          summary: 'PersistentVolumeInodes are filling up.'
        }
        for: 'PT1M'
        labels: {
          severity: 'critical'
        }
        expression: '(\n  kubelet_volume_stats_inodes_free{job="kubelet"}\n    /\n  kubelet_volume_stats_inodes{job="kubelet"}\n) < 0.03\nand\nkubelet_volume_stats_inodes_used{job="kubelet"} > 0\nunless on(namespace, persistentvolumeclaim)\nkube_persistentvolumeclaim_access_mode{ access_mode="ReadOnlyMany"} == 1\nunless on(namespace, persistentvolumeclaim)\nkube_persistentvolumeclaim_labels{label_excluded_from_alerts="true"} == 1\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubePersistentVolumeInodesFillingUp'
        annotations: {
          description: 'Based on recent sampling, the PersistentVolume claimed by {{ $labels.persistentvolumeclaim }} in Namespace {{ $labels.namespace }} is expected to run out of inodes within four days. Currently {{ $value | humanizePercentage }} of its inodes are free.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubepersistentvolumeinodesfillingup'
          summary: 'PersistentVolumeInodes are filling up.'
        }
        for: 'PT1H'
        labels: {
          severity: 'warning'
        }
        expression: '(\n  kubelet_volume_stats_inodes_free{job="kubelet"}\n    /\n  kubelet_volume_stats_inodes{job="kubelet"}\n) < 0.15\nand\nkubelet_volume_stats_inodes_used{job="kubelet"} > 0\nand\npredict_linear(kubelet_volume_stats_inodes_free{job="kubelet"}[6h], 4 * 24 * 3600) < 0\nunless on(namespace, persistentvolumeclaim)\nkube_persistentvolumeclaim_access_mode{ access_mode="ReadOnlyMany"} == 1\nunless on(namespace, persistentvolumeclaim)\nkube_persistentvolumeclaim_labels{label_excluded_from_alerts="true"} == 1\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubePersistentVolumeErrors'
        annotations: {
          description: 'The persistent volume {{ $labels.persistentvolume }} has status {{ $labels.phase }}.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubepersistentvolumeerrors'
          summary: 'PersistentVolume is having issues with provisioning.'
        }
        for: 'PT5M'
        labels: {
          severity: 'critical'
        }
        expression: 'kube_persistentvolume_status_phase{phase=~"Failed|Pending",job="kube-state-metrics"} > 0\n'
      }
    ]
  }
}

resource kubernetes_system 'Microsoft.AlertsManagement/prometheusRuleGroups@2023-03-01' = {
  name: 'kubernetes-system'
  location: location
  properties: {
    interval: 'PT1M'
    scopes: [
      azureMonitorWorkspaceResourceId
    ]
    clusterName: AKSClusterName
    rules: [
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeVersionMismatch'
        annotations: {
          description: 'There are {{ $value }} different semantic versions of Kubernetes components running.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeversionmismatch'
          summary: 'Different semantic versions of Kubernetes components running.'
        }
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        expression: 'count by (cluster) (count by (git_version, cluster) (label_replace(kubernetes_build_info{job!~"kube-dns|coredns"},"git_version","$1","git_version","(v[0-9]*.[0-9]*).*"))) > 1\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeClientErrors'
        annotations: {
          description: 'Kubernetes API server client \'{{ $labels.job }}/{{ $labels.instance }}\' is experiencing {{ $value | humanizePercentage }} errors.\''
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeclienterrors'
          summary: 'Kubernetes API server client is experiencing errors.'
        }
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        expression: '(sum(rate(rest_client_requests_total{job="kube-apiserver",code=~"5.."}[5m])) by (cluster, instance, job, namespace)\n  /\nsum(rate(rest_client_requests_total{job="kube-apiserver"}[5m])) by (cluster, instance, job, namespace))\n> 0.01\n'
      }
    ]
  }
}

resource kube_apiserver_slos 'Microsoft.AlertsManagement/prometheusRuleGroups@2023-03-01' = {
  name: 'kube-apiserver-slos'
  location: location
  properties: {
    interval: 'PT1M'
    scopes: [
      azureMonitorWorkspaceResourceId
    ]
    clusterName: AKSClusterName
    rules: [
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeAPIErrorBudgetBurn'
        annotations: {
          description: 'The API server is burning too much error budget.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeapierrorbudgetburn'
          summary: 'The API server is burning too much error budget.'
        }
        for: 'PT2M'
        labels: {
          long: '1h'
          severity: 'critical'
          short: '5m'
        }
        expression: 'sum(apiserver_request:burnrate1h) > (14.40 * 0.01000)\nand\nsum(apiserver_request:burnrate5m) > (14.40 * 0.01000)\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeAPIErrorBudgetBurn'
        annotations: {
          description: 'The API server is burning too much error budget.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeapierrorbudgetburn'
          summary: 'The API server is burning too much error budget.'
        }
        for: 'PT15M'
        labels: {
          long: '6h'
          severity: 'critical'
          short: '30m'
        }
        expression: 'sum(apiserver_request:burnrate6h) > (6.00 * 0.01000)\nand\nsum(apiserver_request:burnrate30m) > (6.00 * 0.01000)\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeAPIErrorBudgetBurn'
        annotations: {
          description: 'The API server is burning too much error budget.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeapierrorbudgetburn'
          summary: 'The API server is burning too much error budget.'
        }
        for: 'PT1H'
        labels: {
          long: '1d'
          severity: 'warning'
          short: '2h'
        }
        expression: 'sum(apiserver_request:burnrate1d) > (3.00 * 0.01000)\nand\nsum(apiserver_request:burnrate2h) > (3.00 * 0.01000)\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeAPIErrorBudgetBurn'
        annotations: {
          description: 'The API server is burning too much error budget.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeapierrorbudgetburn'
          summary: 'The API server is burning too much error budget.'
        }
        for: 'PT3H'
        labels: {
          long: '3d'
          severity: 'warning'
          short: '6h'
        }
        expression: 'sum(apiserver_request:burnrate3d) > (1.00 * 0.01000)\nand\nsum(apiserver_request:burnrate6h) > (1.00 * 0.01000)\n'
      }
    ]
  }
}

resource kubernetes_system_apiserver 'Microsoft.AlertsManagement/prometheusRuleGroups@2023-03-01' = {
  name: 'kubernetes-system-apiserver'
  location: location
  properties: {
    interval: 'PT1M'
    scopes: [
      azureMonitorWorkspaceResourceId
    ]
    clusterName: AKSClusterName
    rules: [
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeClientCertificateExpiration'
        annotations: {
          description: 'A client certificate used to authenticate to kubernetes apiserver is expiring in less than 7.0 days.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeclientcertificateexpiration'
          summary: 'Client certificate is about to expire.'
        }
        for: 'PT5M'
        labels: {
          severity: 'warning'
        }
        expression: 'apiserver_client_certificate_expiration_seconds_count{job="kube-apiserver"} > 0 and on(job) histogram_quantile(0.01, sum by (job, le) (rate(apiserver_client_certificate_expiration_seconds_bucket{job="kube-apiserver"}[5m]))) < 604800\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeClientCertificateExpiration'
        annotations: {
          description: 'A client certificate used to authenticate to kubernetes apiserver is expiring in less than 24.0 hours.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeclientcertificateexpiration'
          summary: 'Client certificate is about to expire.'
        }
        for: 'PT5M'
        labels: {
          severity: 'critical'
        }
        expression: 'apiserver_client_certificate_expiration_seconds_count{job="kube-apiserver"} > 0 and on(job) histogram_quantile(0.01, sum by (job, le) (rate(apiserver_client_certificate_expiration_seconds_bucket{job="kube-apiserver"}[5m]))) < 86400\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeAggregatedAPIErrors'
        annotations: {
          description: 'Kubernetes aggregated API {{ $labels.name }}/{{ $labels.namespace }} has reported errors. It has appeared unavailable {{ $value | humanize }} times averaged over the past 10m.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeaggregatedapierrors'
          summary: 'Kubernetes aggregated API has reported errors.'
        }
        labels: {
          severity: 'warning'
        }
        expression: 'sum by(name, namespace, cluster)(increase(aggregator_unavailable_apiservice_total[10m])) > 4\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeAggregatedAPIDown'
        annotations: {
          description: 'Kubernetes aggregated API {{ $labels.name }}/{{ $labels.namespace }} has been only {{ $value | humanize }}% available over the last 10m.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeaggregatedapidown'
          summary: 'Kubernetes aggregated API is down.'
        }
        for: 'PT5M'
        labels: {
          severity: 'warning'
        }
        expression: '(1 - max by(name, namespace, cluster)(avg_over_time(aggregator_unavailable_apiservice[10m]))) * 100 < 85\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeAPIDown'
        annotations: {
          description: 'KubeAPI has disappeared from Prometheus target discovery.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeapidown'
          summary: 'Target disappeared from Prometheus target discovery.'
        }
        for: 'PT15M'
        labels: {
          severity: 'critical'
        }
        expression: 'absent(up{job="kube-apiserver"} == 1)\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeAPITerminatedRequests'
        annotations: {
          description: 'The kubernetes apiserver has terminated {{ $value | humanizePercentage }} of its incoming requests.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeapiterminatedrequests'
          summary: 'The kubernetes apiserver has terminated {{ $value | humanizePercentage }} of its incoming requests.'
        }
        for: 'PT5M'
        labels: {
          severity: 'warning'
        }
        expression: 'sum(rate(apiserver_request_terminations_total{job="kube-apiserver"}[10m]))  / (  sum(rate(apiserver_request_total{job="kube-apiserver"}[10m])) + sum(rate(apiserver_request_terminations_total{job="kube-apiserver"}[10m])) ) > 0.20\n'
      }
    ]
  }
}

resource kubernetes_system_kubelet 'Microsoft.AlertsManagement/prometheusRuleGroups@2023-03-01' = {
  name: 'kubernetes-system-kubelet'
  location: location
  properties: {
    interval: 'PT1M'
    scopes: [
      azureMonitorWorkspaceResourceId
    ]
    clusterName: AKSClusterName
    rules: [
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeNodeNotReady'
        annotations: {
          description: '{{ $labels.node }} has been unready for more than 15 minutes.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubenodenotready'
          summary: 'Node is not ready.'
        }
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        expression: 'kube_node_status_condition{job="kube-state-metrics",condition="Ready",status="true"} == 0\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeNodeUnreachable'
        annotations: {
          description: '{{ $labels.node }} is unreachable and some workloads may be rescheduled.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubenodeunreachable'
          summary: 'Node is unreachable.'
        }
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        expression: '(kube_node_spec_taint{job="kube-state-metrics",key="node.kubernetes.io/unreachable",effect="NoSchedule"} unless ignoring(key,value) kube_node_spec_taint{job="kube-state-metrics",key=~"ToBeDeletedByClusterAutoscaler|cloud.google.com/impending-node-termination|aws-node-termination-handler/spot-itn"}) == 1\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeletTooManyPods'
        annotations: {
          description: 'Kubelet \'{{ $labels.node }}\' is running at {{ $value | humanizePercentage }} of its Pod capacity.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubelettoomanypods'
          summary: 'Kubelet is running at capacity.'
        }
        for: 'PT15M'
        labels: {
          severity: 'info'
        }
        expression: 'count by(cluster, node) (\n  (kube_pod_status_phase{job="kube-state-metrics",phase="Running"} == 1) * on(instance,pod,namespace,cluster) group_left(node) topk by(instance,pod,namespace,cluster) (1, kube_pod_info{job="kube-state-metrics"})\n)\n/\nmax by(cluster, node) (\n  kube_node_status_capacity{job="kube-state-metrics",resource="pods"} != 1\n) > 0.95\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeNodeReadinessFlapping'
        annotations: {
          description: 'The readiness status of node {{ $labels.node }} has changed {{ $value }} times in the last 15 minutes.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubenodereadinessflapping'
          summary: 'Node readiness status is flapping.'
        }
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        expression: 'sum(changes(kube_node_status_condition{job="kube-state-metrics",status="true",condition="Ready"}[15m])) by (cluster, node) > 2\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeletPlegDurationHigh'
        annotations: {
          description: 'The Kubelet Pod Lifecycle Event Generator has a 99th percentile duration of {{ $value }} seconds on node {{ $labels.node }}.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeletplegdurationhigh'
          summary: 'Kubelet Pod Lifecycle Event Generator is taking too long to relist.'
        }
        for: 'PT5M'
        labels: {
          severity: 'warning'
        }
        expression: 'node_quantile:kubelet_pleg_relist_duration_seconds:histogram_quantile{quantile="0.99"} >= 10\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeletPodStartUpLatencyHigh'
        annotations: {
          description: 'Kubelet Pod startup 99th percentile latency is {{ $value }} seconds on node {{ $labels.node }}.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeletpodstartuplatencyhigh'
          summary: 'Kubelet Pod startup latency is too high.'
        }
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        expression: 'histogram_quantile(0.99, sum(rate(kubelet_pod_worker_duration_seconds_bucket{job="kubelet"}[5m])) by (cluster, instance, le)) * on(cluster, instance) group_left(node) kubelet_node_name{job="kubelet"} > 60\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeletClientCertificateExpiration'
        annotations: {
          description: 'Client certificate for Kubelet on node {{ $labels.node }} expires in {{ $value | humanizeDuration }}.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeletclientcertificateexpiration'
          summary: 'Kubelet client certificate is about to expire.'
        }
        labels: {
          severity: 'warning'
        }
        expression: 'kubelet_certificate_manager_client_ttl_seconds < 604800\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeletClientCertificateExpiration'
        annotations: {
          description: 'Client certificate for Kubelet on node {{ $labels.node }} expires in {{ $value | humanizeDuration }}.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeletclientcertificateexpiration'
          summary: 'Kubelet client certificate is about to expire.'
        }
        labels: {
          severity: 'critical'
        }
        expression: 'kubelet_certificate_manager_client_ttl_seconds < 86400\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeletServerCertificateExpiration'
        annotations: {
          description: 'Server certificate for Kubelet on node {{ $labels.node }} expires in {{ $value | humanizeDuration }}.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeletservercertificateexpiration'
          summary: 'Kubelet server certificate is about to expire.'
        }
        labels: {
          severity: 'warning'
        }
        expression: 'kubelet_certificate_manager_server_ttl_seconds < 604800\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeletServerCertificateExpiration'
        annotations: {
          description: 'Server certificate for Kubelet on node {{ $labels.node }} expires in {{ $value | humanizeDuration }}.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeletservercertificateexpiration'
          summary: 'Kubelet server certificate is about to expire.'
        }
        labels: {
          severity: 'critical'
        }
        expression: 'kubelet_certificate_manager_server_ttl_seconds < 86400\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeletClientCertificateRenewalErrors'
        annotations: {
          description: 'Kubelet on node {{ $labels.node }} has failed to renew its client certificate ({{ $value | humanize }} errors in the last 5 minutes).'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeletclientcertificaterenewalerrors'
          summary: 'Kubelet has failed to renew its client certificate.'
        }
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        expression: 'increase(kubelet_certificate_manager_client_expiration_renew_errors[5m]) > 0\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeletServerCertificateRenewalErrors'
        annotations: {
          description: 'Kubelet on node {{ $labels.node }} has failed to renew its server certificate ({{ $value | humanize }} errors in the last 5 minutes).'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeletservercertificaterenewalerrors'
          summary: 'Kubelet has failed to renew its server certificate.'
        }
        for: 'PT15M'
        labels: {
          severity: 'warning'
        }
        expression: 'increase(kubelet_server_expiration_renew_errors[5m]) > 0\n'
      }
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeletDown'
        annotations: {
          description: 'Kubelet has disappeared from Prometheus target discovery.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeletdown'
          summary: 'Target disappeared from Prometheus target discovery.'
        }
        for: 'PT15M'
        labels: {
          severity: 'critical'
        }
        expression: 'absent(up{job="kubelet"} == 1)\n'
      }
    ]
  }
}

resource kubernetes_system_scheduler 'Microsoft.AlertsManagement/prometheusRuleGroups@2023-03-01' = {
  name: 'kubernetes-system-scheduler'
  location: location
  properties: {
    interval: 'PT1M'
    scopes: [
      azureMonitorWorkspaceResourceId
    ]
    clusterName: AKSClusterName
    rules: [
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeSchedulerDown'
        annotations: {
          description: 'KubeScheduler has disappeared from Prometheus target discovery.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeschedulerdown'
          summary: 'Target disappeared from Prometheus target discovery.'
        }
        for: 'PT15M'
        labels: {
          severity: 'critical'
        }
        expression: 'absent(up{job="kube-scheduler"} == 1)\n'
      }
    ]
  }
}

resource kubernetes_system_controller_manager 'Microsoft.AlertsManagement/prometheusRuleGroups@2023-03-01' = {
  name: 'kubernetes-system-controller-manager'
  location: location
  properties: {
    interval: 'PT1M'
    scopes: [
      azureMonitorWorkspaceResourceId
    ]
    clusterName: AKSClusterName
    rules: [
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeControllerManagerDown'
        annotations: {
          description: 'KubeControllerManager has disappeared from Prometheus target discovery.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubecontrollermanagerdown'
          summary: 'Target disappeared from Prometheus target discovery.'
        }
        for: 'PT15M'
        labels: {
          severity: 'critical'
        }
        expression: 'absent(up{job="kube-controller-manager"} == 1)\n'
      }
    ]
  }
}

resource kubernetes_system_kube_proxy 'Microsoft.AlertsManagement/prometheusRuleGroups@2023-03-01' = {
  name: 'kubernetes-system-kube-proxy'
  location: location
  properties: {
    interval: 'PT1M'
    scopes: [
      azureMonitorWorkspaceResourceId
    ]
    clusterName: AKSClusterName
    rules: [
      {
        severity: 3
        resolveConfiguration: {
          autoResolved: true
          timeToResolve: 'PT10M'
        }
        actions: [
          {
            actionGroupId: actionGroupResourceId
          }
        ]
        alert: 'KubeProxyDown'
        annotations: {
          description: 'KubeProxy has disappeared from Prometheus target discovery.'
          runbook_url: 'https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeproxydown'
          summary: 'Target disappeared from Prometheus target discovery.'
        }
        for: 'PT15M'
        labels: {
          severity: 'critical'
        }
        expression: 'absent(up{job="kube-proxy"} == 1)\n'
      }
    ]
  }
}
