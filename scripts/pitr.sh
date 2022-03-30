cat <<EOF | kubectl apply -f -
apiVersion: tasks.sql.arcdata.microsoft.com/v1
kind: SqlManagedInstanceRestoreTask                 
metadata:                                       
  name: pitr1-invalid
  namespace: arc
spec:                                           
  source:                                       
    name: sql-gp-1                               
    database: pitr_test                         
  restorePoint: "2000-03-30T15:05:35Z" # Timestamp 22 years ago
  destination:                                  
    name: sql-gp-1                          
    database: pitr_restore_invalid
  dryRun: False
EOF