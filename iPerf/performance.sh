#!/bin/bash
set -euf -o pipefail

OUTPUT_DIR=/must-gather

MNODES=$(oc get node --selector='node-role.kubernetes.io/master' -o name)

for NODE in $MNODES
do
 echo "FIO $NODE"
 oc debug $NODE -- chroot /host podman run --volume /var/lib/etcd:/var/lib/etcd:Z quay.io/openshift-scale/etcd-perf | tee "${OUTPUT_DIR}/${NODE:5}_fio.log"
done

for ANODE in $MNODES
do
  ANODE_ADDRESS=$( oc get $ANODE -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}' )

  #Start iperf server
  oc debug $ANODE --image=quay.io/tidawson/alpine-iperf3 -- iperf3 -s | tee "${OUTPUT_DIR}/${ANODE:5}_iperf_server.log" &
  server_pid=$!

  for BNODE in $(sed "s|$ANODE||" <<<$MNODES)
  do
    echo "PING+IPERF $BNODE -> $ANODE ($ANODE_ADDRESS)"

    oc debug $BNODE -- ping -c5 $ANODE_ADDRESS | tee "${OUTPUT_DIR}/${BNODE:5}_ping_to_${ANODE:5}.log"
    oc debug $BNODE --image=quay.io/tidawson/alpine-iperf3 -- iperf3 -t 60 -c $ANODE_ADDRESS | tee "${OUTPUT_DIR}/${BNODE:5}_iperf_client_to_${ANODE:5}.log"
  done

  #Cleanup debug pod on server side of iperf
  kill $server_pid

done

