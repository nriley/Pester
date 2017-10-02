#!/bin/zsh -ef

set -x -v

PACKAGEDIR="$PWD"
PRODUCT="Pester"

# gather information
cd "$PACKAGEDIR"/Source
VERSION=`agvtool mvers -terse1`
BUILD=`agvtool vers -terse`
DMG="$PRODUCT-$VERSION.dmg" VOL="$PRODUCT $VERSION"
DSTROOT="$PACKAGEDIR/$VOL"
SYMROOT="$PWD/build"
BUNDLEID=net.sabi.$PRODUCT

# for testing Sparkle - set the version back so it'll prompt an
# upgrade to the "current" version
BACKDATED=$DSTROOT/$PRODUCT' (backdated)'.app
/bin/rm -r $BACKDATED
/usr/bin/ditto $DSTROOT/$PRODUCT.app $BACKDATED
/usr/libexec/PlistBuddy -c 'Set :CFBundleVersion 0' \
                        $BACKDATED/Contents/Info.plist

for host in mavericks yosemite elcapitan shirley; do
    HOSTNAME=${host}.local
    { /usr/bin/ssh $HOSTNAME /usr/local/bin/appswitch -qi $BUNDLEID && \
      /usr/bin/ssh $HOSTNAME /usr/local/bin/appswitch -qi $BUNDLEID } || \
        /usr/bin/true
    /usr/bin/rsync -a $DSTROOT $HOSTNAME:Downloads
    /usr/bin/ssh $HOSTNAME defaults write $BUNDLEID SUFeedURL \
                 https://sabi.net/nriley/software/$PRODUCT/updatez.xml
    /usr/bin/ssh $HOSTNAME /usr/local/bin/launch Downloads/${(q)VOL}
done
