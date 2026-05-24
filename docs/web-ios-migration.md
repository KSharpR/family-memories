# Web And iOS Migration Notes

This document records the current compatibility path between the web MVP and the native iOS app.

## Current Web Export

The web app exports a single JSON file:

```text
family-memories-YYYY-MM-DD.json
```

The JSON is a serialized `Album` object from `src/domain/memory.ts`.

Current shape:

```json
{
  "id": "local-album",
  "title": "家族回忆记录册",
  "memories": [
    {
      "id": "memory-1",
      "photoDataUrl": "data:image/png;base64,...",
      "story": "一起翻旧照片",
      "date": "2026-05-20",
      "people": ["奶奶", "我"],
      "filter": "sepia",
      "createdAt": "2026-05-20T00:00:00.000Z",
      "updatedAt": "2026-05-20T00:00:00.000Z"
    }
  ],
  "settings": {
    "theme": "warm-paper",
    "sortOrder": "desc"
  },
  "createdAt": "2026-05-20T00:00:00.000Z",
  "updatedAt": "2026-05-20T00:00:00.000Z"
}
```

The web app stores image bytes inside `photoDataUrl`. It accepts `jpeg`, `jpg`, `png`, `webp`, and `gif` data URLs, with a web-side maximum image payload of 10 MB.

The web importer also accepts older memory field names:

- `photo` as a fallback for `photoDataUrl`
- `text` as a fallback for `story`

## Current iOS Backup

The iOS app exports a `.familymemories` ZIP package documented in `docs/backup-format.md`.

Required entries:

```text
manifest.json
memories.json
Originals/<memory-id>.<extension>
Thumbnails/<memory-id>.jpg
```

iOS stores original image files and thumbnail files as separate package entries. Metadata in `memories.json` references those relative paths.

## Field Mapping

| Web field | iOS field | Strategy |
| --- | --- | --- |
| `id` | `id` | Keep the same ID when it is safe for iOS file paths. |
| `photoDataUrl` or `photo` | `originalData` | Decode base64 payload and infer the extension from MIME type. |
| MIME subtype | `originalFilename` | Use `<id>.<extension>`, normalizing `jpeg` to `jpg`. |
| `story` or `text` | `story` | Preserve user-written text exactly. |
| `date` | `date` | Convert `YYYY-MM-DD` to UTC midnight. |
| `date: null` | `date` | Fall back to `createdAt`. |
| `people` | `people` | Trim blanks and remove exact duplicates. |
| `filter: "none"` | `filter: "original"` | Map web original state to iOS naming. |
| `filter: "sepia"` | `filter: "sepia"` | Preserve sepia marker. |
| `createdAt` | `createdAt` | Parse ISO timestamp. |
| `updatedAt` | `updatedAt` | Parse ISO timestamp; fall back to `createdAt` if absent. |
| Not present | `sourceCreatedAt` | Keep `nil`. Web does not preserve original photo capture metadata. |
| Not present | `sourceAssetIdentifier` | Keep `nil`. Web has no Photos asset identifier. |

## Compatibility Boundary

The first iOS compatibility layer is `WebAlbumImportAdapter`.

It currently parses Web JSON into import candidates and validates:

- Album has a `memories` array.
- Memory IDs are non-empty, unique, and safe for iOS file paths.
- Image data URLs are supported and base64-decodable.
- Web date strings are valid.
- Legacy `photo` and `text` fields are accepted.

It does not yet expose this as a user-facing Settings import action. The next implementation step is to convert these candidates into saved iOS memories by:

1. Writing decoded original image data through `MemoryFileStore`.
2. Generating iOS JPEG thumbnails.
3. Saving resulting `FamilyMemory` records through `MemoryRepository`.
4. Showing a confirmation that this import merges into the current iOS library, unlike the current web import which replaces the entire web album.

## Thumbnail Decision

iOS `.familymemories` packages require thumbnails in v1. Web JSON does not store thumbnails.

Decision for migration:

- Keep thumbnails required in iOS `.familymemories` v1.
- Regenerate thumbnails during Web-to-iOS import or conversion.
- Do not require the web JSON to include thumbnails.

This keeps web exports simple and avoids increasing browser local storage usage.

## User-Facing Migration Guidance

For users moving from web to iOS:

1. Open the web app.
2. Export the album JSON.
3. Move the JSON file to the iPhone through Files, AirDrop, or another user-controlled location.
4. Import it in the iOS app once the web JSON import action is exposed.
5. Export a `.familymemories` backup from iOS after import.

For users moving from iOS to web:

- Direct iOS `.familymemories` import is not implemented in the web app yet.
- The likely future path is a web-side adapter that reads `manifest.json`, `memories.json`, and image entries, then rebuilds `photoDataUrl` values.

## Behavioral Differences

| Area | Web | iOS |
| --- | --- | --- |
| Backup file | Single `.json` | `.familymemories` ZIP package |
| Image storage | Inline `photoDataUrl` | Separate original and thumbnail files |
| Import behavior | Replaces local web album | Merges into local iOS library; same memory ID overwrites |
| Date model | `YYYY-MM-DD` or `null` | Required `Date` |
| Photo metadata | No original asset metadata | Can preserve selected photo capture date when imported on-device |
| Sync | None | None |

## Open Follow-Ups

- Add a Settings import path for web JSON.
- Generate thumbnails during web JSON import.
- Add a web-side `.familymemories` reader later if iOS-to-web migration becomes important.
- Revisit unsafe web memory IDs if real legacy exports contain characters outside `[A-Za-z0-9_-]`.
