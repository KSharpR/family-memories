# Family Memories Backup Format

This document defines the current native iOS `.familymemories` backup package contract.

## Goals

- Preserve family memories without accounts or app-owned servers.
- Keep backups user-controlled and portable.
- Make future data migrations explicit through version fields.
- Keep enough structure aligned with the web MVP to support later cross-platform migration.

## Package

Backup files use the extension:

```text
.familymemories
```

The current package is an uncompressed ZIP archive written by the app. Compression is not required for v1. Readers must reject compressed entries until compression support is intentionally added and tested.

Required entries:

```text
manifest.json
memories.json
Originals/<memory-id>.<extension>
Thumbnails/<memory-id>.jpg
```

Example:

```text
family-memories-2026-05-24T11-00-00Z.familymemories
  manifest.json
  memories.json
  Originals/6F5D.jpg
  Thumbnails/6F5D.jpg
```

## manifest.json

Current fields:

```json
{
  "appName": "Family Memories",
  "backupVersion": 1,
  "dataSchemaVersion": 1,
  "createdAt": "2026-05-24T00:00:00Z",
  "memoryCount": 3,
  "locale": "zh-Hans",
  "minimumSupportedAppVersion": "0.1.0"
}
```

Field meanings:

- `appName`: Human-readable source app name.
- `backupVersion`: Backup package format version. Current value is `1`.
- `dataSchemaVersion`: App data model version used by exported memory records. Current value is `1`.
- `createdAt`: ISO 8601 timestamp when the backup was created.
- `memoryCount`: Number of records in `memories.json`.
- `locale`: UI locale active during export.
- `minimumSupportedAppVersion`: Minimum app version expected to understand this package.

Compatibility rule:

- `dataSchemaVersion` is optional when reading older v1 backups. If absent, readers treat it as schema version `1`.
- A `backupVersion` other than `1` must be rejected until a migration path is implemented.

## memories.json

`memories.json` is an array of memory records.

Current memory fields:

```json
{
  "id": "6F5D",
  "originalFilename": "family.jpg",
  "originalPath": "Originals/6F5D.jpg",
  "thumbnailPath": "Thumbnails/6F5D.jpg",
  "story": "Dinner together",
  "date": "2026-05-24T00:00:00Z",
  "people": ["Mom", "Dad"],
  "filter": "original",
  "createdAt": "2026-05-24T00:00:00Z",
  "updatedAt": "2026-05-24T00:00:00Z",
  "sourceCreatedAt": "2026-05-20T00:00:00Z",
  "sourceAssetIdentifier": "local-photo-asset-id"
}
```

Field meanings:

- `id`: Stable memory ID. Used for metadata identity, file names, restore identity, and overwrite matching.
- `originalFilename`: Original user-facing filename when available.
- `originalPath`: Relative path to the original copied image in the backup.
- `thumbnailPath`: Relative path to the stored thumbnail in the backup.
- `story`: User-entered story text. Do not translate it during import.
- `date`: User-facing memory date. Users can edit this after import.
- `people`: User-entered people tags. Import normalizes whitespace and exact duplicates only.
- `filter`: Compatibility/future editing field. Current value is usually `original`.
- `createdAt`: Memory record creation time.
- `updatedAt`: Last update time.
- `sourceCreatedAt`: Photo capture date when available.
- `sourceAssetIdentifier`: Optional origin identifier. Readers must not require it to load a memory.

## Validation Rules

Readers must validate before mutating local app data:

- Archive must contain a valid central directory and uncompressed entries.
- `manifest.json` must exist.
- `memories.json` must exist.
- `backupVersion` must be supported.
- `memories.count` must equal `manifest.memoryCount`.
- Memory IDs in one backup must be unique.
- `originalPath` must be exactly `Originals/<filename-with-extension>`.
- `thumbnailPath` must be exactly `Thumbnails/<filename-with-extension>`.
- Relative paths must not be empty, absolute, nested, or contain `..`.
- Every referenced original and thumbnail file must exist in the archive.
- Duplicate archive entry names must be rejected.
- Entry checksums and sizes must match the central directory metadata.

## Import Behavior

Current iOS import behavior:

- Validate the backup before any restore operation.
- Show a confirmation before applying the import.
- Show memory count, backup creation time, memory date range, and same-ID match count.
- Merge the backup into the local library.
- Keep local memories unless the backup contains the same memory ID.
- If the backup contains the same memory ID, the imported memory replaces that local metadata record and its image files.
- Invalid backups do not mutate local metadata or local image files.

Replace-all import is not part of the current app. If added later, it must require a separate destructive confirmation.

## Error Reporting

Known backup package errors:

- `invalidArchive`: Damaged or non-Family Memories backup.
- `missingManifest`: Missing `manifest.json`.
- `missingMemories`: Missing `memories.json`.
- `missingFile(path)`: Missing required original or thumbnail file.
- `unsupportedVersion(version)`: Unsupported backup format version.

The app should prefer a specific error message for package-level errors and fall back to a generic invalid-backup message only when the lower-level error is not safe or useful for users.

## Migration Notes

When changing the data model:

1. Add or update `AppDataSchema.currentVersion`.
2. Keep old fields decodable whenever practical.
3. Add tests for reading the previous backup shape.
4. Add tests for exporting the new backup shape.
5. Document the migration in this file.
6. Do not change destructive import behavior without a separate confirmation flow.

When changing package structure:

1. Increment `backupVersion`.
2. Keep v1 import support unless a clear migration path replaces it.
3. Add validation tests for the new required entries.
4. Add clear unsupported-version errors for newer packages.
