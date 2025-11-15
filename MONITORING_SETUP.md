# Monitoring and Observability Setup

## Overview

Complete monitoring and observability stack deployed in the `monitoring` namespace with Prometheus, Grafana, Jaeger, Loki, and supporting tools.

## Components

### Metrics Collection

#### Prometheus
- **Purpose**: Metrics collection and alerting
- **Namespace**: `monitoring`
- **Service**: `prometheus` (ClusterIP) and `prometheus-loadbalancer` (LoadBalancer)
- **Port**: 9090
- **Storage**: 30 days retention
- **Scrapes**:
  - Kubernetes API server
  - Kubernetes nodes
  - Kubernetes pods (with annotations)
  - FTGO application services
  - Node Exporter
  - Kube State Metrics
  - cAdvisor (container metrics)

#### Node Exporter
- **Purpose**: Node-level metrics
- **Type**: DaemonSet (runs on all nodes)
- **Port**: 9100
- **Metrics**: CPU, memory, disk, network per node

#### Kube State Metrics
- **Purpose**: Kubernetes object metrics
- **Type**: Deployment
- **Port**: 8080
- **Metrics**: Pods, deployments, services, nodes, etc.

### Visualization

#### Grafana
- **Purpose**: Metrics visualization and dashboards
- **Namespace**: `monitoring`
- **Service**: `grafana` (ClusterIP) and `grafana-loadbalancer` (LoadBalancer)
- **Port**: 3000
- **Default Credentials**: admin/admin
- **Pre-configured**: Prometheus datasource
- **Access**: Via LoadBalancer URL

### Logging

#### Loki
- **Purpose**: Log aggregation
- **Namespace**: `monitoring`
- **Service**: `loki` (ClusterIP)
- **Port**: 3100
- **Storage**: 10Gi PersistentVolume
- **Retention**: Configurable

#### Promtail
- **Purpose**: Log collection agent
- **Type**: DaemonSet (runs on all nodes)
- **Port**: 3101
- **Collects**: Pod logs, container logs
- **Sends to**: Loki

### Tracing

#### Jaeger
- **Purpose**: Distributed tracing
- **Namespace**: `monitoring`
- **Components**:
  - **Collector**: Collects traces
  - **Query**: UI for viewing traces
  - **Agent**: DaemonSet for trace collection
- **Services**:
  - `jaeger-collector` (ClusterIP)
  - `jaeger-query` (ClusterIP) and `jaeger-query-loadbalancer` (LoadBalancer)
  - `jaeger-agent` (Headless)
- **Ports**:
  - Query UI: 16686
  - Collector: 14268 (HTTP), 14250 (gRPC)
- **Storage**: In-memory (can be configured for persistent storage)

### Alerting

#### Alertmanager
- **Purpose**: Alert management and routing
- **Namespace**: `monitoring`
- **Service**: `alertmanager` (ClusterIP)
- **Port**: 9093
- **Configuration**: Webhook receiver (configurable)

## Deployment

### Automatic Deployment

The monitoring stack is automatically deployed as part of the CI/CD pipeline:

1. Monitoring namespace is created
2. Prometheus and configuration deployed
3. Grafana deployed with Prometheus datasource
4. Node Exporter and Kube State Metrics deployed
5. Alertmanager deployed
6. Loki and Promtail deployed
7. Jaeger deployed

### Manual Deployment

```bash
# Deploy all monitoring components
kubectl apply -f ftgo-application/deployment/kubernetes/monitoring/namespace.yml
kubectl apply -f ftgo-application/deployment/kubernetes/monitoring/prometheus-config.yml
kubectl apply -f ftgo-application/deployment/kubernetes/monitoring/prometheus-deployment.yml
kubectl apply -f ftgo-application/deployment/kubernetes/monitoring/grafana-deployment.yml
kubectl apply -f ftgo-application/deployment/kubernetes/monitoring/node-exporter.yml
kubectl apply -f ftgo-application/deployment/kubernetes/monitoring/kube-state-metrics.yml
kubectl apply -f ftgo-application/deployment/kubernetes/monitoring/alertmanager.yml
kubectl apply -f ftgo-application/deployment/kubernetes/monitoring/loki.yml
kubectl apply -f ftgo-application/deployment/kubernetes/monitoring/promtail.yml
kubectl apply -f ftgo-application/deployment/kubernetes/monitoring/jaeger.yml
```

