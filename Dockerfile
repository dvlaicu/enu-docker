FROM eosio/builder as builder
ARG branch=enumivo
ARG symbol=SYS

RUN \
    git clone -b $branch https://github.com/enumivo/enumivo --recursive \
    && cd enumivo \
    && git checkout $(git describe --abbrev=0 --tags) \
    && git submodule update --init --recursive \
    && echo "$branch:$(git rev-parse HEAD)" > /etc/enumivo-version \
    && cmake -H. -B"/tmp/build" -GNinja -DCMAKE_BUILD_TYPE=Release -DWASM_ROOT=/opt/wasm -DCMAKE_CXX_COMPILER=clang++  \
       -DCMAKE_C_COMPILER=clang -DCMAKE_INSTALL_PREFIX=/tmp/build -DBUILD_MONGO_DB_PLUGIN=true -DCORE_SYMBOL_NAME=$symbol  \
    && cmake --build /tmp/build --target install \
    && rm -fr /tmp/build/bin/enumivocpp

FROM ubuntu:18.04

RUN \
    apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get -y install openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY --from=builder /usr/local/lib/* /usr/local/lib/
COPY --from=builder /tmp/build/bin /opt/enumivo/bin
COPY --from=builder /tmp/build/contracts /contracts
#COPY --from=builder /Docker/config.ini /
COPY config.ini /
COPY --from=builder /etc/enumivo-version /etc
#COPY --from=builder /Docker/enunoded.sh /opt/eosio/bin/enunoded.sh
COPY enunoded.sh /opt/enumivo/bin/enunoded.sh
ENV EOSIO_ROOT=/opt/enumivo
RUN chmod +x /opt/enumivo/bin/enunoded.sh
ENV LD_LIBRARY_PATH /usr/local/lib
ENV PATH /opt/enumivo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
