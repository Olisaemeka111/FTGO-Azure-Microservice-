# Action Plan to Fix All Pod Errors

## Root Cause Analysis

### 1. **Kafka Crash (182 restarts)**
**Error:**
```
Found directory /var/lib/kafka/data/lost+found, 'lost+found' is not in the form of topic-partition
```

**Why This Happens:**
- Linux filesystems automatically create a `lost+found` directory when a filesystem is initialized
- Kafka expects ONLY topic-partition directories in its data directory
- When Kafka starts, it scans `/var/lib/kafka/data` and finds `lost+found`, which doesn't match the expected pattern
- Kafka fails to start because it cannot parse `lost+found` as a topic-partition name

**Fix Required:**
- Add an init container to remove `lost+found` before Kafka starts, OR
- Configure Kafka to ignore the `lost+found` directory, OR
- Delete the PVC and recreate it (clean slate)

---

### 2. **Application Services Crash (7 services)**
**Error:**
```
Access to DialectResolutionInfo cannot be null when 'hibernate.dialect' not set
```

**Why This Happens:**
- Applications try to connect to MySQL databases that **don't exist**:
  - `eventuate` (used by: Restaurant, Order, Kitchen, Accounting, Order History)
  - `ftgo_consumer_service` (used by: Consumer Service)
- Hibernate cannot determine the database dialect because:
  1. Connection fails (database doesn't exist)
  2. No explicit dialect configured in environment variables
- MySQL only has default databases: `information_schema`, `mysql`, `performance_schema`, `sys`

**Fix Required:**
1. Create missing databases in MySQL
2. Create database users with proper permissions
3. Add Hibernate dialect configuration to all services
4. Ensure databases are created before services start

---

## Action Plan

### Phase 1: Fix Kafka (Priority: HIGH)

**Option A: Add Init Container (Recommended)**
```yaml
initContainers:
  - name: remove-lost-found
    image: busybox:1.35
    command: ['sh', '-c', 'rm -rf /var/lib/kafka/data/lost+found || true']
    volumeMounts:
      - name: ftgo-kafka-persistent-storage
        mountPath: /var/lib/kafka/data
```

**Option B: Clean Volume (Quick Fix)**
```bash
# Delete Kafka StatefulSet and PVC, then redeploy
kubectl delete statefulset ftgo-kafka -n ftgo
kubectl delete pvc ftgo-kafka-persistent-storage-ftgo-kafka-0 -n ftgo
# Redeploy through pipeline
```

**Files to Modify:**
- `ftgo-application/deployment/kubernetes/aks/ftgo-kafka-aks.yml`

---

### Phase 2: Create MySQL Databases (Priority: CRITICAL)

**Create Init Job:**
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: ftgo-mysql-init
  namespace: ftgo
spec:
  template:
    spec:
      restartPolicy: OnFailure
      containers:
      - name: mysql-init
        image: mysql:8.0
        command:
        - /bin/bash
        - -c
        - |
          mysql -h ftgo-mysql -u root -prootpassword <<EOF
          CREATE DATABASE IF NOT EXISTS eventuate;
          CREATE DATABASE IF NOT EXISTS ftgo_consumer_service;
          CREATE DATABASE IF NOT EXISTS ftgo_order_service;
          CREATE DATABASE IF NOT EXISTS ftgo_restaurant_service;
          CREATE DATABASE IF NOT EXISTS ftgo_kitchen_service;
          CREATE DATABASE IF NOT EXISTS ftgo_accounting_service;
          CREATE DATABASE IF NOT EXISTS ftgo_order_history_service;
          
          -- Create users and grant permissions
          CREATE USER IF NOT EXISTS 'mysqluser'@'%' IDENTIFIED BY 'mysqlpw';
          GRANT ALL PRIVILEGES ON eventuate.* TO 'mysqluser'@'%';
          GRANT ALL PRIVILEGES ON ftgo_consumer_service.* TO 'ftgo_consumer_service_user'@'%';
          FLUSH PRIVILEGES;
          EOF
```

**Files to Create:**
- `ftgo-application/deployment/kubernetes/aks/ftgo-mysql-init.yml`

**Files to Modify:**
- `.github/workflows/build-and-push.yml` - Add step to run init job before deploying services

---

### Phase 3: Add Hibernate Dialect Configuration (Priority: HIGH)

**Add to all application services:**
```yaml
env:
  - name: SPRING_JPA_DATABASE_PLATFORM
    value: org.hibernate.dialect.MySQL8Dialect
  # OR
  - name: SPRING_JPA_PROPERTIES_HIBERNATE_DIALECT
    value: org.hibernate.dialect.MySQL8Dialect
```

**Files to Modify:**
- `ftgo-application/deployment/kubernetes/aks/ftgo-services-aks.yml`
  - Consumer Service
  - Restaurant Service
  - Order Service
  - Kitchen Service
  - Accounting Service
  - Order History Service

---

### Phase 4: Update Pipeline (Priority: MEDIUM)

**Add to `.github/workflows/build-and-push.yml`:**
```yaml
- name: Wait for MySQL to be ready
  run: |
    kubectl wait --for=condition=ready pod/ftgo-mysql-0 -n ftgo --timeout=300s

- name: Initialize MySQL databases
  run: |
    kubectl apply -f ftgo-application/deployment/kubernetes/aks/ftgo-mysql-init.yml
    kubectl wait --for=condition=complete job/ftgo-mysql-init -n ftgo --timeout=300s || true
```

---

## Implementation Steps

1. **Fix Kafka** (15 minutes)
   - Add init container to `ftgo-kafka-aks.yml`
   - Commit and push
   - Pipeline will redeploy Kafka

2. **Create MySQL Init Job** (20 minutes)
   - Create `ftgo-mysql-init.yml`
   - Update pipeline to run init job
   - Commit and push
   - Pipeline will create databases

3. **Add Hibernate Dialect** (15 minutes)
   - Add dialect env var to all services in `ftgo-services-aks.yml`
   - Commit and push
   - Pipeline will redeploy services

4. **Test** (10 minutes)
   - Verify Kafka starts successfully
   - Verify databases exist
   - Verify services connect to databases
   - Check pod status

**Total Estimated Time: 60 minutes**

---

## Verification Commands

```bash
# Check Kafka
kubectl logs -n ftgo ftgo-kafka-0

# Check databases
kubectl exec -n ftgo ftgo-mysql-0 -- mysql -u root -prootpassword -e "SHOW DATABASES;"

# Check service logs
kubectl logs -n ftgo ftgo-accounting-service-<pod-id>

# Check all pods
kubectl get pods -n ftgo
```

---

## Expected Outcome

After fixes:
- ✅ Kafka pod: Running (no more lost+found error)
- ✅ All databases: Created in MySQL
- ✅ Application services: Can connect to databases
- ✅ Hibernate: Dialect configured correctly
- ✅ All pods: Running and Ready

