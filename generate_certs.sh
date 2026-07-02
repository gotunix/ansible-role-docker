#!/bin/bash

# Exit on error
set -e

echo "Generating Docker TLS Certificates..."

# Create a temporary directory
TMPDIR=$(mktemp -d)
cd "$TMPDIR"

# 1. Generate CA
echo "1/3 Generating Certificate Authority (CA)..."
openssl genrsa -out ca-key.pem 4096 2>/dev/null
openssl req -new -x509 -days 3650 -key ca-key.pem -sha256 -out ca.pem -subj "/CN=Docker-CA" 2>/dev/null

# 2. Generate Server Certs
echo "2/3 Generating Server Certificates..."
openssl genrsa -out server-key.pem 4096 2>/dev/null
openssl req -subj "/CN=*" -sha256 -new -key server-key.pem -out server.csr 2>/dev/null
echo "subjectAltName = DNS:*,IP:127.0.0.1,IP:0.0.0.0" > extfile.cnf
echo "extendedKeyUsage = serverAuth" >> extfile.cnf
openssl x509 -req -days 3650 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -extfile extfile.cnf 2>/dev/null

# 3. Generate Client Certs
echo "3/3 Generating Client Certificates..."
openssl genrsa -out key.pem 4096 2>/dev/null
openssl req -subj '/CN=docker-client' -new -key key.pem -out client.csr 2>/dev/null
echo "extendedKeyUsage = clientAuth" > extfile-client.cnf
openssl x509 -req -days 3650 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out cert.pem -extfile extfile-client.cnf 2>/dev/null

# 4. Format Output for Ansible vars/main.yml
cat <<EOF > output.yml
---
docker_tls_ca_cert: |
$(cat ca.pem | sed 's/^/  /')

docker_tls_server_cert: |
$(cat server-cert.pem | sed 's/^/  /')

docker_tls_server_key: |
$(cat server-key.pem | sed 's/^/  /')

# The below client certificates are for your personal laptop to connect remotely
# They won't be copied to the server natively unless you want a local client testing
docker_tls_client_cert: |
$(cat cert.pem | sed 's/^/  /')

docker_tls_client_key: |
$(cat key.pem | sed 's/^/  /')
EOF

echo ""
echo "=============================================="
echo "          CERTIFICATES GENERATED!             "
echo "=============================================="
echo ""
echo "Please copy the following YAML block and replace the contents of"
echo "roles/docker/vars/main.yml or paste it into your host_vars:"
echo ""
cat output.yml

# Cleanup
cd - > /dev/null
rm -rf "$TMPDIR"
