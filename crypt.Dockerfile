FROM ubuntu:24.04 AS crypt_builder

# Install build dependencies in a single layer
RUN apt update && \
    apt install -y \
    build-essential \
    make \
    libtext-template-perl \
    wget \
    git && \
    rm -rf /var/lib/apt/lists/* # Clean up apt cache to reduce image size

WORKDIR /crypt

RUN wget https://github.com/openssl/openssl/archive/refs/tags/openssl-3.5.1.tar.gz && \
    mkdir openssl && \
    tar -xvf openssl-3.5.1.tar.gz -C openssl --strip-components=1 && \
    rm openssl-3.5.1.tar.gz

# Change WORKDIR to the openssl source directory
WORKDIR /crypt/openssl
RUN ./config --prefix=/usr/local --openssldir=/usr/local/ssl shared && \
    make -j$(nproc) && \
    make install

FROM ubuntu:24.04 AS final_image

# Install only runtime dependencies if needed
# For openssl, the libraries are dynamic, so they need to be present.
# Since the install to /usr/local, we'll copy them.

# Copy OpenSSL binary and libraries from the builder stage
COPY --from=crypt_builder /usr/local/bin/openssl /usr/local/bin/
COPY --from=crypt_builder /usr/local/lib/ /usr/local/lib/
COPY --from=crypt_builder /usr/local/ssl/ /usr/local/ssl/

# Re-run ldconfig to update the linker cache in the final image
RUN ldconfig

# Set default command or entrypoint
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
