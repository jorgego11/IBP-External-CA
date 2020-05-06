#!/bin/bash

##
# Copyright IBM Corporation 2020
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##

### Functions
function log {
    echo "[$(date +"%m-%d-%Y %r")]: $*"
}


# get config file and properties
CONFIG_FILE=$1
log "CONFIG_FILE is: $CONFIG_FILE"

ORG_DISPLAY_NAME=`jq -r .ORG_DISPLAY_NAME "$CONFIG_FILE"`
log "ORG_DISPLAY_NAME is: $ORG_DISPLAY_NAME"

MSP_ID=`jq -r .MSP_ID "$CONFIG_FILE"`
log "MSP_ID is: $MSP_ID"

HOST_URL=`jq -r .HOST_URL "$CONFIG_FILE"`
log "HOST_URL is: $HOST_URL"


# Source corresponding installation script based on PLATFORM
log "Starting creating MSP with external CA..."

# Remove previous install
rm -r ./rootExCA

# Create new install
mkdir ./rootExCA
mkdir ./rootExCA/ca ./rootExCA/tlsca


log "STEP 1 ################ Lets do Root CA ################"  
cd ./rootExCA/ca

mkdir certs crl newcerts private csr
chmod 700 private
touch index.txt
echo 1000 > serial
cp ../../ssl-config/opensslRootCA.cnf .

# Create the root CA private key
# private key is not encripted, otherwise add    -aes128 | -aes192 | -aes256 | -des | -des3    -passout <passpharse>
openssl ecparam -genkey -name prime256v1 -noout -out ./private/ca.key.pem


# Create the root CA certificate
openssl req -config opensslRootCA.cnf \
      -key private/ca.key.pem \
      -batch -new -x509 -days 7300 -sha256 -extensions v3_ca \
      -out certs/ca.cert.pem

# Verify the root CA certificate
openssl x509 -noout -text -in certs/ca.cert.pem

# Base64 encode
export FLAG=$(if [ "$(uname -s)" == "Linux" ]; then echo "-w 0"; else echo "-b 0"; fi)
CA_CERT=`cat certs/ca.cert.pem | base64 $FLAG`



log "STEP 2 ################ Lets do Root TLS CA ################" 
cd ../..
cd ./rootExCA/tlsca

mkdir certs crl newcerts private csr
chmod 700 private
touch index.txt
echo 1000 > serial
cp ../../ssl-config/opensslRootTLS.cnf .

# Create the root TLS CA private key
# private key is not encripted, otherwise add    -aes128 | -aes192 | -aes256 | -des | -des3    -passout <passpharse>
### Attention: this is the key used to sign the certificate requests, anyone holding this can sign certificates on your behalf. So keep it in a safe place!
openssl ecparam -genkey -name prime256v1 -noout -out ./private/tlsca.key.pem


# Create the root TLS CA certificate
### Here we used our root key to create the root certificate that needs to be distributed in all the computers that have to trust us.
openssl req -config opensslRootTLS.cnf \
      -key private/tlsca.key.pem \
      -batch -new -x509 -days 7300 -sha256 -extensions v3_ca \
      -out certs/tlsca.cert.pem

# Verify the root TLS CA certificate
openssl x509 -noout -text -in certs/tlsca.cert.pem

# Base64 encode
export FLAG=$(if [ "$(uname -s)" == "Linux" ]; then echo "-w 0"; else echo "-b 0"; fi)
TLSCA_CERT=`cat certs/tlsca.cert.pem | base64 $FLAG`



log "STEP 3 ################ Lets do MSP Admin identity certificate ################" 
cd ../..
cd ./rootExCA/ca
cp ../../ssl-config/opensslMSPAdmin.cnf .

# Create the MSP Admin private key
# private key is not encripted, otherwise add    -aes128 | -aes192 | -aes256 | -des | -des3    -passout <passpharse>
openssl ecparam -genkey -name prime256v1 -noout -out ./private/mspadmin.key.pem


# Create the MSP Admin Certificate Signing Request (CSR)
openssl req -config opensslMSPAdmin.cnf \
      -key private/mspadmin.key.pem \
      -batch -new -sha256 -out csr/mspadmin.csr.pem 

# Sign the CSR 
openssl ca -config opensslMSPAdmin.cnf \
      -extensions usr_cert \
      -days 375 -notext -md sha256 \
      -in csr/mspadmin.csr.pem \
      -out certs/mspadmin.cert.pem

# Verify the root CA certificate
openssl x509 -noout -text -in certs/mspadmin.cert.pem

