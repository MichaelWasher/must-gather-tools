#!/bin/bash 
#
# A small script for setting the dns-operator an unmanaged state and increasing the logs for the DNS Pods
#
# 
OVERRIDES=$(oc get clusterversion version -o jsonpath="{.spec.overrides}")
if [[ $OVERRIDES == "" ]]; then
  echo "Configure list to be present"
	oc patch clusterversion version --type json -p '
  - op: add
	path: /spec/overrides
	value: []
'
fi

echo "Set the DNS Operator to Unmanaged"
oc patch clusterversion version --type json -p "
- op: add
  path: /spec/overrides/-
  value:
    kind: Deployment
    group: apps/v1
    name: dns-operator
    namespace: openshift-dns-operator
    unmanaged: true
"

echo "Scale down the DNS operator"
oc scale deploy/dns-operator --replicas=0 -n openshift-dns-operator

echo "Add debug logging to Corefile"
oc get cm -n openshift-dns dns-default -o json | sed "s/errors/errors\\\\n    log/gi" | oc replace -f -

echo "Restart DNS Pods"
for POD in $(oc get pods -n openshift-dns -o name); do
  echo "Restarting ${POD:4}"
  oc delete $POD
done
