#!/bin/zsh

# stuff to do:
# hdiutil create DiskImage.dmg -megabytes <size> -layout NONE
# hdid -nomount DiskImage.dmg
# sudo /sbin/newfs_hfs -w -v VolumeName -b 4096 /dev/disk2
# hdiutil eject /dev/disk2

# also check out 'build' on mosxland.sf.net

# set -x -v

PACKAGEDIR="$PWD"
PRODUCT="Pester"

cd "$PACKAGEDIR"/Source && \
find . -name \*~\* -exec rm -r '{}' \; && \
VERSION=`cat VERSION` && \
DMG="$PRODUCT-$VERSION.dmg" VOL="$PRODUCT $VERSION" MOUNTPOINT="/Volumes/$VOL" && \
DSTROOT="$PACKAGEDIR/$VOL" && \
sudo rm -fr "$DSTROOT" && \
rm -rf build/ && \
pbxbuild install "DSTROOT=$DSTROOT" && \
ditto -rsrc "$PACKAGEDIR"/Source "$DSTROOT"/Source && \
ditto -rsrc "${PACKAGEDIR}/Read Me" "$DSTROOT" && \
rm -rf "$DSTROOT"/Source/build "${DSTROOT}/Source/Read Me.rtfd" && \
#breaks in 10.2 and later, sigh.
#mkdir "$DSTROOT/Read Me.rtfd" && \
#cd "$DSTROOT/Read Me.rtfd" && \
#for i in "../Pester.app/Contents/Resources/Read Me.rtfd"/*; do ln -s "$i"; done && \
find "$DSTROOT" -name ".svn" -exec sudo /bin/rm -rf "{}" \; ; \
cd "$PACKAGEDIR" && \
rm -f "$DMG" && \
hdiutil create "$DMG" -megabytes 5 -ov -type UDIF && \
DISK=`hdid -nomount "$DMG" | sed -ne ' /Apple_partition_scheme/ s|^/dev/\([^ ]*\).*$|\1|p'` && \
newfs_hfs -v "$VOL" "/dev/r${DISK}s2" && \
hdiutil eject "$DISK" && \
hdid "$DMG" && \
ditto -rsrc "$DSTROOT" "$MOUNTPOINT" && \
chmod -R a+rX,u+w "$MOUNTPOINT" && \
openUp "$MOUNTPOINT" && \
# sleep 2 && \
hdiutil eject $DISK && \
# osascript -e "tell application \"Finder\" to eject disk \"$VOL\"" && \
hdiutil convert "$DMG" -format UDZO -imagekey zlib-level=9 -o "z$DMG" && \
mv "z$DMG" "$DMG" && \
scp "$DMG" ainaz:web/nriley/software/ && \
:
