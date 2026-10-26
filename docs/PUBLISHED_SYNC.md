# Work from the published Nexus Test place

The published place is [Nexus Test](https://www.roblox.com/games/99438308921556/Nexus-Test), place ID `99438308921556`. A public game page does not expose its editable place file. A place owner can provide it without sharing an account password or API key:

1. In Roblox Studio, open **File → Open from Roblox** and choose **Nexus Test**.
2. With the published place open, choose **File → Save to File As…** and select **Roblox XML Place (`.rbxlx`)**. Save a copy; this does not publish or overwrite the live game.
3. Supply the `.rbxlx` copy for review. The imported file is kept as a separate snapshot under `reference/`; the existing GitHub source and original starter place stay intact.
4. To package the current Luau source on top of that snapshot, run:

   ```bash
   python tools/export_place.py --base-place reference/Nexus_Test.published.rbxlx
   npm test
   ```

The exporter preserves the snapshot's world objects and settings and replaces only the Anime Nexus scripts listed in its manifest. Review the generated place in Studio before any publish. Future published-place changes require another export; this workflow does not pull changes silently or publish changes back to Roblox.

The alternative automated download uses Roblox's authenticated Asset Delivery Open Cloud API. It needs an API key with download access to the place and network access to `apis.roblox.com` and Roblox's returned CDN host. Set the key in a local environment variable or managed secret, then run:

```bash
python tools/fetch_published_place.py
```

The script fetches place ID `99438308921556` without publishing or overwriting a prior snapshot. If Roblox returns a binary `.rbxl`, open it in Studio and save a `.rbxlx` XML copy before using `--base-place`. This workspace currently receives a proxy 403 for Roblox domains, so the authenticated download cannot be run here until that network path is available. Never paste an API key or Roblox session cookie into chat or the repository.
