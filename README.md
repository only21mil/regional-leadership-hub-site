# Regional Leadership Hub — Public Site

Static pages required by the App Store Connect submission for
**Regional Leadership Hub** (bundle ID `com.discounttire.region2.hub`).

Three pages:

- `index.html` — landing page
- `privacy.html` — Privacy Policy URL for ASC
- `support.html` — Support URL for ASC

Operator branding throughout: **DT of Tennessee** (Discount Tire Region 2
leadership). Support contact: `thevictorvogel@gmail.com`.

## Publish via GitHub Pages

Two common patterns:

### Option A — separate repo (recommended for separation of concerns)

1. Create a new public repo, e.g. `regional-leadership-hub-site`.
2. Copy the contents of this `site/` folder into the repo root.
3. In repo Settings → Pages, set Source = `main` branch, folder = `/` (root).
4. The pages will be live at `https://<your-user>.github.io/regional-leadership-hub-site/`.
5. Use those URLs in App Store Connect:
   - Support URL: `https://<your-user>.github.io/regional-leadership-hub-site/support.html`
   - Privacy Policy URL: `https://<your-user>.github.io/regional-leadership-hub-site/privacy.html`

### Option B — `/docs` folder of any public repo

1. Move the contents of this `site/` folder to a `/docs` folder in any public
   repo you own.
2. In repo Settings → Pages, set Source = `main` branch, folder = `/docs`.
3. The pages will be live at `https://<your-user>.github.io/<repo-name>/`.

## After publishing

Update `Docs/IOS_RELEASE_READINESS.md` with the live URLs (search for
`Support URL:` and `Privacy Policy URL:`) and post the URLs as a comment on
Linear SAT-195 so it can be moved to Done.

## Maintenance

Edit any page locally, commit to the host repo, and GitHub Pages republishes
automatically. Bump the `Last updated` date on `privacy.html` whenever the
collected-data section changes (see also the App Privacy questionnaire in
`Docs/IOS_RELEASE_READINESS.md`).
