#!/bin/zsh -e

# set -x -v

PACKAGEDIR="$PWD"
PRODUCT="Pester"

# gather information
cd "$PACKAGEDIR"/Source
VERSION=`cat VERSION`
BUILD=`agvtool vers -terse`
DMG="$PRODUCT-$VERSION.dmg" VOL="$PRODUCT $VERSION"
DSTROOT="$PACKAGEDIR/$VOL"

# clean and build
sudo rm -rf "$DSTROOT"
find . -name \*~ -exec rm '{}' \;
rm -rf build/ Sparkle/build/
cd Sparkle
xcodebuild -target Sparkle -configuration Release
cd ..
xcodebuild -target Pester -configuration Release "DSTROOT=$DSTROOT" \
    DEPLOYMENT_LOCATION=YES install
rm -rf build/Release # or Xcode gets confused next time because of the symlink
find "$DSTROOT" \( -name ".svn" -or -name "Headers" \) \
    -exec sudo /bin/rm -rf "{}" \; || true

# create disk image
cd "$PACKAGEDIR"
rm -f $DMG
hdiutil create $DMG -megabytes 5 -ov -layout NONE -fs 'HFS+' -volname $VOL
MOUNT=`hdiutil attach $DMG`
DISK=`echo $MOUNT | sed -ne ' s|^/dev/\([^ ]*\).*$|\1|p'`
MOUNTPOINT=`echo $MOUNT | sed -ne 's|^.*\(/Volumes/.*\)$|\1|p'`
ditto -rsrc "$DSTROOT" "$MOUNTPOINT"
chmod -R a+rX,u+w "$MOUNTPOINT"
hdiutil detach $DISK
hdiutil resize -sectors min $DMG
hdiutil convert $DMG -format UDBZ -o z$DMG
mv z$DMG $DMG
hdiutil internet-enable $DMG
zmodload zsh/stat
SIZE=$(stat -L +size $DMG)

# update Web presence
DIGEST=`openssl dgst -sha1 -binary < $DMG | openssl dgst -dss1 -sign ~/Documents/Development/DSA/dsa_priv.pem | openssl enc -base64`
perl -pi -e 's|(<enclosure url=".+'$DMG'").+/>|\1 length="'$SIZE'" type="application/x-apple-diskimage" sparkle:version="'$BUILD'" sparkle:shortVersionString="'$VERSION'" sparkle:dsaSignature="'$DIGEST'"/>|' Updates/updates.xml
scp $DMG ainaz:web/nriley/software/
ssh ainaz chmod go+r web/nriley/software/$DMG
rsync -avz --exclude='.*' Updates/ ainaz:web/nriley/software/$PRODUCT/
cd "$PACKAGEDIR"/Source
# agvtool bump -all

