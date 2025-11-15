# Auto Scaling Guide - Azure AKS on Azure Stack HCI

This guide explains how to use and configure auto scaling features in your AKS cluster.

## Overview

This Terraform module provides three types of auto scaling:

1. **Horizontal Pod Autoscaler (HPA)** - Scales pods based on metrics
2. **Cluster Autoscaler** - Scales nodes automatically
3. **KEDA** - Event-driven autoscaling (optional)

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  Auto Scaling Stack                     │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Application Layer                                │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐  │  │
│  │  │    Pod     │  │    Pod     │  │    Pod     │  │  │
│  │  └────────────┘  └────────────┘  └────────────┘  │  │
│  │       ▲              ▲              ▲             │  │
│  └───────┼──────────────┼──────────────┼─────────────┘  │
│          │              │              │                │
│  ┌───────┴──────────────┴──────────────┴─────────────┐  │
│  │  Horizontal Pod Autoscaler (HPA)                  │  │
│  │  - Monitors CPU/Memory metrics                    │  │
│  │  - Scales pods up/down                            │  │
│  └────────────────────┬──────────────────────────────┘  │
│                       │                                 │
│  ┌────────────────────▼──────────────────────────────┐  │
│  │  Metrics Server                                   │  │
│  │  - Collects resource metrics                      │  │
│  │  - Provides metrics API                           │  │
│  └────────────────────┬──────────────────────────────┘  │
│                       │                                 │
│  ┌────────────────────▼──────────────────────────────┐  │
│  │  Cluster Autoscaler                               │  │
│  │  - Monitors pending pods                          │  │
│  │  - Adds/removes nodes                             │  │
│  └────────────────────┬──────────────────────────────┘  │
│                       │                                 │
│  ┌────────────────────▼──────────────────────────────┐  │
│  │  Node Pools                                       │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐        │  │
│  │  │  Node 1  │  │  Node 2  │  │  Node N  │        │  │
│  │  └──────────┘  └──────────┘  └──────────┘        │  │
│  │  Min: 1        Current: 3    Max: 10             │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Configuration

### Enable Auto Scaling

Update your `terraform.tfvars`:

```hcl
# Enable all autoscaling features
enable_metrics_server         = true
enable_cluster_autoscaler     = true
enable_node_pool_autoscaling  = true

# Configure scaling behavior
autoscaler_expander               = "least-waste"
scale_down_enabled                = true
scale_down_delay_after_add        = "10m"
scale_down_unneeded_time          = "10m"
scale_down_utilization_threshold  = 0.5

# Set node pool limits
linux_node_pool_min_count    = 2   # Minimum nodes
linux_node_pool_max_count    = 10  # Maximum nodes
windows_node_pool_min_count  = 1
windows_node_pool_max_count  = 8
```

### Apply Configuration

```bash
terraform apply
```

## Horizontal Pod Autoscaler (HPA)

### Prerequisites

- Metrics Server must be enabled (automatically installed)
- Pods must have resource requests defined

### Create an HPA

#### Example 1: CPU-Based Scaling

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: nginx-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: nginx
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

Apply it:

```bash
kubectl apply -f nginx-hpa.yaml
```

#### Example 2: Memory-Based Scaling

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

#### Example 3: Using kubectl

```bash
# Create HPA with kubectl
kubectl autoscale deployment nginx \
  --cpu-percent=70 \
  --min=2 \
  --max=10

# View HPA status
kubectl get hpa

# Watch HPA in action
kubectl get hpa -w

# Describe HPA for details
kubectl describe hpa nginx
```

### Example Deployment with Resource Requests

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        resources:
          requests:
            cpu: 100m        # Required for HPA
            memory: 128Mi    # Required for memory-based HPA
          limits:
            cpu: 500m
            memory: 512Mi
        ports:
        - containerPort: 80
```

### Testing HPA

#### Generate Load

```bash
# Deploy test application
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-apache
spec:
  replicas: 1
  selector:
    matchLabels:
      app: php-apache
  template:
    metadata:
      labels:
        app: php-apache
    spec:
      containers:
      - name: php-apache
        image: registry.k8s.io/hpa-example
        resources:
          requests:
            cpu: 200m
          limits:
            cpu: 500m
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: php-apache
spec:
  ports:
  - port: 80
  selector:
    app: php-apache
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: php-apache
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
EOF

# Generate load (in another terminal)
kubectl run -it --rm load-generator \
  --image=busybox:1.28 \
  --restart=Never \
  -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://php-apache; done"

