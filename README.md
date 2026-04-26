# Show Stash

Show Stash is a Roku SceneGraph channel for keeping a short, household-friendly list of favorite shows and launching the streaming service where each show is watched.

The app is intended to reduce the friction of remembering which service has which show. Users add shows to a shared household list, optionally use TMDb lookup to find show metadata and a likely streaming provider, and then select a show from the main screen to launch that provider's Roku channel.

## Current Capabilities

- Add favorite shows from the Roku UI.
- Search TMDb while adding a show when an API key is configured.
- Map supported TMDb watch providers to Roku channel IDs.
- Save shows locally in the Roku registry.
- Sync a household show list through Firebase Realtime Database.
- Create or join a household using a generated household code.
- Launch the selected show's streaming service.
- Open a Settings screen to view and edit the TMDb API key.
- Optionally save Hulu and ESPN matches as Disney+ for Disney bundle workflows.
- Focus the newly added show in the main list after it is saved.

## Planned Direction

Show Stash currently launches the streaming service associated with a show. The desired next step is direct program launch where possible. That will require provider-specific content IDs and Roku deep-link parameters supported by each streaming provider.

## Project Structure

```text
.
|-- manifest
|-- README.md
|-- source/
|   `-- main.brs
|-- components/
|   |-- MainScene.xml
|   |-- MainScene.brs
|   |-- AddShow.xml
|   |-- AddShow.brs
|   |-- SettingsScreen.xml
|   |-- SettingsScreen.brs
|   |-- SetupScreen.xml
|   |-- SetupScreen.brs
|   |-- MetadataSearchTask.xml
|   |-- MetadataSearchTask.brs
|   |-- TMDbMetadataProvider.brs
|   |-- LaunchTask.xml
|   |-- LaunchTask.brs
|   |-- FirebaseTask.xml
|   `-- FirebaseTask.brs
`-- images/
    `-- Show Stash Icon.jpg
```

## Key Components

- `MainScene` controls the main show list, keyboard shortcuts, add/settings overlays, deletion, sync, and launch flow.
- `AddShow` handles show entry, TMDb match selection, and fallback manual service selection.
- `SettingsScreen` displays and edits the TMDb API key, toggles app preferences, and includes application attribution/copyright information.
- `TMDbMetadataProvider` searches TMDb, scores possible matches, fetches watch providers, and maps supported providers to Roku app IDs.
- `FirebaseTask` fetches and pushes household show lists to Firebase Realtime Database.
- `LaunchTask` launches an installed Roku app by app ID, or opens the Channel Store springboard if the app is not installed.
- `SetupScreen` creates or joins a shared household.

## Controls

- `OK`: Launch the selected show's streaming service.
- `*` / Options: Add a show.
- `Play`: Open Settings.
- `Back` or `Delete`: Remove the selected show.

## Configuration

### TMDb

TMDb lookup uses the `TMDbApiKey` value stored in the Roku registry. Users can edit this from the Settings screen.

The app can also read a fallback `TMDb_api_key` value from `manifest`, but storing private API keys directly in committed source is not recommended for public repositories.

TMDb attribution is shown on the Settings screen:

> This product uses the TMDb API but is not endorsed or certified by TMDb.

### Settings

Settings are stored in the Roku registry under the `RokuTracker` section.

- `TMDbApiKey`: TMDb API key used for metadata lookup.
- `useDisneyForHuluAndESPN`: When `true`, shows whose selected or detected service is Hulu, ESPN, or ESPN+ are saved as Disney+ instead.

### Firebase

Household sync is currently configured in `components/FirebaseTask.brs` with this Firebase Realtime Database URL:

```text
https://roku-tracker-default-rtdb.firebaseio.com
```

If this project is deployed outside the original environment, update that endpoint and configure appropriate Firebase security rules.

## Supported Streaming Services

The current service map includes:

- Netflix
- Hulu
- Disney+
- ESPN
- Amazon Prime
- Max
- Apple TV+
- Peacock
- Paramount+

Provider mappings live in `components/TMDbMetadataProvider.brs` and manual service choices live in `components/AddShow.brs`. Additionally, any Provider provided by TMDb is also allowed, but not added to this self-serve Provider list.

## Development

This is a standard Roku SceneGraph channel. To test it on a Roku device:

1. Enable Developer Mode on the Roku device.
2. Zip the channel contents from the project root.
3. Upload the zip through the Roku developer web installer.
4. Launch the sideloaded channel on the device.

The package should include `manifest`, `source/`, `components/`, and `images/`.

## Notes

- The app targets FHD UI resolution.
- Show data is stored as JSON in the Roku registry under the `RokuTracker` section.
- Household sync uses a shared household code and stores shows under `/households/{householdCode}/shows.json`.
- Direct program deep linking is not implemented yet.

## Copyright

Copyright (c) 2026 by Pearl Lane, LLC
Website: https://pearllane.com
Support: hello@pearllane.com

Pearl Lane, LLC
12128 N Division St Ste 1520
Spokane, WA 99218
