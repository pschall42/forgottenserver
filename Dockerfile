FROM alpine:3.13.0 AS build
# crypto++-dev was in edge/testing, but it's now in edge/community and refuses to install, so install via git instead
RUN apk add --no-cache \
  binutils \
  boost-dev \
  build-base \
  clang \
  cmake \
  fmt-dev \
  gcc \
  git \
  gmp-dev \
  luajit-dev \
  make \
  mariadb-connector-c-dev \
  pugixml-dev

RUN git clone --depth 1 --branch CRYPTOPP_8_4_0 https://github.com/weidai11/cryptopp.git /usr/src/cryptopp
WORKDIR /usr/src/cryptopp
RUN make
# Installs to /usr/local/include/cryptopp/*.h /usr/local/lib/libcryptopp.a /usr/local/bin/cryptest.exe /usr/local/share/cryptopp/TestData/*.dat /usr/local/share/cryptopp/TestVectors/*.txt
RUN make install

COPY cmake /usr/src/forgottenserver/cmake/
COPY src /usr/src/forgottenserver/src/
COPY CMakeLists.txt /usr/src/forgottenserver/
WORKDIR /usr/src/forgottenserver/build
RUN cmake .. && make

FROM alpine:3.13.0
RUN apk add --no-cache \
  boost-iostreams \
  boost-system \
  boost-filesystem \
  fmt \
  gmp \
  luajit \
  mariadb-connector-c \
  pugixml

# Install crypto++ installation outputs
COPY --from=build /usr/local/include/cryptopp /usr/local/include/cryptopp
COPY --from=build /usr/local/lib/libcryptopp.a /usr/local/lib/libcryptopp.a
COPY --from=build /usr/local/bin/cryptest.exe /usr/local/bin/cryptest.exe
COPY --from=build /usr/local/share/cryptopp/TestData /usr/local/share/cryptopp/TestData
COPY --from=build /usr/local/share/cryptopp/TestVectors /usr/local/share/cryptopp/TestVectors

COPY --from=build /usr/src/forgottenserver/build/tfs /bin/tfs
COPY data /srv/data/
COPY LICENSE README.md *.dist *.sql key.pem /srv/

EXPOSE 7171 7172
WORKDIR /srv
VOLUME /srv
ENTRYPOINT ["/bin/tfs"]