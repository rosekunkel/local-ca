##
# Local Certificate Authority
#
# @file
# @version 0.1

.PHONY: all ca clean
.DEFAULT: all
.SUFFIXES:

key := private/%-key.pem
cert := certs/%-cert.pem
conf := requests/%-cert.conf
req := requests/%-cert.csr

.PRECIOUS: $(key) $(cert)

dirs := private certs

all_certs := $(patsubst $(conf),$(cert),$(wildcard requests/*.conf))

all : $(all_certs)

$(key) : | private
	openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -out '$@'

$(req) : $(conf) $(key)
	openssl req -new -config '$(word 1,$^)' -key '$(word 2,$^)' -out '$@'

$(cert) : ca/ca.conf $(req) certs/ca-root-cert.pem private/ca-root-key.pem | ca/index.db ca/serial certs
	openssl ca -batch -config '$(word 1,$^)' -in '$(word 2,$^)' -out '$@'
	@rm -f certs/$$(cat ca/serial.old).pem

certs/ca-root-cert.pem : ca/ca-root-cert.conf private/ca-root-key.pem | certs
	openssl req -new -x509 -config '$(word 1,$^)' -key '$(word 2,$^)' -out '$@'

ca/index.db :
	@touch '$@'

ca/serial :
	@echo '01' > '$@'

$(dirs) :
	@mkdir '$@'

clean:
	rm -rf $(dirs) requests/*.csr ca/*.pem ca/index.db* ca/serial*
