#!/bin/bash
x=1
while [ $x -le 55 ]
do
    kubectl delete pvc -l=controller=sql-gp-$x -n arc
    x=$(( $x + 1 ))
done

