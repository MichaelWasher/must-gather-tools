#!/bin/bash 
#
# A small script for setting the dns-operator back into a managed stage
#
# Cleanup
INDEX=$(oc get clusterversion version -o json  | jq '.spec.overrides | map(.name == "dns-operator") | index(true)')
if [[ ! $INDEX == "null" ]]; then
  echo "Removing the DNS Operator override"
  oc patch clusterversion version --type=json -p="[{'op': 'remove', 'path': '/spec/overrides/$INDEX'}]"
else
  echo "DNS Operator override not found. Doing nothing..."
fi