# Watch HPA scale up
kubectl get hpa php-apache --watch
```

## Cluster Autoscaler

### How It Works

The Cluster Autoscaler automatically:
- **Scales up** when pods can't be scheduled due to insufficient resources
- **Scales down** when nodes are underutilized for a period of time

### Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `autoscaler_expander` | Node selection strategy | `least-waste` |
| `scale_down_enabled` | Allow scaling down | `true` |
| `scale_down_delay_after_add` | Wait time after scale up | `10m` |
| `scale_down_unneeded_time` | Time before removing unneeded node | `10m` |
| `scale_down_utilization_threshold` | CPU threshold for scale down | `0.5` |

### Expander Options

- **least-waste**: Selects node group that will have the least idle CPU after scale-up
- **most-pods**: Selects node group that would schedule the most pods
- **random**: Selects node group randomly
- **priority**: Selects based on configured priorities

### Testing Cluster Autoscaler

#### Trigger Scale Up

```bash
# Create deployment that requires more resources than available
kubectl create deployment autoscale-test \
  --image=nginx \
  --replicas=50

# Watch nodes being added
kubectl get nodes --watch

# Check autoscaler logs
kubectl logs -n kube-system -l app=cluster-autoscaler
```

#### Trigger Scale Down

```bash
# Delete the deployment
kubectl delete deployment autoscale-test

# Wait for scale_down_unneeded_time (default 10m)
# Watch nodes being removed
kubectl get nodes --watch
```

### Preventing Scale Down

To prevent specific nodes from being scaled down:

```bash
# Annotate node to prevent scale down
kubectl annotate node <node-name> \
  cluster-autoscaler.kubernetes.io/scale-down-disabled=true

# Remove annotation to allow scale down
kubectl annotate node <node-name> \
  cluster-autoscaler.kubernetes.io/scale-down-disabled-
```

## KEDA (Event-Driven Autoscaling)

KEDA extends Kubernetes autoscaling with event-driven capabilities.

### Enable KEDA

```hcl
# In terraform.tfvars
enable_keda = true
```

### KEDA Example: Scale Based on Azure Queue

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: azure-queue-scaler
spec:
  scaleTargetRef:
    name: queue-processor
  minReplicaCount: 0   # Scale to zero when idle
  maxReplicaCount: 30
  triggers:
  - type: azure-queue
    metadata:
      queueName: orders
      queueLength: '5'
      connectionFromEnv: AZURE_STORAGE_CONNECTION_STRING
```

### KEDA Example: Scale Based on Metrics

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: prometheus-scaler
spec:
  scaleTargetRef:
    name: api-server
  minReplicaCount: 2
  maxReplicaCount: 20
  triggers:
  - type: prometheus
    metadata:
      serverAddress: http://prometheus:9090
      metricName: http_requests_per_second
      threshold: '100'
      query: sum(rate(http_requests_total[2m]))
```

## Monitoring Auto Scaling

### View HPA Status

```bash
# List all HPAs
kubectl get hpa --all-namespaces

# Watch HPA
kubectl get hpa -w

# Detailed HPA info
kubectl describe hpa <hpa-name>
```

### View Cluster Autoscaler Status

```bash
# Check autoscaler logs
kubectl logs -n kube-system -l app=cluster-autoscaler --tail=50

# View autoscaler status configmap
kubectl get configmap cluster-autoscaler-status \
  -n kube-system -o yaml

# Check node status
kubectl get nodes -o wide
```

### View Metrics

```bash
# Check metrics server is running
kubectl get deployment metrics-server -n kube-system

# View node metrics
kubectl top nodes

# View pod metrics
kubectl top pods --all-namespaces
```

### Azure Portal Monitoring

1. Navigate to your cluster in Azure Portal
2. Go to **Monitoring** > **Insights**
3. View:
   - Node scaling events
   - Pod scaling events
   - Resource utilization trends

## Best Practices

### 1. Set Resource Requests and Limits

Always define resource requests for HPA to work:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

### 2. Configure Appropriate Min/Max Replicas

```yaml
minReplicas: 2   # Ensure availability
maxReplicas: 20  # Prevent runaway scaling
```

### 3. Set Reasonable Scaling Thresholds

```yaml
# CPU-based
averageUtilization: 70  # Scale when avg CPU > 70%

