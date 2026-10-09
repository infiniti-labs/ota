# OTA metadata

Device-specific updates and changelogs live in device directories. Certified
Build properties are shared across devices at the repository root. URLs do not
depend on an Android-version directory or runtime substitutions.

## Endpoints

- Updates: https://raw.githubusercontent.com/infiniti-labs/ota/main/infiniti/updates.json
- Changelog: https://raw.githubusercontent.com/infiniti-labs/ota/main/infiniti/changelog.md
- Certified Build properties: https://raw.githubusercontent.com/infiniti-labs/ota/main/certified_build_props.json

## Publishing updates

`updates.json` is a JSON array, not an object with a `response` member. An empty
array means no updates are advertised. Each entry must have a positive Unix
timestamp (`datetime`), a nonempty `version`, and exactly one element in `files`.
Each file needs `filename`, `os_patch_level`, positive integer `os_sdk_level`,
lowercase hexadecimal `sha256`, positive byte `size`, and an HTTPS download `url`.
Calculate these from the actual signed OTA, never placeholder values.

Optional `ota_property_files` comes from the OTA's `META-INF/com/android/metadata`.
If supplied, it must include valid ranges for `payload_metadata.bin`,
`payload.bin`, and `payload_properties.txt`, bounded by the package size.

The package must be hosted separately; this repository stores metadata only.
Update the device changelog when publishing a release.

## Certified Build properties

The root JSON uses PixelOS framework field names, including `VERSION.` prefixes.
It does not accept PlayIntegrityFork's advanced switches. Preview identities can
expire or stop being accepted; the included identity is a diagnostic configuration,
not a guarantee of integrity verdicts or payment compatibility.

Manual `pif_data` on the phone takes precedence over the downloaded configuration.

## Automatic refresh

The GitHub workflow refreshes the shared JSON at 09:00 IST on the second
Wednesday of each month, or on manual dispatch. Weekly schedule triggers on
other Wednesdays exit without downloading or changing anything.

It downloads and executes upstream PlayIntegrityFork `autopif4.sh` unchanged.
A minimal `getprop` adapter selects Pixel 11 Pro (`grizzly`); BusyBox provides
the date syntax expected by upstream. Generated files stay in runner temporary
storage. `actions/github-script` validates the selected device and converts the
output to PixelOS field names. No Android installation or firmware download is
performed. Failed generation leaves the existing JSON unchanged.