## Accessing Monitoring Tools

### Load Balancer URLs

After deployment, Load Balancer URLs are displayed in:
- GitHub Actions workflow summary
- Workflow logs

### Grafana
- **URL**: `http://<GRAFANA_LB_IP>`
- **Username**: `admin`
- **Password**: `admin` (change on first login)
- **Pre-configured**: Prometheus datasource

### Prometheus
- **URL**: `http://<PROMETHEUS_LB_IP>`
- **Features**: Query metrics, view targets, alerts

### Jaeger
- **URL**: `http://<JAEGER_LB_IP>`
- **Features**: View distributed traces, search traces

### Internal Access

All services are also accessible via ClusterIP within the cluster:

```bash
# Port forward to access services
kubectl port-forward -n monitoring service/prometheus 9090:9090
kubectl port-forward -n monitoring service/grafana 3000:3000
kubectl port-forward -n monitoring service/jaeger-query 16686:16686
```

## Configuring Application Services for Monitoring

### Prometheus Metrics

Add annotations to your application pods to enable scraping:

```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/actuator/prometheus"
```

### Distributed Tracing

Configure your Spring Boot applications to send traces to Jaeger:

```yaml
env:
  - name: JAEGER_AGENT_HOST
    value: jaeger-agent
  - name: JAEGER_AGENT_PORT
    value: "6831"
```

## Monitoring Dashboards

### Grafana Dashboards

Import pre-built dashboards:
- Kubernetes Cluster Monitoring
- Node Exporter Full
- Kubernetes Pods
- Spring Boot 2.1 Statistics

### Custom Dashboards

Create custom dashboards for:
- FTGO application metrics
- Service-specific metrics
- Business metrics
- Error rates and latency

## Alerts

### Alertmanager Configuration

Alerts are configured in Prometheus and routed through Alertmanager. Configure receivers for:
- Email notifications
- Slack webhooks
- PagerDuty
- Custom webhooks

### Example Alerts

- High CPU usage
- High memory usage
- Pod restart count
- Service availability
- Error rate thresholds

## Log Aggregation

### Loki Queries

Query logs using LogQL:

```logql
# All logs from ftgo namespace
{namespace="ftgo"}

# Error logs
{namespace="ftgo"} |= "ERROR"

# Logs from specific pod
{namespace="ftgo", pod="ftgo-api-gateway-*"}
```

### Grafana Logs Panel

Add Loki as a datasource in Grafana to visualize logs alongside metrics.

## Distributed Tracing

### Jaeger Integration

1. Configure applications to send traces
2. View traces in Jaeger UI
3. Analyze service dependencies
4. Identify performance bottlenecks

### Trace Sampling

Configure sampling rates in application configuration to control trace volume.

## Resource Requirements

### Estimated Resources

- **Prometheus**: 2-4GB RAM, 1-2 CPU
- **Grafana**: 256-512MB RAM, 250-500m CPU
- **Loki**: 512MB-1GB RAM, 500m-1 CPU
- **Jaeger**: 256-512MB RAM per component
- **Node Exporter**: 64-128MB RAM per node
- **Kube State Metrics**: 128-256MB RAM

### Storage

- **Prometheus**: 30 days retention (configurable)
- **Loki**: 10Gi PersistentVolume (expandable)

## Security

### Security Context

All monitoring components run with:
- Non-root users
- Read-only root filesystem (where applicable)
- Dropped capabilities
- RBAC for service accounts

### Network Policies

Monitoring namespace has restricted network access:
- Services accessible within cluster
- LoadBalancers for external access
- Pod Security Standards enforced

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n monitoring
```

### View Logs

```bash
kubectl logs -n monitoring deployment/prometheus
kubectl logs -n monitoring deployment/grafana
```

### Check Services

```bash
kubectl get services -n monitoring
```

### Verify Scraping

1. Access Prometheus UI
2. Go to Status → Targets
3. Verify all targets are UP

## Next Steps

1. Configure custom Grafana dashboards
2. Set up alert rules in Prometheus
3. Configure Alertmanager receivers
4. Integrate Jaeger with application services
5. Set up log retention policies
6. Configure trace sampling rates

