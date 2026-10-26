# Anime Nexus portrait atlases

All 204 cards have a unique assigned portrait cell in `nexus_portraits_01.png` through `nexus_portraits_23.png`. Each image has a 3×3 grid; its cells are read left to right, top to bottom. Atlases 01–04 hold the 36 original characters. Atlases 05–23 hold the 168 fiction-roster slots. The later atlases are original alternate-reality interpretations, not official franchise art or licensed likenesses.

Roblox requires images to be uploaded before `ImageLabel` can display them. The initial Studio build will show colored initials until this is done.

1. In Roblox Studio, open **View → Asset Manager** and import the 23 PNGs as images into the experience. Wait for moderation and make sure their thumbnails load.
2. Copy the numeric asset ID of each uploaded image, in filename order: 01, 02, 03, …, 23. Keep a `0` for an atlas you have not uploaded yet.
3. In **Explorer**, select **ReplicatedStorage → NexusPortraitAssets**. Paste the 23 IDs into its **Value** property as a comma-separated line, for example `123456,234567,0,0,...`. Do not include `rbxassetid://`, image names, spaces inside numbers, or quotes. Do this before pressing Play.

The Cards screen, pack reel, and summon reveal read the IDs from that one property. You can add the remaining IDs later without rebuilding the place. If an uploaded image is still under moderation or belongs to an account that cannot be used by the experience, Roblox may still show the fallback initial.

Individual cards can be overridden with `Identity.PortraitAssetId`. This takes precedence over their atlas cell. Fiction identities remain unverified in `C.RosterMode="Development"` and are excluded from public-mode summons until their rights metadata is cleared. Do not treat the generated portraits as a franchise licence.