# Memory-based
averageUtilization: 80  # Scale when avg memory > 80%
```

### 4. Configure Pod Disruption Budgets

Ensure availability during scaling:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: myapp
```

### 5. Use Anti-Affinity for Distribution

Spread pods across nodes:

```yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchLabels:
            app: myapp
        topologyKey: kubernetes.io/hostname
```

### 6. Monitor Scaling Events

```bash
# Watch for scaling events
kubectl get events --sort-by='.lastTimestamp' --watch

# Filter HPA events
kubectl get events --field-selector involvedObject.kind=HorizontalPodAutoscaler
```

## Troubleshooting

### HPA Not Scaling

#### Issue: HPA shows "unknown" metrics

```bash
kubectl describe hpa <hpa-name>
# Output shows: unable to get metrics
```

**Solution:**
```bash
# Check metrics server is running
kubectl get deployment metrics-server -n kube-system

# Verify metrics are available
kubectl top nodes
kubectl top pods

# If metrics server is not responding, restart it
kubectl rollout restart deployment metrics-server -n kube-system
```

#### Issue: Pods missing resource requests

```bash
kubectl describe hpa <hpa-name>
# Output shows: missing request for cpu
```

**Solution:** Add resource requests to your deployment:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
```

### Cluster Autoscaler Not Scaling

#### Issue: Nodes not being added

```bash
# Check autoscaler logs
kubectl logs -n kube-system -l app=cluster-autoscaler
```

**Common causes:**
- Node pool at maximum capacity
- Insufficient quota
- Node pool autoscaling disabled

**Solution:**
```bash
# Verify Terraform configuration
terraform output autoscaling_configuration

# Check node pool limits
terraform output node_pool_scaling_limits

# Increase max count if needed
# Edit terraform.tfvars and apply
```

#### Issue: Nodes not being removed

**Check:**
- Scale down is enabled
- Nodes are below utilization threshold
- Sufficient time has passed (scale_down_unneeded_time)
- Nodes don't have pods with local storage
- Nodes don't have system pods

### Performance Issues

#### Issue: HPA scaling too aggressively

**Solution:** Adjust scaling behavior:

```yaml
behavior:
  scaleDown:
    stabilizationWindowSeconds: 300
    policies:
    - type: Percent
      value: 50
      periodSeconds: 60
  scaleUp:
    stabilizationWindowSeconds: 60
    policies:
    - type: Percent
      value: 100
      periodSeconds: 60
```

## Cost Optimization

### Strategy 1: Aggressive Scale Down

For development environments:

```hcl
scale_down_enabled                = true
scale_down_delay_after_add        = "5m"
scale_down_unneeded_time          = "5m"
scale_down_utilization_threshold  = 0.3
linux_node_pool_min_count         = 1
```

### Strategy 2: Scale to Zero (with KEDA)

For batch workloads:

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: batch-processor
spec:
  scaleTargetRef:
    name: batch-processor
  minReplicaCount: 0   # Scale to zero when no work
  maxReplicaCount: 50
```

### Strategy 3: Scheduled Scaling

Scale based on time (requires KEDA):

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: business-hours-scaling
spec:
  scaleTargetRef:
    name: web-app
  minReplicaCount: 10   # Business hours
  maxReplicaCount: 50
  triggers:
  - type: cron
    metadata:
      timezone: America/New_York
      start: 0 9 * * 1-5    # 9 AM weekdays
      end: 0 17 * * 1-5     # 5 PM weekdays
      desiredReplicas: "10"
```

## Configuration Reference

### Complete Terraform Variables

```hcl
# Metrics Server
enable_metrics_server = true

# Cluster Autoscaler
enable_cluster_autoscaler         = true
enable_node_pool_autoscaling      = true
autoscaler_expander               = "least-waste"
scale_down_enabled                = true
scale_down_delay_after_add        = "10m"
scale_down_unneeded_time          = "10m"
scale_down_utilization_threshold  = 0.5

# Node Pool Limits
linux_node_pool_min_count    = 1
linux_node_pool_max_count    = 10
windows_node_pool_min_count  = 1
windows_node_pool_max_count  = 8

# KEDA
enable_keda = false
```

## Additional Resources

- [Kubernetes HPA Documentation](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [Cluster Autoscaler Documentation](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)
- [KEDA Documentation](https://keda.sh/)
- [Metrics Server GitHub](https://github.com/kubernetes-sigs/metrics-server)

---

**Last Updated**: Based on Terraform module v1.0.0 with autoscaling support

