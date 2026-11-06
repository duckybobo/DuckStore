# DuckStore for iOS

A native iPhone/iPad app for your DuckStore server. It lists your apps, installs them, registers the
device and lets you add new `.ipa` files with the **+** button, with the same swimming-duck animations as the web page.

It is a front end for the DuckStore **server** (the `duckstore` folder). It does not replace the server or Apple's
signing rules.

## What it can and cannot do

- **Install apps:** tapping GET opens iOS's own install prompt for a signed app from your server. iOS does the
  install, not this app, so the swimming bar is a "sent to iOS" animation rather than live progress.
- **Add apps:** the + button uploads an `.ipa` to your server, which signs it. Needs your `ADMIN_TOKEN`.
- **Register this device:** Settings opens your server's registration profile in Safari.
- **It cannot** install apps that aren't signed for your registered devices, bypass Apple's certificate rules, or
  work without a running DuckStore server.

## Build the .ipa (no Mac needed)

This project was written without access to Xcode, so **it has not been compiled yet**. The first build may show a
Swift error or two that need fixing.

1. Create a new GitHub repository and upload everything in this folder (keep the `.github` folder).
2. Open the **Actions** tab, choose **Build DuckStore.ipa**, and press **Run workflow**.
   GitHub's macOS runners are free for public repositories. Private repositories use your free minutes at a higher rate.
3. When it finishes, download `DuckStore-unsigned-ipa` from the run page and unzip it to get `DuckStore.ipa`.
4. If the build fails, open the failed step and send me the error text.

On a Mac with Xcode you can instead run `brew install xcodegen && xcodegen generate` and open `DuckStore.xcodeproj`.

## Install it

The built file is **unsigned**, so iOS will not run it until it is signed:

- **With your DuckStore server:** put `DuckStore.ipa` in the server's `sources/` folder. It signs the app with your
  certificate and it then appears in the web store, so you can install it from Safari.
- **Without a paid Apple account:** sideload it with AltStore, SideStore or Sideloadly (7-day certificates, 3 apps).

## First launch

Open Settings (gear icon), enter your server address (for example `https://store.yourname.com`), your admin token
and invite code, then tap **Register this device** once.

## Notes

- Requires iOS 15 or later.
- The admin token is stored in the iOS Keychain, not in plain preferences.
- Apps signed with a wildcard profile can't use some entitlements (see the server README). That applies to this app
  too, but it only needs the network, so it is unaffected.
