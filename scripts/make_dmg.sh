#!/bin/bash
# Build a distributable Rednif.dmg that non-technical users can install by
# dragging Rednif.app into Applications. No Rust or build tools needed by them.
#
# Usage:
#   ./scripts/make_app.sh          # build + assemble Rednif.app first
#   ./scripts/make_dmg.sh          # then wrap it in Rednif.dmg
#
# For a SEAMLESS install (no Gatekeeper warning) the app is signed with a
# Developer ID certificate and notarized by Apple. The identity + notary profile
# are read from the environment (REDNIF_DEVID, REDNIF_NOTARY_PROFILE).
#
# One-time notary profile setup (do this ONCE before the first notarized build):
#   xcrun notarytool store-credentials rednif-notary \
#       --apple-id you@example.com --team-id Z69U4AQSH3 --password <app-specific-pw>
#
# NOTE: team id Z69U4AQSH3 is the Developer ID team (matches the cert below), NOT
# the Apple Development team 7UB4C2P6D6.
#
# To force an UNSIGNED build (e.g. quick local test), run:  REDNIF_DEVID="" ./scripts/make_dmg.sh

set -e
cd "$(dirname "$0")/.."

APP="Rednif.app"
VOL="Rednif"
STAGING="dmg-staging"
# Version comes from Cargo.toml so each release DMG is uniquely named.
VERSION=$(grep -m1 '^version' Cargo.toml | sed -E 's/.*"([^"]+)".*/\1/')
DMG="Rednif-${VERSION}.dmg"

# Signing identity + notary profile (override via env; set REDNIF_DEVID="" to skip).
: "${REDNIF_DEVID=}"
: "${REDNIF_NOTARY_PROFILE=rednif-notary}"

if [ ! -d "$APP" ]; then
    echo "ERROR: $APP not found. Run ./scripts/make_app.sh first."
    exit 1
fi

# --- Optional: sign with Developer ID + hardened runtime (needed to notarize) --
if [ -n "$REDNIF_DEVID" ]; then
    echo "Signing with: $REDNIF_DEVID"
    # Sign nested helper executables first, then the app, with the hardened
    # runtime. Every bundled helper must be signed or the outer bundle's
    # signature is rejected ("code object is not signed at all in subcomponent").
    for helper in removebg cloudctl; do
        if [ -f "$APP/Contents/MacOS/$helper" ]; then
            codesign --force --options runtime --timestamp \
                --sign "$REDNIF_DEVID" "$APP/Contents/MacOS/$helper"
        fi
    done
    codesign --force --options runtime --timestamp \
        --sign "$REDNIF_DEVID" --identifier com.rednif.app "$APP"
    codesign --verify --deep --strict --verbose=2 "$APP"
else
    echo "NOTE: REDNIF_DEVID not set — building an unsigned/ad-hoc DMG."
    echo "      Users will see a Gatekeeper warning (WELCOME.txt explains the fix)."
fi

# --- Stage the drag-to-install layout ----------------------------------------
rm -rf "$STAGING" "$DMG"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

# A short note for users who hit Gatekeeper on an un-notarized build.
cat > "$STAGING/WELCOME.txt" <<'TXT'
Installing Rednif
==================

1. Drag "Rednif" onto the "Applications" folder in this window.
2. Open Applications and launch Rednif.

If macOS says Rednif "cannot be opened because Apple cannot check it":
  - Right-click (or Control-click) Rednif in Applications.
  - Choose "Open", then click "Open" again in the dialog.
  You only need to do this once.
TXT

# --- Build the compressed DMG -------------------------------------------------
hdiutil create -volname "$VOL" -srcfolder "$STAGING" -ov -format UDZO "$DMG"
rm -rf "$STAGING"

# --- Optional: notarize + staple so there's NO Gatekeeper warning ------------
# Notarization credentials, in priority order so the same script works locally
# and in CI:
#   1. a stored notarytool keychain profile   (REDNIF_NOTARY_PROFILE) — local default
#   2. an App Store Connect API key (.p8)      (REDNIF_NOTARY_KEY / _KEY_ID / _ISSUER) — CI
#   3. an Apple ID + app-specific password      (REDNIF_NOTARY_APPLE_ID / _PASSWORD / _TEAM_ID)
# In CI set REDNIF_NOTARY_PROFILE="" so it skips the (absent) profile.
NOTARY_ARGS=()
if [ -n "$REDNIF_NOTARY_PROFILE" ]; then
    NOTARY_ARGS=(--keychain-profile "$REDNIF_NOTARY_PROFILE")
elif [ -n "$REDNIF_NOTARY_KEY" ] && [ -n "$REDNIF_NOTARY_KEY_ID" ] && [ -n "$REDNIF_NOTARY_ISSUER" ]; then
    NOTARY_ARGS=(--key "$REDNIF_NOTARY_KEY" --key-id "$REDNIF_NOTARY_KEY_ID" --issuer "$REDNIF_NOTARY_ISSUER")
elif [ -n "$REDNIF_NOTARY_APPLE_ID" ] && [ -n "$REDNIF_NOTARY_PASSWORD" ] && [ -n "$REDNIF_NOTARY_TEAM_ID" ]; then
    NOTARY_ARGS=(--apple-id "$REDNIF_NOTARY_APPLE_ID" --password "$REDNIF_NOTARY_PASSWORD" --team-id "$REDNIF_NOTARY_TEAM_ID")
fi

if [ -n "$REDNIF_DEVID" ] && [ "${#NOTARY_ARGS[@]}" -gt 0 ]; then
    echo "Submitting $DMG to Apple for notarization (this can take a few minutes)…"
    xcrun notarytool submit "$DMG" "${NOTARY_ARGS[@]}" --wait
    xcrun stapler staple "$DMG"
    echo "Notarized + stapled. This DMG installs with no warnings."
elif [ -n "$REDNIF_DEVID" ]; then
    echo "Signed but NOT notarized (no notary credentials — set REDNIF_NOTARY_PROFILE,"
    echo "  or REDNIF_NOTARY_KEY/_KEY_ID/_ISSUER, or REDNIF_NOTARY_APPLE_ID/_PASSWORD/_TEAM_ID)."
fi

echo "Built $DMG"
