# Vault Is a Single Store; Sync Is a Transport Property

Every artefact lives inside the vault, **regardless of size**. Obsidian Sync (Standard tier) has a 5 MB per-file cap — files over that still live in the vault, they just don't propagate to other devices. That is an accepted trade-off, **not** a problem to solve by moving storage outside the vault.

**Never move originals out of the vault to make sync happy.** The tempting fix — parking big files in a sibling archive folder — trades a transport limitation for a correctness one: the vault stops being the single place a thing can be, and from then on "where is the original?" has no reliable answer. The capturing machine holds the canonical full vault; other devices see the sync-eligible subset. That is the design working, not a degradation.

## Dual-version pattern (when a sync-friendly companion is wanted)

Keep the full-resolution original IN the vault; optionally add a downsized companion alongside it.

- **Bundles** (photo sets, scan series): full-res originals in an `originals/` sub-folder; downsized companions at the bundle's top level. Example: `reports/<bundle>/IMG_0001.jpeg` (downsized, syncs) plus `reports/<bundle>/originals/IMG_0001.jpeg` (full-res, doesn't sync).
- **Single files:** append `-original` to the full-res copy. Example: `<paper-title>.pdf` (compressed, syncs) plus `<paper-title>-original.pdf` (full-res, doesn't sync).

`originals/` is bundle-internal, not a topic-node-level convention — it does NOT violate the three-blessed-sub-folder rule, which governs sub-folders directly inside a topic node, not sub-folders inside `reports/<bundle>/`.

## Compression recipes

Images (macOS):
```
sips --resampleHeightWidthMax 2400 --setProperty formatOptions 82 file.jpeg --out file.jpeg
```

PDFs (Ghostscript):
```
gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dDownsampleColorImages=true \
  -dColorImageResolution=100 -dGrayImageResolution=100 -dMonoImageResolution=100 \
  -dColorImageDownsampleType=/Bicubic -dGrayImageDownsampleType=/Bicubic \
  -dMonoImageDownsampleType=/Bicubic -dNOPAUSE -dQUIET -dBATCH \
  -sOutputFile=out.pdf in.pdf
```

Both recipes overwrite or emit next to the source, so run them on the companion copy — never on the only copy you have.
