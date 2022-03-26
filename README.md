# Arc Data Benchmark - Monitoring and Scalability

A terraform-built scalable environment for coming up with a set of back-of-the-napkin calculations to determine guidance on topics like PV sizing, the number of supported SQL instances per Controller, retention settings and anything else related to **scalability**.

## Table of Contents <!-- omit in toc -->

- [A](#A)
  - [B](#B)

---

# TO-DO

- [x] Increase Core limit in a region
- [x] Terraform AKS setup with:
  - [x] Container Insights and Log Analytics
  - [x] Plug-and-play new `NodePools`
- [x] **`az`** Data Controller Deploy with Kafka (Indirect mode)
- [x] Argo CD hookup with this repo
  - [x] ArgoCD setup
  - [x] Weavescope
  - [x] SQL MI(s)
  - [ ] Kafdrop
- [ ] Experiments
  - [x] **Experiment 1**: Effect of nodes (since `metricsdc` runs as `DaemonSet`) on Log Volumes - ✔
  - [x] **Experiment 2**: Effect of instances on Log Volumes
  - [ ] **Experiment 3**: Effect of replicas (1, 2, 3) on Log Volumes

---

# Dashboards/endpoints

There are a few different monitoring tools deployed in this environment, below are the endpoints:

| Tech       | Expose endpoint                                                        | Endpoint                 | Credentials            | Purpose                  |
| ---------- | ---------------------------------------------------------------------- | ------------------------ | ---------------------- | ------------------------ |
| Grafana    | `kubectl port-forward service/metricsui-external-svc -n arc 3000:3000` | `https://127.0.0.1:3000` | admin:acntorPRESTO!    | Data Services Metrics    |
| Kibana     | `kubectl port-forward service/logsui-external-svc -n arc 5601:5601`    | `https://127.0.0.1:5601` | admin:acntorPRESTO!    | Data Services Logs       |
| ArgoCD     | `kubectl port-forward service/argocd-server -n argocd 80:80`           | `https://127.0.0.1:80`   | admin:rnHFlEtXSwf5aDMx | CICD interface           |
| Weavescope | `kubectl port-forward service/weave-scope-app -n weave 81:80`          | `http://127.0.0.1:81`    | None                   | K8s monitoring interface |

---

## Infrastructure Deployment

### Dev Container

The folder `.devcontainer` has necessary tools (terraform, azure-cli, kubectl etc) to get started on this demo with [Remote Containers](https://code.visualstudio.com/docs/remote/containers).

### Terraform apply

The following script deploys the environment with Terraform:

```bash
# ---------------------
# ENVIRONMENT VARIABLES
# For Terraform
# ---------------------
# Secrets
export TF_VAR_SPN_CLIENT_ID=$spnClientId
export TF_VAR_SPN_CLIENT_SECRET=$spnClientSecret
export TF_VAR_SPN_TENANT_ID=$spnTenantId
export TF_VAR_SPN_SUBSCRIPTION_ID=$subscriptionId

# Module specific
export TF_VAR_resource_group_name='raki-jake-arc-benchmark-rg'

# ---------------------
# DEPLOY TERRAFORM
# ---------------------
cd terraform
terraform init
terraform plan
terraform apply -auto-approve

# ---------------------
# ‼ DESTROY ENVIRONMENT
# ---------------------
terraform destory
```

---

## Arc deployment

Before onboarding Argo, we onboard the Data Controller and get Kafka up with a manual workaround.

### Arc Data Services (without Kafka)

```bash
cd azure-arc

# Deployment variables
export random=$(echo $RANDOM | md5sum | head -c 5; echo;)
export resourceGroup=$TF_VAR_resource_group_name
export aksName='aks-benchmark'
export AZDATA_USERNAME='boor'
export AZDATA_PASSWORD='acntorPRESTO!'
export arcDcName='arc-dc'
export azureLocation='eastus'
export AZDATA_LOGSUI_USERNAME=$AZDATA_USERNAME
export AZDATA_METRICSUI_USERNAME=$AZDATA_USERNAME
export AZDATA_LOGSUI_PASSWORD=$AZDATA_PASSWORD
export AZDATA_METRICSUI_PASSWORD=$AZDATA_PASSWORD

# Login as service principal
az login --service-principal --username $spnClientId --password $spnClientSecret --tenant $spnTenantId
az account set --subscription $subscriptionId

# Get kubeconfig
az aks get-credentials --resource-group $TF_VAR_resource_group_name --name $aksName

# Create custom profile for AKS
az arcdata dc config init --source azure-arc-aks-default-storage --path custom --force

# Create with the AKS profile
az arcdata dc create --path './custom' \
                     --k8s-namespace arc \
                     --name $arcDcName \
                     --subscription $subscriptionId \
                     --resource-group $resourceGroup \
                     --location $azureLocation \
                     --connectivity-mode indirect \
                     --use-k8s

# Controller gets deployed, but no Kafka in this March release.

```

### Arc Data Services (_with_ Kafka)

We first have to delete the Data controller because `spec.monitoring.enablekafka=true` is immutable as of March 2022, then onboard it with Kafka from YAML definitions:

```bash
# Delete controller
kubectl delete datacontroller arc-dc -n arc

# Apply pre-canned YAMl file with spec.monitoring.enablekafka=true
kubectl apply -f /workspaces/arc-data-benchmark/azure-arc/controller-kafka/controller-kafka.yaml

```

---

## ArgoCD deployment

```bash
# Argo namespace
kubectl create namespace argocd

# Deploy Argo
kubectl apply -n argocd -f /workspaces/arc-data-benchmark/kubernetes/argocd/argo.yaml

# Patch Service to be externally accessible
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Get secret
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

---

## Weavescope

Follow the simple steps here to get Weavescope onboarded: https://www.buchatech.com/2021/12/deploy-app-to-azure-kubernetes-service-via-argo-cd/

**YAML file:** `/workspaces/arc-data-benchmark/kubernetes/argocd-config/weavescope.yaml`
![Weavescope deployed](_images/weavescope-argocd.png)

And we see the UI:
![Weavescope UI](_images/weavescope.png)

---

## SQL MIs

```bash
kubectl apply -f /workspaces/arc-data-benchmark/kubernetes/argocd-config/sqlmi.yaml -n argocd
```

And we see the SQL MI resources in the UI:
![SQL MI](_images/sqlmi-argocd.png)

---

# Experiment setup

### Effect of logs

- **Experiment 1**: Effect of nodes (since `metricsdc` runs as `DaemonSet`) on Log Volumes - ✔
- **Experiment 2**: Effect of instances on Log Volumes
- **Experiment 3**: Effect of replicas (1, 2, 3) on Log Volumes

### Max limits per controller

- **Experiment 4**: Max # of MIs you can deploy at once (assume infra is there)
- **Experiment 5**: Max # of MIs a Controller can ramp up to at most (assume infra is there)
- **Experiment 6**: Max # of MIs you can upgrade at once

### Things we want to track

- Nodes - number, sizes
- MIs - number, replicas, size
- Deployment timestamp start, end

### The equation

We want to model this for all of our PVCs

```text
data-control
data-controldb
data-kafka-broker-0
data-kafka-zookeeper-0
data-logsdb-0
data-metricsdb-0
logs-control
logs-controldb
logs-kafka-broker-0
logs-kafka-zookeeper-0
logs-logsdb-0
logs-metricsdb-0
```

![Equation](_images/equation.png)

---

### Experiment steps

> Script to generate query result timestamp: `$Date = Get-Date; $Date.ToString() -replace(":", "-") -replace("/", "-")`

#### **Experiment 1**: Effect of nodes (since `metricsdc` runs as `DaemonSet`) on Log Volumes - ✔

| #   | Timestamp (UTC)      | Step performed                              | Clusters | Nodes (no Autoscale) | MIs | Query results                        | Comments                                          |
| --- | -------------------- | ------------------------------------------- | -------- | -------------------- | --- | ------------------------------------ | ------------------------------------------------- |
| 1   | 2022-03-23T00:00:00Z | Deployed base Terraform module + Controller | 1        | 2*DS3_V2, 0*DS5_v2   | 0   | 2022-03-22 9-10-22 PM.csv            | Baseline setup for Arc Indirect                   |
| 2   | 2022-03-23T01:26:00Z | Scaled up node to 3                         | 1        | 3*DS3_V2, 0*DS5_v2   | 0   | 2022-03-22 9-40-16 PM.csv            | Looking at impact of nodes increase on log volume |
| 3   | 2022-03-23T01:47:00Z | Scaled up node to 10                        | 1        | 10*DS3_V2, 0*DS5_v2  | 0   | 2022-03-22 9-56-14 PM.csv            | Looking at impact of nodes increase on log volume |
| 4   | 2022-03-23T02:05:00Z | Scaled up node to 25 (max)                  | 1        | 25*DS3_V2, 0*DS5_v2  | 0   | 2022-03-22 10-34-02 PM.csv           | Looking at impact of nodes increase on log volume |
| 5   | 2022-03-23T02:34:00Z | None                                        | 1        | 25*DS3_V2, 0*DS5_v2  | 0   | 2022-03-22 10-42-30 PM_nodes_e2e.csv | Final snapshot of nodes                           |
| 6   | 2022-03-23T02:34:00Z | Scaled down node to 2                       | 1        | 2*DS3_V2, 0*DS5_v2   | 0   | None                                 | Back down to normal                               |

#### **Experiment 2**: Effect of SQL MIs on Log Volumes

| #   | Timestamp (UTC)      | Step performed      | Clusters | Nodes (no Autoscale) | MIs | Query results              | Comments                                 |
| --- | -------------------- | ------------------- | -------- | -------------------- | --- | -------------------------- | ---------------------------------------- |
| 1   | 2022-03-23T12:00:00Z | None                | 1        | 2*DS3_V2, 0*DS5_v2   | 0   | 2022-03-23 8-48-54 AM.csv  | Baseline setup before MI deploy          |
| 2   | 2022-03-23T12:59:00Z | +1 GP MI            | 1        | 2*DS3_V2, 0*DS5_v2   | 1   | 2022-03-24 8-30-00 AM.csv  | Deployed +1 MI                           |
| 3   | 2022-03-24T12:46:00Z | +1 GP MI            | 1        | 2*DS3_V2, 0*DS5_v2   | 2   | 2022-03-24 9-09-55 PM.csv  | Deployed +1 MI                           |
| 4   | 2022-03-25T01:24:00Z | +1 DS5_v2 node      | 1        | 2*DS3_V2, 1*DS5_v2   | 2   | 2022-03-24 9-47-03 PM.csv  | Deployed +1 Node since out of memory     |
| 5   | 2022-03-25T01:58:00Z | +5 GP MI            | 1        | 2*DS3_V2, 1*DS5_v2   | 7   | 2022-03-24 10-31-04 PM.csv | Deployed +5 MIs to see if 5x logs slope  |
| 6   | 2022-03-25T02:47:00Z | -7 GP MIs - 1 nodes | 1        | 2*DS3_V2, 0*DS5_v2   | 0   | None                       | Removed MIs and big node as test is over |

#### **Experiment 3**: Effect of replicas (1, 2, 3) on Log Volumes

| #   | Timestamp (UTC)      | Step performed         | Clusters | Nodes (no Autoscale) | MIs         | Query results              | Comments                                     |
| --- | -------------------- | ---------------------- | -------- | -------------------- | ----------- | -------------------------- | -------------------------------------------- |
| 0   | 2022-03-26T13:30:00Z | None                   | 1        | 2*DS3_V2, 0*DS5_v2   | 0           | 2022-03-26 10-04-40 AM.csv | Baseline setup before node scale             |
| 1   | 2022-03-26T13:55:00Z | +1 DS3_v2 node         | 1        | 3*DS3_V2, 0*DS5_v2   | 0           | 2022-03-26 10-12-30 AM.csv | Spin up node for replica test                |
| 2   | 2022-03-26T14:21:00Z | +1 GP MI               | 1        | 3*DS3_V2, 0*DS5_v2   | 1x1 replica | 2022-03-26 1-13-44 PM.csv  | Deployed +1 MI, 1 Replica                    |
| 3   | 2022-03-26T00:00:00Z | -1 GP MI, +1 BC MI x 2 | 1        | 3*DS3_V2, 0*DS5_v2   | 1x2 replica | TBD                        | Deleted previous, Deployed +1 BC, 2 Replicas |
| 4   | 2022-03-26T00:00:00Z | -1 BC MI, +1 BC MI x 3 | 1        | 3*DS3_V2, 0*DS5_v2   | 1x3 replica | TBD                        | Deleted previous, Deployed +1 BC, 3 Replicas |

---

# Useful snippets

## Delete stale PVCs
```bash
kubectl delete pvc -l=controller=sql-gp-1 -n arc
```

## Query 1: Grab usage metrics for all PVCs

The following query returns all PVCs:

```sql
let startDateTime = todatetime('2022-03-24T12:46:00Z');
let endDateTime = startDateTime + 12h;
let trendBinSize = 1m;

KubePodInventory
| where TimeGenerated < endDateTime
| where TimeGenerated >= startDateTime
| where Namespace in ('arc' )
| distinct PodUid
| join hint.strategy=shuffle (
    InsightsMetrics
    | where TimeGenerated < endDateTime + trendBinSize
    | where TimeGenerated >= startDateTime - trendBinSize
    | where Namespace == 'container.azm.ms/pv'
    | where Name == 'pvUsedBytes'
    | extend Tags = todynamic(Tags)
    | extend CapacityMB = Tags.pvCapacityBytes/1048576, PodUid = tostring(Tags.podUid), PodName = Tags.podName, VolumeMB = Tags.volume/1048576, PvUsedMB = Val/1048576
    | extend UsagePercent = round((PvUsedMB / CapacityMB) * 100, 2)
    | extend PvcName = tostring(Tags.pvcName), VolumeName = Tags.volumeName
    | project TimeGenerated, Computer, PodName, PvcName, VolumeName, VolumeMB, PvUsedMB, CapacityMB, UsagePercent, PodUid
    )
    on PodUid
| project TimeGenerated, Computer, PodName, PvcName, VolumeName, VolumeMB, PvUsedMB, CapacityMB, UsagePercent
```

## Query 2: Center around the time when a change was executed (e.g. node spinup)

```sql
let changeTime = todatetime('2022-03-23T01:26:00Z');
let startDateTime = changeTime - 5m;
let endDateTime = changeTime + 15m;
let trendBinSize = 1m;
```

---

## Observations and Kusto graphs

### **Experiment 1**: Effect of nodes (since `metricsdc` runs as `DaemonSet`) on Log Volumes - ✔

Baseline - `2022-03-22 9-10-22 PM.csv`:
![1](_images/2022-03-22%209-10-22%20PM.png)

Scaled up node to 3 - `2022-03-22 9-40-16 PM.csv`:
![2](_images/2022-03-22%209-40-16%20PM.png)

Scaled up node to 10 - `2022-03-22 9-56-14 PM.csv`:
![3](_images/2022-03-22%209-56-14%20PM.png)

Scaled up node to 25 - ``:
![3.5](_images/nodepool-max.png)
![4](_images/2022-03-22%2010-34-02%20PM.png)

Start to end view:
![5](_images/nodes-end-to-end.png)

### **Experiment 2**: Effect of SQL MIs on Log Volumes - ✔

Baseline - `2022-03-23 8-48-54 AM.csv`:
![1](_images/sqlmi-baseline.png)

Scaled up MI to 1, running for ~24 hours - `2022-03-22 9-40-16 PM.csv`:
![2](_images/2node-1mi.png)

Scaled up MI to 2, running for ~12 hours - `2022-03-24 9-09-55 PM.csv`:
![2](_images/2node-2mi.png)

Zooming in on the spike:
![3](_images/2node-2mi-spike.png)

Scaled up MI to 7 and nodes to 3, running for ~15 mins - `2022-03-24 10-31-04 PM.csv`:
![3](_images/3node-7mi.png)

Start to end view:
![5](_images/node-e2e-view.png)

### **Experiment 3**: Effect of replicas (1, 2, 3) on Log Volumes

Baseline - `2022-03-26 10-04-40 AM.csv`:

> Note that even though we haven't had any SQL MIs running past few days `Nodes: 2*DS3_V2, 0*DS5_v2 | MI: 0`, baseline PVC usage has been going up
> ![0](_images/baseline-creep.png)

Baseline with 3 Nodes, 0 MIs - `2022-03-26 10-12-30 AM.csv`:
![1](_images/3node-0mis.png)

1x1 Replica (GP) - `2022-03-26 1-13-44 PM.csv`:
![2](_images/3node-1mi1repl.png)

1x2 Replica (BC) - `TBD`:

1x3 Replica (BC) - `TBD`:

---

## Calculations

---

# Questions to Answer

## `logsdb` volume

#### Q: How should you size your `logsdb` volume?

A: TBD

#### Q: What volume of logs are created on cluster deployment?

A: TBD

#### Q: At what rate does the control plane produce logs with no data service instances and no errors?

A: TBD

#### Q: What volume of logs are created on sqlmi creation?

A: TBD

#### Q: At what rate are sqlmi logs produced over time per instance? Per replica?

A: TBD

#### Q: All of the above, but for Kafka too

A: TBD

#### Q: How should you size your `metricsdb` volume?

A: TBD

#### Q: At what rate are `metricsdc` logs produced per node? Is this significant enough to be factored into the calculation?

A: TBD

---

## Log retention settings

#### Q: How should you set your logs retention settings?

A: TBD

#### Q: This is basically the same question as how to size your logsdb volume. Retention = volume_size / avg_logs_per_day

A: TBD

#### Q: Also note this feature is in progress (planned default is two weeks)

A: TBD

---

## Scalability

#### Q: How many sqlmi instances/replicas can you run per data controller? (Assuming logs/metrics retention is not the bottleneck)

> Not sure what specific benchmarks we need for this beyond just slowly increasing on a big cluster and seeing what happens.

A: TBD

#### Q: What’s the rate of collection per day per `sqlmi` CR instance? Per replica?

A: TBD

#### Q: What is the rate of metrics collection per node? (when enabled)

A: TBD

#### Q: Should we be piping all logs files into elastic/influx? What can we exclude?

A: TBD

#### Q: Should we offer settings to control the level of logs collection on a per file basis?

A: TBD

#### Q: Can we add info/debug/error level metadata to every log file?

A: TBD

---

## Misc

#### Q: How can we stop errors from spamming the logs?

A: TBD

#### Q: How do customers resize monitoring resources as we increase our collection? (e.g. `PV` resize)

A: TBD

#### Q: Does Indirect VS Direct mode increase the amount of logs generated for the same setup?

A: TBD

#### Q: Does Transactions happening on an MI (e.g. HammerDB) increase the amount of logs/metrics generated?

A: TBD

---

# Misc notes

---

# Gotchas/lessons-learned

TBD
