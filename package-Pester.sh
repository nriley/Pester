#!/bin/zsh -e

set -x -v

PACKAGEDIR="$PWD"
ARCHIVEDIR="$PWD"/Archives
EXPORTDIR=$(mktemp -d)
RELEASEDIR="$PWD"/Releases
SOURCEDIR="$PWD"/Source
PRODUCT=$(print "$SOURCEDIR"/*.xcodeproj(:t:r))

# gather information
cd $SOURCEDIR
VERSION=$(agvtool mvers -terse1)
BUILD=$(agvtool vers -terse)
DMG="$RELEASEDIR/$PRODUCT $VERSION.dmg"
VOL="$PRODUCT $VERSION"
ARCHIVE="$ARCHIVEDIR/$PRODUCT $VERSION ($BUILD).xcarchive"
EXPORT="$EXPORTDIR/$VOL"

# archive and export
mkdir -p $ARCHIVEDIR
rm -rf $ARCHIVE
xcodebuild -scheme $PRODUCT -archivePath $ARCHIVE archive
xcodebuild -archivePath $ARCHIVE -exportArchive -exportPath $EXPORT -exportOptionsPlist $PACKAGEDIR/exportOptions.plist

# ensure code signature and Developer ID are valid
codesign --verify --verbose=4 "$EXPORT"/*.app
# also capture the identity in order to sign the disk image
IDENTITY=$(spctl -vv --assess "$EXPORT"/*.app 2>&1 | grep 'origin=' | sed -e 's/^origin=//')

# remove export metadata we don't want in the disk image
rm -f $EXPORT/*.plist $EXPORT/Packaging.log

# create disk image
mkdir -p $RELEASEDIR
rm -f $DMG
hdiutil create $DMG -megabytes 20 -ov -layout NONE -fs 'HFS+' -volname $VOL
MOUNT=$(hdiutil attach $DMG)
DISK=$(echo $MOUNT | sed -ne ' s|^/dev/\([^ ]*\).*$|\1|p')
MOUNTPOINT=$(echo $MOUNT | sed -ne 's|^.*\(/Volumes/.*\)$|\1|p')
ditto -rsrc "$EXPORT" "$MOUNTPOINT"
chmod -R a+rX,u+w "$MOUNTPOINT"
hdiutil detach $DISK
hdiutil resize -sectors min $DMG
ZDMG="${DMG:r}z.dmg"
hdiutil convert $DMG -format UDBZ -o $ZDMG
mv $ZDMG $DMG
hdiutil internet-enable $DMG

# sign the disk image
codesign --sign $IDENTITY $DMG

# verify disk image signature
spctl -vv --assess --type open --context context:primary-signature $DMG

zmodload zsh/stat
SIZE=$(stat -L +size $DMG)

# clean up
rm -rf "$EXPORTDIR"

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
