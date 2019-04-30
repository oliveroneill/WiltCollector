#!/usr/bin/env sh

set -e

BUILD_DIR=.build/${BUILD_CONFIGURATION}
swift package update
swift build -c ${BUILD_CONFIGURATION} &&
ls -lah .build/release/ &&
cp -r /${SWIFTFILE}/usr/lib/swift/linux/*.so $BUILD_DIR &&
cp /usr/lib/x86_64-linux-gnu/libicudata.so $BUILD_DIR/libicudata.so.52 &&
cp /usr/lib/x86_64-linux-gnu/libicui18n.so $BUILD_DIR/libicui18n.so.52 &&
cp /usr/lib/x86_64-linux-gnu/libicuuc.so $BUILD_DIR/libicuuc.so.52 &&
cp /usr/lib/x86_64-linux-gnu/libbsd.so $BUILD_DIR/libbsd.so.0 &&

mkdir -p $DEST &&

cp $BUILD_DIR/$EXECUTABLE_NAME $DEST &&
cp $BUILD_DIR/./*.so $DEST &&
cp $BUILD_DIR/./*.so.* $DEST &&
# I'll be honest, I'm not sure what 61 or 61.1 means but this fixes
# AWS Lambda issues...
mv $BUILD_DIR/libicui18nswift.so.61.1 $DEST/libicui18nswift.so.61 &&
mv $BUILD_DIR/libicudataswift.so.61.1 $DEST/libicudataswift.so.61 &&
mv $BUILD_DIR/libicuucswift.so.61.1 $DEST/libicuucswift.so.61 &&
cp index.js $DEST &&

cd $DEST &&
ls -lah &&
echo "Creating zip...." &&
zip WiltCollector.zip $EXECUTABLE_NAME index.js ./*.so ./*.so.*
