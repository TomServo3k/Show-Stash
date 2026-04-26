# Roku Certification Notes

These notes summarize known behavior to review before submitting Show Stash to Roku.

## Core Channel Behavior

Show Stash is a household show list. Users add shows, optionally use TMDb lookup to identify metadata and likely watch providers, and select a saved show to open the Roku channel for the selected streaming service.

## Important Certification Risk

Show Stash intentionally launches selected third-party Roku channels when possible and opens the Roku Channel Store springboard when a selected service is not installed. This behavior is central to the product.

Before public submission, ask Roku Partner Success whether this launcher-style workflow is acceptable for a utility channel. If Roku rejects channels that launch or direct users into other channels, Show Stash may not be certifiable without removing its primary feature.

## Privacy And Data

Show Stash stores show lists and settings locally in the Roku registry. Household sync sends the household list to Firebase Realtime Database under a household code. TMDb lookup sends search text to TMDb when enabled.

## Content And Commerce

Show Stash does not stream video, sell subscriptions, sell rentals, or process payments. Streaming services opened from Show Stash are responsible for their own content, accounts, subscriptions, purchases, and policies.

## Test Scenarios

- First launch with no household code.
- Create a household.
- Join an existing household.
- Add a show with TMDb enabled.
- Add a show manually when TMDb has no match.
- Back out of TMDb results, edit the previous show name, and search again.
- Remove a show with confirmation.
- Toggle Disney+ preference for Hulu and ESPN matches.
- Launch an installed streaming service.
- Open the Channel Store springboard for a service that is not installed.
- Use Back from the main screen to exit.
