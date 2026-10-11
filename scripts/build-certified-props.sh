#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
: "${CERTIFIED_PROPS_KEY:?Set CERTIFIED_PROPS_KEY to the signing-key basename}"
: "${ANDROID_HOME:?Set ANDROID_HOME to the Android SDK directory}"
tools="$ANDROID_HOME/build-tools/35.0.0"
work=$(mktemp -d "${TMPDIR:-/tmp}/certified-props.XXXXXX")
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/res/values"
node - "$root/certified_build_props.json" "$work" <<'JS'
const fs = require('node:fs');
const [input, output] = process.argv.slice(2);
const props = JSON.parse(fs.readFileSync(input, 'utf8'));
const escape = text => text.replaceAll('&', '&amp;').replaceAll('<', '&lt;')
  .replaceAll('>', '&gt;').replaceAll('"', '&quot;').replaceAll("'", '&apos;');
const version = Math.floor(Date.now() / 1000);
const items = Object.entries(props).map(([key, value]) => {
  if (typeof value !== 'string' || !value || !/^[A-Z0-9_.]+$/.test(key)) {
    throw new Error(`Invalid property: ${key}`);
  }
  return `        <item>${escape(key + ':' + value)}</item>`;
}).join('\n');
fs.writeFileSync(`${output}/res/values/props.xml`,
  `<resources><string-array name="config_certifiedBuildProperties" translatable="false">\n${items}\n</string-array></resources>\n`);
fs.writeFileSync(`${output}/AndroidManifest.xml`,
  `<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="net.pixelos.certifiedprops.overlay" android:versionCode="${version}" android:versionName="${version}"><uses-sdk android:minSdkVersion="34" android:targetSdkVersion="35"/><overlay android:targetPackage="android" android:isStatic="false" android:priority="0"/><application android:hasCode="false"/></manifest>\n`);
JS
"$tools/aapt2" compile --dir "$work/res" -o "$work/resources.zip"
"$tools/aapt2" link -I "$ANDROID_HOME/platforms/android-35/android.jar" \
    --manifest "$work/AndroidManifest.xml" -o "$work/unsigned.apk" "$work/resources.zip"
"$tools/apksigner" sign --key "$CERTIFIED_PROPS_KEY.pk8" \
    --cert "$CERTIFIED_PROPS_KEY.x509.pem" --out "$work/signed.apk" "$work/unsigned.apk"
"$tools/apksigner" verify "$work/signed.apk"
mv "$work/signed.apk" "$root/certified_build_props.apk"
