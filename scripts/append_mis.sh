#!/bin/bash
mis=55
x=1
file='/workspaces/arc-data-benchmark/kubernetes/sqlmi/sql-gp.yaml'
while [ $x -le 55 ]
do
  cat >> $file <<EOF
apiVersion: sql.arcdata.microsoft.com/v2
kind: SqlManagedInstance
metadata:
  name: sql-gp-$x
  namespace: arc
spec:
  backup:
    retentionPeriodInDays: 7
  dev: true
  tier: GeneralPurpose
  forceHA: "true"
  licenseType: LicenseIncluded
  replicas: 1
  scheduling:
    default:
      resources:
        limits:
          cpu: "1"
          memory: 2Gi
        requests:
          cpu: "1"
          memory: 2Gi
  security:
    adminLoginSecret: sql-login-secret
  services:
    primary:
      type: LoadBalancer
      port: 31433
  storage:
    backups:
      volumes:
        - className: azurefile
          size: 1Gi
    data:
      volumes:
        - className: managed-premium
          size: 1Gi
    datalogs:
      volumes:
        - className: managed-premium
          size: 1Gi
    logs:
      volumes:
        - className: managed-premium
          size: 1Gi
EOF
  echo "---" >> /workspaces/arc-data-benchmark/kubernetes/sqlmi/sql-gp.yaml
  x=$(( $x + 1 ))
done

# Remove the last ---
tail -n 1 "$file" | wc -c | xargs -I {} truncate "$file" -s -{}
