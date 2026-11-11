pipeline {
    agent { label 'c1-podman' }
    options {
        disableConcurrentBuilds()
        timestamps()
        timeout(time: 60, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
        skipDefaultCheckout(true)
    }
    triggers { pollSCM('H/2 * * * *') }
    environment {
        REGISTRY = 'registry.assign.zmansour1.300.ops:5000'
        IMAGE_REPO = 'registry.assign.zmansour1.300.ops:5000/bind-secondary'
    }
    stages {
        stage('Checkout') {
            steps {
                deleteDir()
                checkout scm
                script {
                    env.IMAGE_TAG = "${env.BUILD_NUMBER}-${sh(script: 'git rev-parse --short=12 HEAD', returnStdout: true).trim()}"
                }
                sh 'test "$(id -un)" = jenkins-agent; java -version; podman --version; trivy --version'
            }
        }
        stage('Build') {
            steps {
                // Host network lets apt use C1's working lab resolver without container NAT surprises.
                sh 'podman build --pull=always --network=host -t "$IMAGE_REPO:$IMAGE_TAG" .'
            }
        }
        stage('BIND configuration check') {
            steps {
                sh '''#!/bin/bash
set -euo pipefail
keyfile=$(mktemp)
trap 'rm -f "$keyfile"' EXIT
# A disposable test key, never the lab TSIG key and never placed in the image.
printf 'key "xfer-key" { algorithm hmac-sha256; secret "%s"; };\n' "$(openssl rand -base64 32)" > "$keyfile"
# The disposable key is public test data, so bind can read it across the test mount.
chmod 644 "$keyfile"
podman run --rm --network=none --user bind --entrypoint /usr/bin/named-checkconf \
  -v "$keyfile:/etc/bind/xfer.key:ro" "$IMAGE_REPO:$IMAGE_TAG" /etc/bind/named.conf
'''
            }
        }
        stage('BIND CIS image permissions') {
            steps {
                sh '''#!/bin/bash
set -euo pipefail
podman run --rm --network=none --entrypoint /bin/sh "$IMAGE_REPO:$IMAGE_TAG" -ec '
  test -z "$(find /etc/bind /var/cache/bind /var/lib/bind /run/named -type d ! -user root -print)"
  test -z "$(find /etc/bind -type f ! -user root -print)"
  test -z "$(find /etc/bind /var/cache/bind /var/lib/bind /run/named ! -group root ! -group bind -print)"
  test -z "$(find /etc/bind -type d -perm /020 -print)"
  test -z "$(find /etc/bind /var/cache/bind /var/lib/bind /run/named -type f -perm /022 -print)"
  test -z "$(find /etc/bind /var/cache/bind /var/lib/bind /run/named -type d -perm /002 -print)"
  test "$(stat -c %G /run/named)" = bind
  test "$(stat -c %a /run/named)" = 2770
'
'''
            }
        }
        stage('Scan vulnerabilities') {
            steps {
                // Report-only policy permitted by assignment. Scanner errors still fail the job.
                sh '''#!/bin/bash
set -euo pipefail
podman save --format oci-archive -o image.tar "$IMAGE_REPO:$IMAGE_TAG"
trivy image --input image.tar --scanners vuln --severity HIGH,CRITICAL \
  --format json --output trivy-report.json --exit-code 0 --timeout 15m
jq '[.Results[]?.Vulnerabilities[]?] | length' trivy-report.json
'''
                archiveArtifacts artifacts: 'trivy-report.json', fingerprint: true
            }
        }
        stage('Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'registry-ad', usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
                    sh '''#!/bin/bash
set +x
set -euo pipefail
umask 077
authfile=$(mktemp)
trap 'rm -f "$authfile"' EXIT
printf '%s' "$REG_PASS" | podman login --authfile "$authfile" --username "$REG_USER" --password-stdin "$REGISTRY"
podman push --authfile "$authfile" "$IMAGE_REPO:$IMAGE_TAG"
'''
                }
            }
        }
    }
    post {
        always {
            sh 'rm -f image.tar'
            // Retain only this job's report, not layers from every historical build.
            sh 'if [ -n "${IMAGE_TAG:-}" ]; then podman rmi "$IMAGE_REPO:$IMAGE_TAG" || true; fi'
        }
    }
}
