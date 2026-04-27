# Regional Leadership Hub — Public Site

Static pages and OTA distribution for **Regional Leadership Hub**
(bundle ID `com.discounttire.region2.hub`).

## Pages

- `index.html` — landing page
- `privacy.html` — Privacy Policy URL for ASC
- `support.html` — Support URL for ASC

## OTA Distribution

Internal Region&#8209;2 users can install or update the app directly:

- **Install page:** `https://only21mil.github.io/regional-leadership-hub-site/ota/install.html`
- **Manifest:** `https://only21mil.github.io/regional-leadership-hub-site/ota/manifest.plist`

### How to install

1. Open Safari on your iOS device.
2. Navigate to the install page (above).
3. Tap **"Install Regional Leadership Hub"** — this triggers the
   `itms-services://` protocol to download and install the IPA.
4. If prompted, go to **Settings → General → VPN & Device
   Management** and trust the developer certificate.
5. The app appears on your home screen.

### Prerequisites

- Device UDID must be registered in the ad-hoc provisioning profile.
- Developer certificate must be trusted on the device.

### Updating

When a new build is released, simply tap the install link again on your
device — iOS replaces the existing app while preserving data.

---

## Original content (App Store Connect pages)

Operator branding throughout: **DT of Tennessee** (Discount Tire Region 2
leadership). Support contact: `thevictorvogel@gmail.com`.

## Publish via GitHub Pages

- This **is** the separate `regional-leadership-hub-site` repo, published via GitHub Pages from `main` branch root.
- OTA manifest and install pages are in the `ota/` directory.
- Use `script/build_and_deploy_ota.sh` in the main Xcode project to build, export, copy, and deploy in one command.

## Maintenance

Edit any page locally, commit, and GitHub Pages republishes automatically.
For OTA updates, run the build-and-deploy script.

Bump the `Last updated` date on `privacy.html` whenever the collected-data
section changes.
# force rebuild Mon Apr 27 05:44:47 CDT 2026
