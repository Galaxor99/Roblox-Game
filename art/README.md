# Anime Nexus portrait atlases

All 204 cards have a unique assigned portrait cell in `nexus_portraits_01.png` through `nexus_portraits_23.png`. Each image has a 3×3 grid; its cells are read left to right, top to bottom. Atlases 01–04 hold the 36 original characters. Atlases 05–23 hold the 168 fiction-roster slots. The later atlases are original alternate-reality interpretations, not official franchise art or licensed likenesses.

Roblox requires images to be uploaded before `ImageLabel` can display them. In Roblox Studio, open **Asset Manager** and import the 23 PNGs as images. Copy each image's numeric asset ID into the corresponding position of `C.PortraitAtlases` in `ReplicatedStorage/NexusConfig`. For example, the ID for `nexus_portraits_01.png` goes at index 1, and the ID for `nexus_portraits_23.png` goes at index 23. The Cards screen, pack reel, and summon reveal will then display the portraits. Set the IDs in `src/NexusConfig.luau` as well if you are rebuilding from source.

Individual cards can be overridden with `Identity.PortraitAssetId`. This takes precedence over their atlas cell. Fiction identities remain unverified in `C.RosterMode="Development"` and are excluded from public-mode summons until their rights metadata is cleared. Do not treat the generated portraits as a franchise licence.
