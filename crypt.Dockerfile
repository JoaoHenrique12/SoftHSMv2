FROM ubuntu:24.04 AS crypt_builder

RUN apt update && \
    apt install -y \
    build-essential \
    make \
    libtext-template-perl \
    wget \
    sudo \
    git

# openssl instalation guide:
# https://github.com/openssl/openssl/blob/master/INSTALL.md

WORKDIR /crypt

RUN wget https://github.com/openssl/openssl/archive/refs/tags/openssl-3.5.1.tar.gz

RUN mkdir openssl
RUN tar -xvf openssl-3.5.1.tar.gz -C openssl --strip-components=1

RUN cd openssl
RUN ./Configure
RUN make
# should use non root user to run tests
# RUN make test

# The binary will be installed on 
# /usr/local/bin/openssl
RUN make install

# https://github.com/openssl/openssl/blob/master/NOTES-UNIX.md
# tells the dynamic linker to look in new library path before the system paths
RUN export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

RUN cd ..
RUN mkdir tests && cd tests


# list algorithms
# /usr/local/bin/openssl list -signature-algorithms | grep SLH-DSA

# private key
# /usr/local/bin/openssl genpkey -algorithm SLH-DSA-SHA2-128f -out slhdsa_private.pem

# public key
# /usr/local/bin/openssl pkey -in slhdsa_private.pem -pubout -out slhdsa_public.pem

# signing without hashing message
## SLH-DSA, like ML-DSA, is a "raw" signature algorithm, meaning it doesn't automatically hash the input before signing.
## You typically sign the raw data or a pre-hashed message. The pkeyutl command is suitable for this.
# /usr/local/bin/openssl pkeyutl -sign -in message.txt -inkey slhdsa_private.pem -out message.sig -rawin

# verify
# /usr/local/bin/openssl pkeyutl -verify -in message.txt -pubin -inkey slhdsa_public.pem -sigfile message.sig -rawin

CMD ["bash"]
