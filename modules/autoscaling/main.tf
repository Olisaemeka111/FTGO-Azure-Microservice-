# Auto Scaling Module - For Standard AKS
# Note: AKS has built-in autoscaling via node pool settings
# This module provides HPA configuration examples and documentation

# Note: Metrics Server and Cluster Autoscaler are built into AKS
# - Metrics Server: Pre-installed in all AKS clusters
# - Cluster Autoscaler: Configured via node pool enable_auto_scaling settings
# - Node pool autoscaling: Already configured in aks-workload module

# This module now serves as documentation and example configurations
# Actual autoscaling is handled by AKS node pool settings
# Outputs are defined in outputs.tf
