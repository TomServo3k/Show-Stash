# Roku Submission Checklist

Show Stash is an SDK/SceneGraph Roku channel. Direct Publisher is not applicable.

## Files In This Repository

- `manifest`: Roku manifest with version and runtime asset references.
- `source/`: BrightScript app entry point.
- `components/`: SceneGraph XML and BrightScript components.
- `images/`: Runtime channel artwork packaged with the app.
- `store-assets/`: Store listing artwork that may be uploaded in the Roku Developer Dashboard.
- `Build Package.ps1`: Creates a clean sideload zip in `Backups/`.

## Package Creation

1. Run `Build Package.ps1`.
2. Sideload the generated zip on a Roku device in Developer Mode.
3. Test the channel.
4. Use the Roku device packager to create the signed `.pkg` file required by the Developer Dashboard.
5. Keep the developer ID and package password in a secure place.

## Developer Dashboard Items

Prepare the following before public submission:

- Channel name: Show Stash.
- Trademark/brand note: Pearl Lane has been submitted as a trademark application and is pending processing. Show Stash and the Show Stash TV-face-and-moustache logo are trademarks claimed by Pearl Lane, LLC.
- Channel category.
- Short description.
- Full description.
- Support email: hello@PearlLane.com.
- Support URL: https://PearlLane.com/ShowStash.
- Privacy Policy URL.
- Terms of Use URL.
- Age/content rating selections.
- Regions where the channel should be available.
- Store poster image from `store-assets/store-poster_540x405.png`.
- Store screenshots, starting with `store-assets/store-screenshot_1920x1080.png` and real on-device screenshots.

## Suggested Store Description

Show Stash helps households remember where their favorite shows are watched. Add shows to a shared household list, use optional TMDb lookup to identify likely streaming services, and select a saved show to open the matching Roku channel.

## Pre-Submission Review

- Confirm the app's third-party channel launching behavior with Roku Partner Success.
- Confirm Firebase security rules are appropriate for public use.
- Confirm the public privacy policy and terms pages are hosted and match the app behavior.
- Confirm the TMDb API key is not committed to the public repository.
- Run Roku static analysis in the Developer Dashboard.
- Test on at least one physical Roku device.
