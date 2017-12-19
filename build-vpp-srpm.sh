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
    echo "$0 < -c commit -g > < [master] | [tag] > -h -k -p < URL >        \
             -u < URL > -v                                              \
                                                                        \
    -g <VPP TAG>   -- VPP release tag commit to build. The default is \
                       master.                                          \
    -h              -- print this message                               \
    -v              -- Set verbose mode."
}
while getopts "c:g:hkp:s:u:v" opt; do
    case "$opt" in
        c)
            COMMIT=${OPTARG}
            ;;
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
    VPP_REPO_URL=https://gerrit.fd.io/r/vpp
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

if [ ! -z $COMMIT ]; then
    git checkout $COMMIT
elif [[ "$VPP_VERSION" =~ "master" ]]; then
    git checkout master
else
    git checkout v$VPP_VERSION
fi
echo
echo ==============================================
echo make dist tarball for this release.
echo ==============================================
make dist

TARBALL=`realpath $TMPDIR/vpp/build-root/vpp-latest.tar.xz`
BASENAME=`basename $TARBALL | sed -e s/.tar.\*//`
VERSION=`echo $BASENAME | cut -f2 -d-`
RELEASE=`echo $BASENAME | cut -f3- -d- | sed -e s/-/_/g`

echo ==============================================
echo Building SRPM: version: $VERSION release: $RELEASE
echo ==============================================

cp build-root/vpp-latest.tar.xz $TMPDIR
cd $TMPDIR
if [ ! -d dist ] ; then mkdir dist ; fi

DISTDIR=`mktemp -d`
cd $DISTDIR
tar -xJf $TARBALL

cd vpp-$VERSION
echo
echo ====================================================================
echo These patches must be applied now because they change the spec file.
echo ====================================================================
echo
if [ "$VERSION" = "18.01" ] ; then
    echo Apply patch0001-Add-dpdk-tarball-to-Sources-in-srpm-1801
    patch -p1 < $HOME/patches/0001-Add-dpdk-tarball-to-Sources-in-srpm-1801.patch
else
    echo Apply patch 0001-Add-dpdk-tarball-to-Sources-in-srpm
    patch -p1 < $HOME/patches/0001-Add-dpdk-tarball-to-Sources-in-srpm.patch
fi
echo Apply patch 0002-Set-rpmbuild-option-default-to-WITHOUT-aeasni-crypto
patch -p1 < $HOME/patches/0002-Set-rpmbuild-option-default-to-WITHOUT-aeasni-crypto.patch

if [[ $RELEASE == "release" ]] ; then
    echo Apply patch to make package release conform to Fedora guidelines
    patch -p1 < $HOME/patches/0001-Make-Package-release-number-confirm-to-Fedora.patch
fi

if [[ ! "${SRC}dummy" == "dummy" ]]; then
    echo "---------------------------------------"
    echo "Build SRPM"
    echo
fi

mkdir -p extras/rpm/rpmbuild/{RPMS,SRPMS,BUILD,SOURCES,SPECS}
cp $HOME/patches/* extras/rpm/rpmbuild/SOURCES

echo Changelog:
echo =====================================================================
cat $HOME/changelog.txt
echo =====================================================================
echo

cat $HOME/changelog.txt >> extras/rpm/vpp.spec

make pkg-srpm
cp $DISTDIR/vpp-$VERSION/extras/rpm/vpp*.src.rpm $HOME
if [ ! -d $DISTDIR ] ; then rm -rf $DISTDIR ; fi

exit 0
