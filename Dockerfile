FROM ubuntu:18.04

ENV IS_IN_CONTAINER 1
ENV PACKAGE_ARCH apollolake
ENV DSM_VER 6.2

#export IS_IN_CONTAINER=1
#export PACKAGE_ARCH=apollolake
#export DSM_VER=6.2

RUN apt-get update \
 && apt-get -qy install git python3 wget ca-certificates xz-utils

#COPY . /source/WireGuard

#ENTRYPOINT exec /source/WireGuard/build.sh
