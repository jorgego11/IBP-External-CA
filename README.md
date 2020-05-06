# IBP External CA

This is a simple asset that can be used by **Blockchain Labs** and **Tech Sales** teams to demo the External CA feature in IBP v2.1.3. Basically it simulates the creation of certificates by an on-premises/cloud based centralized enterprise certificate management solution such as www.digicert.com, www.entrust.com and others. 

This asset is not meant to be given to customers for free unless its in the context of a paid service engagement or a *confirmed* sales opportunity.

This repository contains scripts that create various crypto material required for a 'Peer MSP', org-admin identity, peer identity and peer TLS. The same script flow could be extended to also generate the Orderer MSP certificates.

The scripts leverage the openssl command to generate X.509 certificates and keys that support Elliptic Curve Digital Signature Algorithm (ECDSA) with curve prime256v1. This script has been tested on macOS Mojave with openssl version LibreSSL 2.6.5. Note that an External CA means that there is no Fabric-CA SDK that developers could use to dinamically generate identities. Instead, the client application should leverage whatever API is exposed by the centralized certificate management solution (if any).


## Script Flow Description

Note that on every script run the folder rootExCA will be recreated with the Root CA and Root TLS certificates.

* Step 1 Root CA creation
* Step 2 Root TLS creation
* Step 3 MSP Admin identity creation
* Step 4 Peer identity creation
* Step 5 Peer TLS certificate creation
* Step 6 Peer MSP file creation


## Script Run Instructions

Update the createMSPexternalCA.json file by filling the values for ORG_DISPLAY_NAME
, MSP_ID and the host URL.

Run this:

    ./createMSPexternalCA.sh  createMSPexternalCA.json

## Creating a Peer Org with one peer in IBP using the generated certs

On the IBP console:

* Click on the *Organizations* tab and import the orgmsp.json file.
* Click on the *Wallet* tab and create the organization admin:  enter display name (e.g. org3admin) and import the certificate file (mspadmin.cert.pem) and private key file (mspadmin.key.PKCS8.pem)
* On the *Nodes* tab click *Add peer*:

    * Select create a peer, Next
    * Enter Peer display name and check *Use your own CA ...* , Next
    * Import the Peer identity certificate file (peer.cert.pem), private key file (peer.key.PKCS8.pem) and select the MSP that you just imported,  Next
    * Import the Peer TLS certificate file (tlspeer.cert.pem) and private key file (tlspeer.key.PKCS8.pem),  Next
    * Select the Peer administrator identity that you just added to the wallet, Next
    * Review the Summary and click *Add peer*

The new peer that uses external certificates should be up and running in a few minutes.

## Uselful Tools

1. [base 64 text decoder](https://www.base64decode.org  ) - 
2. [certificate decoder](https://certlogik.com/decoder/) - Useful certificate decoder to validate certificate attributes.