#Verify certificate chain of trust 
log "##### Certificate chain of trust validation" 
openssl verify -purpose any -CAfile certs/ca.cert.pem      certs/mspadmin.cert.pem
log "##### " 

# Base64 encode
export FLAG=$(if [ "$(uname -s)" == "Linux" ]; then echo "-w 0"; else echo "-b 0"; fi)
ADMIN_CERT=`cat certs/mspadmin.cert.pem | base64 $FLAG`



log "STEP 4 ################ Lets do Peer identity (cert & private key) ################" 
cd ../..
cd ./rootExCA/ca
cp ../../ssl-config/opensslPeer.cnf .

# Create the Peer identity private key
# private key is not encripted, otherwise add    -aes128 | -aes192 | -aes256 | -des | -des3    -passout <passpharse>
openssl ecparam -genkey -name prime256v1 -noout -out ./private/peer.key.pem


# Create the MSP Admin Certificate Signing Request (CSR)
openssl req -config opensslPeer.cnf \
      -key private/peer.key.pem \
      -batch -new -sha256 -out csr/peer.csr.pem 

# Sign the CSR 
openssl ca -config opensslPeer.cnf \
      -extensions usr_cert \
      -days 375 -notext -md sha256 \
      -in csr/peer.csr.pem \
      -out certs/peer.cert.pem

# Verify the root CA certificate
openssl x509 -noout -text -in certs/peer.cert.pem

#Verify certificate chain of trust 
log "##### Certificate chain of trust validation" 
openssl verify -purpose any -CAfile certs/ca.cert.pem      certs/peer.cert.pem
log "##### " 


log "STEP 5 ################ Create public TLS certificate for the Peer ################" 
cd ../..
cd ./rootExCA/tlsca
cp ../../ssl-config/opensslPeerTLS.cnf .

# Create the Peer TLS private key
# private key is not encripted, otherwise add    -aes128 | -aes192 | -aes256 | -des | -des3    -passout <passpharse>
openssl ecparam -genkey -name prime256v1 -noout -out ./private/tlspeer.key.pem


# Create the Peer TLS   Certificate Signing Request (CSR)
openssl req -config opensslPeerTLS.cnf \
      -key private/tlspeer.key.pem \
      -batch -new -sha256 -out csr/tlspeer.csr.pem 

# Sign the CSR 
openssl ca -config opensslPeerTLS.cnf \
      -extensions server_cert \
      -days 375 -notext -md sha256 \
      -in csr/tlspeer.csr.pem \
      -out certs/tlspeer.cert.pem

# Verify the root CA certificate
openssl x509 -noout -text -in certs/tlspeer.cert.pem

#Verify certificate chain of trust 
log "##### Certificate chain of trust validation" 
openssl verify -purpose any -CAfile certs/tlsca.cert.pem      certs/tlspeer.cert.pem
log "##### " 



log "STEP 6 ################ Create Peer MSP file ################" 

### Define the MSP file
cd ..
(
cat<<EOF
{
    "display_name": "$ORG_DISPLAY_NAME",
    "msp_id": "$MSP_ID",
    "type": "msp",
    "admins": [
        "$ADMIN_CERT"
    ],
    "root_certs": [
        "$CA_CERT"
    ],
    "intermediate_certs": [],
    "tls_root_certs": [
        "$TLSCA_CERT"
    ],
    "revocation_list": [],
    "organizational_unit_identifiers": [],
    "fabric_node_ous": {
        "admin_ou_identifier": {
            "certificate": "$CA_CERT",
            "organizational_unit_identifier": "admin"
        },
        "client_ou_identifier": {
            "certificate": "$CA_CERT",
            "organizational_unit_identifier": "client"
        },
        "enable": true,
        "orderer_ou_identifier": {
            "certificate": "$CA_CERT",
            "organizational_unit_identifier": "orderer"
        },
        "peer_ou_identifier": {
            "certificate": "$CA_CERT",
            "organizational_unit_identifier": "peer"
        }
    },
    "host_url": "$HOST_URL",
    "name": "$ORG_DISPLAY_NAME"
}
EOF
)> orgmsp.json



# Late addition needed to bypass this issue:   https://github.ibm.com/IBM-Blockchain/OpTools/issues/3886
# convert from PKCS#1 format to PKCS#8
# The crypto library that IBP v2.1.3 currently does not support PKCS#1 format!!
openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in ./ca/private/mspadmin.key.pem -out ./ca/private/mspadmin.key.PKCS8.pem
openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in ./ca/private/peer.key.pem -out ./ca/private/peer.key.PKCS8.pem
openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in ./tlsca/private/tlspeer.key.pem -out ./tlsca/private/tlspeer.key.PKCS8.pem