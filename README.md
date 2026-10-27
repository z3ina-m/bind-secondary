# bind-secondary

OPS300 Assignment 1.

This repository contains the build source for a BIND secondary DNS image.

Jenkins will poll this repository, build the image using Podman on
a separate SSH agent, scan it for vulnerabilities, and push it to
the private registry using a unique build tag.

Passwords, TSIG secrets, SSH private keys, and registry credentials
are supplied separately and are not stored in this repository.
