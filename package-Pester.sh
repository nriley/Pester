#!/bin/zsh

#set -x -v

PACKAGEDIR="$PWD"
PRODUCT="Pester"

cd "$PACKAGEDIR"/Source && \
find . -name \*~\* -exec rm -r '{}' \; && \
rm -f .gdb_history && \
VERSION=`cat VERSION` && \
DMG="$PRODUCT-$VERSION.dmg" VOL="$PRODUCT $VERSION" DSTROOT="$PACKAGEDIR/$VOL" && \
sudo rm -fr "$DSTROOT" && \
rm -rf build/ && \
pbxbuild install "DSTROOT=$DSTROOT" && \
rm -rf build/ && \
ditto -rsrc "$PACKAGEDIR"/Source "$DSTROOT"/Source && \
ditto -rsrc "${PACKAGEDIR}/Read Me" "$DSTROOT" && \
rm -rf "$DSTROOT"/Source/build "${DSTROOT}/Source/Read Me.rtfd" && \
find "$DSTROOT" -name ".svn" -exec sudo /bin/rm -rf "{}" \; ; \
cd "$PACKAGEDIR" && \
rm -f "$DMG" && \
hdiutil create "$DMG" -megabytes 5 -ov -layout NONE -fs 'HFS+' -volname "$VOL" && \
MOUNT=`hdiutil attach "$DMG"` && \
DISK=`echo "$MOUNT" | sed -ne ' s|^/dev/\([^ ]*\).*$|\1|p'` && \
MOUNTPOINT=`echo "$MOUNT" | sed -ne 's|^.*\(/Volumes/.*\)$|\1|p'` && \
ditto -rsrc "$DSTROOT" "$MOUNTPOINT" && \
chmod -R a+rX,u+w "$MOUNTPOINT" && \
openUp "$MOUNTPOINT" && \
hdiutil detach $DISK && \
hdiutil resize -sectors min "$DMG" && \
hdiutil convert "$DMG" -format UDZO -imagekey zlib-level=9 -o "z$DMG" && \
mv "z$DMG" "$DMG" && \
hdiutil internet-enable "$DMG" && \
scp "$DMG" ainaz:web/nriley/software/ && \
cd "$PACKAGEDIR"/Source && \
agvtool bump -all && \
:
