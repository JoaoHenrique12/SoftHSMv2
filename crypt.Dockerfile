FROM ubuntu:24.04 AS crypt_builder

RUN apt update && \
    apt install -y \
    build-essential \
    make \
    libtext-template-perl \
    wget \
    git && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /crypt

RUN wget https://github.com/openssl/openssl/archive/refs/tags/openssl-3.5.1.tar.gz && \
    mkdir openssl && \
    tar -xvf openssl-3.5.1.tar.gz -C openssl --strip-components=1 && \
    rm openssl-3.5.1.tar.gz

WORKDIR /crypt/openssl

RUN ./config --prefix=/usr/local --openssldir=/usr/local/ssl -Wl,-rpath=/usr/local/lib && \
    make -j$(nproc) && \
    make install

FROM ubuntu:24.04 AS final_image

COPY --from=crypt_builder /usr/local/bin/openssl /usr/local/bin/
COPY --from=crypt_builder /usr/local/lib64/ /usr/local/lib64/
COPY --from=crypt_builder /usr/local/ssl/ /usr/local/ssl/

# Configura o loader para encontrar as bibliotecas
RUN echo '/usr/local/lib64' > /etc/ld.so.conf.d/openssl.conf && \
    ldconfig

ENV LD_LIBRARY_PATH=/usr/local/lib64

CMD ["bash"]


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
