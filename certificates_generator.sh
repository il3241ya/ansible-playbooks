#!/bin/bash

set -e

mkdir -p ./certs
cd ./certs

# Gen root certs
read -p "Do you want to generate the root certificate? (y/n): " generate_root_cert

if [[ "$generate_root_cert" == "y" || "$generate_root_cert" == "Y" ]]; then
  ROOT_CA_NAME="MyRootCA"
  ROOT_META="/CN=$ROOT_CA_NAME/O=Company"

  openssl genpkey -algorithm RSA -out rootCA.key -aes256 -pkeyopt rsa_keygen_bits:4096

  openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.crt -subj "$ROOT_META"
  echo "The root certificate (rootCA.crt) and the password-protected key (rootCA.key) have been successfully created."
else
  echo "Skipping root certificate generation."
fi

# Gen cert for service
mkdir -p $1_cert
cd $1_cert

META='/CN='$1' Server/L=Sity/O=COMPANY'

openssl req -new -nodes -out $1.csr -newkey rsa:4096 -keyout $1.key -subj "$META"

cat > $1.v3.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
IP.1 = $2
EOF

openssl x509 -req -in $1.csr -CA ../rootCA.crt -CAkey ../rootCA.key -CAcreateserial -out $1.crt -days 825 -sha256 -extfile $1.v3.ext
