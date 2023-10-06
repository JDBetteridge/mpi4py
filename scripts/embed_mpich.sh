#!/bin/bash
set -xe

VERSION=4.1.2
SHA256=3492e98adab62b597ef0d292fb2459b6123bc80070a8aa0a30be6962075a12f0

pushd $(dirname $0)
SCRIPT_DIR=$PWD
INSTALL_DIR=$(dirname $SCRIPT_DIR)/src/mpi4py/
curl -L -O https://www.mpich.org/static/downloads/$VERSION/mpich-$VERSION.tar.gz
echo "$SHA256  mpich-$VERSION.tar.gz" | sha256sum -c -

tar -xzf mpich-$VERSION.tar.gz

pushd mpich-$VERSION
./autogen.sh
./configure \
    --prefix=$INSTALL_DIR \
    --with-device=ch4:ucx \
    --with-hwloc="embedded" \
    --without-java \
    --without-ze \
    --enable-error-checking=runtime \
    --enable-error-messages=all \
    --disable-static \
    CC=gcc CXX=g++ FC=gfortran
make -j8
make install
popd

cat <<EOF > mpi.cfg
[mpi]
mpicc  = $INSTALL_DIR/bin/mpicc
mpicxx = $INSTALL_DIR/bin/mpicxx
EOF

cd ..
git apply scripts/include_source.patch
env MPI4PY_BUILD_MPICFG=scripts/mpi.cfg python -m build --wheel
auditwheel repair dist/*.whl

popd

