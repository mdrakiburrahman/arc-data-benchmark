# Arc Data Benchmark - Monitoring and Scalability

A terraform-built scalable environment for coming up with a set of back-of-the-napkin calculations to determine guidance on topics like PV sizing, the number of supported SQL instances per Controller, retention settings and anything else related to **scalability**.

## Table of Contents <!-- omit in toc -->
- [A](#A)
  - [B](#B)

---

# TO-DO

- [ ] Increase Core limit in a region
- [ ] Terraform AKS setup with:
  - [ ] Container Insights and Log Analytics
  - [ ] Plug-and-play new `NodePools`
- [ ] `az` Data Controller Deploy with Kafka (Indirect mode)
- [ ] Argo CD hookup with this repo
  - [ ] Weavescope
  - [ ] SQL MI
  - [ ] Kafdrop

---

# Dashboards/endpoints

There are a few different **temporary** monitoring tools deployed in this environment, below are the endpoints.

| Tech | Public Endpoint | Credentials       | Purpose |
| ---- | --------------- | ----------------- | ------- |
| A    | `0.0.0.0:3000`  | Username:Password | B       |

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

# Useful Kusto queries

## Query 1: TBD

```sql
SELECT * FROM FOO
```

Diagram: TBD

--- 
# Misc notes


--- 
# Gotchas/lessons-learned

TBD