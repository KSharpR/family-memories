import { describe, expect, it } from "vitest";
import {
  createEmptyAlbum,
  normalizePeople,
  parseAlbumJson,
  serializeAlbum
} from "./serializers";
import type { Album } from "../domain/memory";

describe("album serializers", () => {
  it("creates an empty warm-paper album", () => {
    const album = createEmptyAlbum("2026-05-20T00:00:00.000Z");

    expect(album).toMatchObject({
      id: "local-album",
      title: "家族回忆记录册",
      memories: [],
      settings: {
        theme: "warm-paper",
        sortOrder: "desc"
      },
      createdAt: "2026-05-20T00:00:00.000Z",
      updatedAt: "2026-05-20T00:00:00.000Z"
    });
  });

  it("normalizes people tags by trimming, dropping blanks, and deduplicating", () => {
    expect(normalizePeople([" 爷爷 ", "", "妈妈", "爷爷", "妈妈 "])).toEqual([
      "爷爷",
      "妈妈"
    ]);
  });

  it("round-trips a valid album", () => {
    const album: Album = {
      id: "local-album",
      title: "家族回忆记录册",
      settings: { theme: "warm-paper", sortOrder: "desc" },
      createdAt: "2026-05-20T00:00:00.000Z",
      updatedAt: "2026-05-20T00:00:00.000Z",
      memories: [
        {
          id: "memory-1",
          photoDataUrl: "data:image/png;base64,YWJj",
          story: "一起包饺子的下午",
          date: "2026-02-10",
          people: ["奶奶", "我"],
          filter: "sepia",
          createdAt: "2026-05-20T00:00:00.000Z",
          updatedAt: "2026-05-20T00:00:00.000Z"
        }
      ]
    };

    expect(parseAlbumJson(serializeAlbum(album))).toEqual(album);
  });

  it("rejects invalid import data", () => {
    expect(() => parseAlbumJson("{\"memories\":\"bad\"}")).toThrow(
      "Album import file is not compatible"
    );
  });

  it("rejects unsupported or malformed image data urls", () => {
    const album: Album = {
      ...createEmptyAlbum("2026-05-20T00:00:00.000Z"),
      memories: [
        {
          id: "memory-1",
          photoDataUrl: "data:image/svg+xml;base64,abc",
          story: "bad image",
          date: "2026-05-20",
          people: [],
          filter: "none",
          createdAt: "2026-05-20T00:00:00.000Z",
          updatedAt: "2026-05-20T00:00:00.000Z"
        }
      ]
    };

    expect(() => parseAlbumJson(serializeAlbum(album))).toThrow(
      "Album import file is not compatible"
    );
    expect(() =>
      parseAlbumJson(
        serializeAlbum({
          ...album,
          memories: [
            {
              ...album.memories[0],
              photoDataUrl: "data:image/png,abc"
            }
          ]
        })
      )
    ).toThrow("Album import file is not compatible");
  });

  it("rejects image data urls with invalid base64 payloads", () => {
    const album: Album = {
      ...createEmptyAlbum("2026-05-20T00:00:00.000Z"),
      memories: [
        {
          id: "memory-1",
          photoDataUrl: "data:image/png;base64,a",
          story: "bad base64",
          date: "2026-05-20",
          people: [],
          filter: "none",
          createdAt: "2026-05-20T00:00:00.000Z",
          updatedAt: "2026-05-20T00:00:00.000Z"
        }
      ]
    };

    expect(() => parseAlbumJson(serializeAlbum(album))).toThrow(
      "Album import file is not compatible"
    );
    expect(() =>
      parseAlbumJson(
        serializeAlbum({
          ...album,
          memories: [
            {
              ...album.memories[0],
              photoDataUrl: "data:image/png;base64,a="
            }
          ]
        })
      )
    ).toThrow("Album import file is not compatible");
    expect(() =>
      parseAlbumJson(
        serializeAlbum({
          ...album,
          memories: [
            {
              ...album.memories[0],
              photoDataUrl: "data:image/png;base64,a=="
            }
          ]
        })
      )
    ).toThrow("Album import file is not compatible");
  });

  it("rejects oversized image data urls", () => {
    const oversizedPayload = "a".repeat(14 * 1024 * 1024);
    const album: Album = {
      ...createEmptyAlbum("2026-05-20T00:00:00.000Z"),
      memories: [
        {
          id: "memory-1",
          photoDataUrl: `data:image/png;base64,${oversizedPayload}`,
          story: "too large",
          date: "2026-05-20",
          people: [],
          filter: "none",
          createdAt: "2026-05-20T00:00:00.000Z",
          updatedAt: "2026-05-20T00:00:00.000Z"
        }
      ]
    };

    expect(() => parseAlbumJson(serializeAlbum(album))).toThrow(
      "Album import file is not compatible"
    );
  });

  it("rejects duplicate or blank memory ids", () => {
    const memory = {
      id: "memory-1",
      photoDataUrl: "data:image/png;base64,YWJj",
      story: "duplicated",
      date: "2026-05-20",
      people: [],
      filter: "none" as const,
      createdAt: "2026-05-20T00:00:00.000Z",
      updatedAt: "2026-05-20T00:00:00.000Z"
    };
    const album: Album = {
      ...createEmptyAlbum("2026-05-20T00:00:00.000Z"),
      memories: [memory, { ...memory }]
    };

    expect(() => parseAlbumJson(serializeAlbum(album))).toThrow(
      "Album import file is not compatible"
    );
    expect(() =>
      parseAlbumJson(
        serializeAlbum({
          ...album,
          memories: [{ ...memory, id: "  " }]
        })
      )
    ).toThrow("Album import file is not compatible");
  });

  it("rejects invalid dates and non-string people tags", () => {
    const album = {
      ...createEmptyAlbum("2026-05-20T00:00:00.000Z"),
      memories: [
        {
          id: "memory-1",
          photoDataUrl: "data:image/png;base64,YWJj",
          story: "invalid fields",
          date: "20-05-2026",
          people: ["我"],
          filter: "none",
          createdAt: "2026-05-20T00:00:00.000Z",
          updatedAt: "2026-05-20T00:00:00.000Z"
        }
      ]
    };

    expect(() => parseAlbumJson(JSON.stringify(album))).toThrow(
      "Album import file is not compatible"
    );
    expect(() =>
      parseAlbumJson(
        JSON.stringify({
          ...album,
          memories: [
            {
              ...album.memories[0],
              date: "2026-05-20",
              people: ["我", null]
            }
          ]
        })
      )
    ).toThrow("Album import file is not compatible");
  });
});
