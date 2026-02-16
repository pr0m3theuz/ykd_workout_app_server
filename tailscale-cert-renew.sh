#!/bin/bash
# Move to the desired certificate directory
cd /var/mnt/lil_nas/icefoxneoalligator/docker/compose/couchbase/certs

# Request new certificate
tailscale cert --cert-file cert.pem --key-file privkey.pem your-machine.your-tailnet.ts.net

podman restart couchbase-server sync-gateway

