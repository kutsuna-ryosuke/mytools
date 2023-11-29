#!/bin/bash
#
#  to generate self-signed certificates for AWS ClientVPN.
#  Referrence: https://docs.aws.amazon.com/ja_jp/vpn/latest/clientvpn-admin/mutual.html
#

EASYRSA_REQ_COUNTRY=JP
EASYRSA_REQ_ORG=example
SERVERNAME=vpn
EASYRSA_REQ_CN=www
EASYRSA_CERT_EXPIRE=3650

[ ! -e easy-rsa ] && git clone https://github.com/OpenVPN/easy-rsa.git

(cd easy-rsa/easyrsa3;
	./easyrsa init-pki
	./easyrsa build-ca nopass
	./easyrsa build-server-full ${SERVERNAME}.${EASYRSA_REQ_ORG}.${EASYRSA_REQ_COUNTRY} nopass
	./easyrsa build-client-full ${EASYRSA_REQ_CN}.${EASYRSA_REQ_ORG}.${EASYRSA_REQ_COUNTRY} nopass	

	for crts in $(find . -name "*.crt"); do
		pwd
		echo "=== $crts ==="
		openssl x509 -in $crts -noout -issuer
		openssl x509 -in $crts -noout -subject
		openssl x509 -in $crts -noout -startdate
		openssl x509 -in $crts -noout -enddate
	done
)
