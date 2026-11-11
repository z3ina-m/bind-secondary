[README.md](https://github.com/user-attachments/files/34670583/README.md)
# bind-secondary - OPS300 Assignment 1

Lab secondary DNS image for lab.zmansour1.300.ops and 18.168.192.in-addr.arpa.
Primary DNS: 192.168.18.10

Jenkins polls main every two minutes, checks out on C1 (label c1-podman), builds with
rootless Podman, validates the BIND configuration using a disposable test TSIG key,
scans the exact built OCI archive, and pushes a BUILD_NUMBER-COMMIT_SHA tag to the
private registry. The Jenkins controller has zero executors.

Credentials used by Jenkins: registry-ad (username/password for registry-ci), and
c1-ssh (SSH private key attached to the node configuration). No credentials belong
in this repository. Supply the real /etc/bind/xfer.key at runtime with a read-only
mount. Mount a writable /var/cache/bind volume with ownership matching the image's
bind user. The pipeline builds/pushes; it does not redeploy the existing C1-C3 services.

## Build

podman build --pull=always --network=host -t bind-secondary:test .

Only Dockerfile and the three named.conf files enter the build context, as enforced
by .dockerignore. Do not upload TSIG files, private keys, lab reports, or registry
configuration containing AD bind credentials. Existing published lab images that
copied xfer.key remain sensitive; replacing the Dockerfile does not remove keys from
old images. Coordinate any old-key rotation across DNS and C1-C3 separately.
