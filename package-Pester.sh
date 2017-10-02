#!/bin/zsh -e

# set -x -v

PACKAGEDIR="$PWD"
PRODUCT="Pester"

# gather information
cd "$PACKAGEDIR"/Source
VERSION=`agvtool mvers -terse1`
BUILD=`agvtool vers -terse`
DMG="$PRODUCT-$VERSION.dmg" VOL="$PRODUCT $VERSION"
DSTROOT="$PACKAGEDIR/$VOL"
SYMROOT="$PWD/build"

# clean and build
find . -name \*~ -exec rm '{}' \;
rm -rf "$SYMROOT" "$DSTROOT"
xcodebuild -target "$PRODUCT" -configuration Release "DSTROOT=$DSTROOT" \
    SYMROOT="$SYMROOT" DEPLOYMENT_LOCATION=YES install

cd "$PACKAGEDIR"

# ensure code signature and Developer ID are valid
codesign --verify --verbose=4 "$VOL"/*.app
spctl -vv --assess "$VOL"/*.app

# create disk image
rm -f $DMG
hdiutil create $DMG -megabytes 20 -ov -layout NONE -fs 'HFS+' -volname $VOL
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

if [[ -n $1 ]]; then
    return
fi

# update Web presence
DIGEST=`openssl dgst -sha1 -binary < $DMG | openssl dgst -dss1 -sign ~/Documents/Development/DSA/dsa_priv.pem | openssl enc -base64`
NOW=`perl -e 'use POSIX qw(strftime); print strftime("%a, %d %b %Y %H:%M:%S %z", localtime(time())) . $tz'`
perl -pi -e 's|(<enclosure url=".+'$DMG'").+/>|\1 length="'$SIZE'" type="application/x-apple-diskimage" sparkle:version="'$BUILD'" sparkle:shortVersionString="'$VERSION'" sparkle:dsaSignature="'$DIGEST'"/>|' Updates/updates.xml
perl -pi -e 's#<(pubDate|lastBuildDate)>[^<]*#<$1>'$NOW'# && $done++ if $done < 3' Updates/updates.xml
perl -pi -e 's|(<guid isPermaLink="false">)[^<]*|$1'${PRODUCT:l}-${VERSION:s/.//}'| && $done++ if $done < 1' Updates/updates.xml
perl -pe 's|release-notes.html<|release-notes.html#sparkle<|' < Updates/updates.xml >! Updates/updates-1.1b14.xml
scp $DMG osric:web/nriley/software/$DMG.new
ssh osric chmod go+r web/nriley/software/$DMG.new
ssh osric mv web/nriley/software/$DMG{.new,}
# for testing
mv Updates/updates.xml Updates/updatez.xml
rsync -avz --exclude='.*' Updates/ osric:web/nriley/software/$PRODUCT/
# for testing
mv Updates/updatez.xml Updates/updates.xml
ssh osric chmod -R go+rX web/nriley/software/$PRODUCT
cd "$PACKAGEDIR"/Source
