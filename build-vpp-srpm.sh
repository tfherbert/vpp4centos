#!/bin/bash

#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

set -e

echo "==============================="
echo executing $0 $@
echo executing on machine `uname -a`

usage() {
    echo "$0 -g < [master] | [tag] | [commit] > -h -k -p < URL >        \
             -u < URL > -v                                              \
                                                                        \
    -g <VPP TAG>   -- VPP release tag commit to build. The default is \
                       master.                                          \
    -h              -- print this message                               \
    -v              -- Set verbose mode."
}
while getopts "g:hkp:s:u:v" opt; do
    case "$opt" in
        g)
            VPP_VERSION=${OPTARG}
            ;;
        h|\?)
            usage
            exit 1
            ;;
        s)
            SRC=${OPTARG}
            ;;
        v)
            verbose="yes"
            ;;
    esac
done

if [ -z $VPP_REPO_URL ]; then
    VPP_REPO_URL=ssh://tfherbert@gerrit.fd.io:29418/vpp
fi
if [ -z $VPP_VERSION ]; then
    VPP_VERSION=master
fi

HOME=`pwd`
TOPDIR=$HOME
TMPDIR=$TOPDIR/rpms

mkdir -p $TMPDIR

RPMDIR=$HOME/vpp/extras/rpm

cd $TMPDIR
if [ -d vpp ]; then
    rm -rf vpp
fi
git clone $VPP_REPO_URL
cd vpp

if [[ "$VPP_VERSION" =~ "master" ]]; then
    git checkout master
elif [[ "$VPP_VERSION" =~ "stable" ]]; then
    git checkout -b $VPP_VERSION origin/$VPP_VERSION
else
    git checkout v$VPP_VERSION
fi

if [[ ! "${SRC}dummy" == "dummy" ]]; then
    echo "---------------------------------------"
    echo "Build SRPM"
    echo

fi
cd $HOME/rpms/vpp/extras/rpm
#
# Add local patches to spec file.
#
patch -p3 < $HOME/patches/0001-Add-local-patches-to-SRPM.patch

#
# Copy patches
#
cp $HOME/patches/* $HOME/rpms/vpp/extras/rpm/rpmbuild/SOURCES
#
# Update Changelog
#
cat $HOME/changelog.txt > $HOME/rpms/vpp/extras/rpm/rpmbuild/SOURCES/vpp.spec 
#
# Build RPM
#
make srpm

exit 0
