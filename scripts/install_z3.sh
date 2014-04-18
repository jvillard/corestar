#!/bin/bash

if [ "$UID" -ne "0" ]; then
    echo "This script should be run as root"
    exit 1
fi

if [ -z "$CORESTAR_HOME" ]; then
    echo "CORESTAR_HOME is not set. Please source setenv first."
    exit 1
fi

SCRIPTS=$CORESTAR_HOME/scripts
Z3_URL="http://www.doc.ic.ac.uk/~jvillar1/pub/z3-7f27f3bd15dba1b2ae830d87d1fcb68a7312db6a.zip"
Z3_ZIP="z3.zip"
TMP=$(mktemp -d)

echo $TMP
cd $TMP

echo "Downloading..."
wget $Z3_URL -O $Z3_ZIP
echo "Extracting..."
unzip $Z3_ZIP
# dos2unix ./configure
tr -d '\r' < configure > configure.unix
cat configure.unix > configure

echo "Building Z3..."
./configure && cd build && make -j 8 && make install
ldconfig

cd .. && ./configure --ml && cd build && make ml && make install
