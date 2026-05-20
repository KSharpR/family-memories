import type { Album, MemoryFilter, MemoryItem } from "../domain/memory";

export const IMPORT_ERROR_MESSAGE = "Album import file is not compatible";
const MAX_IMAGE_BYTES = 10 * 1024 * 1024;
const IMAGE_DATA_URL_PATTERN =
  /^data:image\/(jpeg|jpg|png|webp|gif);base64,([A-Za-z0-9+/]+={0,2})$/;
const DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;
const BASE64_PAYLOAD_PATTERN = /^[A-Za-z0-9+/]+={0,2}$/;

export function createEmptyAlbum(now = new Date().toISOString()): Album {
  return {
    id: "local-album",
    title: "家族回忆记录册",
    memories: [],
    settings: {
      theme: "warm-paper",
      sortOrder: "desc"
    },
    createdAt: now,
    updatedAt: now
  };
}

export function normalizePeople(people: string[]): string[] {
  const seen = new Set<string>();
  const normalized: string[] = [];

  for (const person of people) {
    const trimmed = person.trim();
    if (trimmed.length === 0 || seen.has(trimmed)) {
      continue;
    }
    seen.add(trimmed);
    normalized.push(trimmed);
  }

  return normalized;
}

export function serializeAlbum(album: Album): string {
  return JSON.stringify(album, null, 2);
}

export function parseAlbumJson(serialized: string): Album {
  try {
    const parsed: unknown = JSON.parse(serialized);
    return coerceAlbum(parsed);
  } catch (error) {
    if (error instanceof Error && error.message === IMPORT_ERROR_MESSAGE) {
      throw error;
    }
    throw new Error(IMPORT_ERROR_MESSAGE);
  }
}

function coerceAlbum(value: unknown): Album {
  if (!isRecord(value) || !Array.isArray(value.memories)) {
    throw new Error(IMPORT_ERROR_MESSAGE);
  }

  const now = new Date().toISOString();
  const settingsValue: Record<string, unknown> = isRecord(value.settings)
    ? value.settings
    : {};

  const seenMemoryIds = new Set<string>();

  return {
    id: readString(value.id, "local-album"),
    title: readString(value.title, "家族回忆记录册"),
    settings: {
      theme: "warm-paper",
      sortOrder: settingsValue.sortOrder === "asc" ? "asc" : "desc"
    },
    createdAt: readString(value.createdAt, now),
    updatedAt: readString(value.updatedAt, now),
    memories: value.memories.map((memory) => coerceMemory(memory, seenMemoryIds))
  };
}

function coerceMemory(value: unknown, seenMemoryIds: Set<string>): MemoryItem {
  if (!isRecord(value)) {
    throw new Error(IMPORT_ERROR_MESSAGE);
  }

  const id = readRequiredString(value.id).trim();
  if (seenMemoryIds.has(id)) {
    throw new Error(IMPORT_ERROR_MESSAGE);
  }
  seenMemoryIds.add(id);

  const photoDataUrl = readString(value.photoDataUrl ?? value.photo, "");

  if (!isAllowedImageDataUrl(photoDataUrl)) {
    throw new Error(IMPORT_ERROR_MESSAGE);
  }

  const now = new Date().toISOString();

  return {
    id,
    photoDataUrl,
    story: readString(value.story ?? value.text, ""),
    date: readDate(value.date),
    people: readPeople(value.people),
    filter: readFilter(value.filter),
    createdAt: readString(value.createdAt, now),
    updatedAt: readString(value.updatedAt, now)
  };
}

function readFilter(value: unknown): MemoryFilter {
  return value === "sepia" ? "sepia" : "none";
}

function readString(value: unknown, fallback: string): string {
  return typeof value === "string" ? value : fallback;
}

function readRequiredString(value: unknown): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new Error(IMPORT_ERROR_MESSAGE);
  }
  return value;
}

function readDate(value: unknown): string | null {
  if (value === undefined || value === null || value === "") {
    return null;
  }
  if (typeof value !== "string" || !DATE_PATTERN.test(value)) {
    throw new Error(IMPORT_ERROR_MESSAGE);
  }

  const parsed = new Date(`${value}T00:00:00.000Z`);
  if (Number.isNaN(parsed.getTime()) || parsed.toISOString().slice(0, 10) !== value) {
    throw new Error(IMPORT_ERROR_MESSAGE);
  }

  return value;
}

function readPeople(value: unknown): string[] {
  if (value === undefined) {
    return [];
  }
  if (!Array.isArray(value) || !value.every((person) => typeof person === "string")) {
    throw new Error(IMPORT_ERROR_MESSAGE);
  }
  return normalizePeople(value);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function isAllowedImageDataUrl(value: string): boolean {
  const match = IMAGE_DATA_URL_PATTERN.exec(value);
  if (!match) {
    return false;
  }

  const payload = match[2];

  return isValidBase64Payload(payload) && estimateBase64Bytes(payload) <= MAX_IMAGE_BYTES;
}

function estimateBase64Bytes(payload: string): number {
  const padding = payload.endsWith("==") ? 2 : payload.endsWith("=") ? 1 : 0;
  return Math.floor((payload.length * 3) / 4) - padding;
}

function isValidBase64Payload(payload: string): boolean {
  if (payload.length === 0 || payload.length % 4 !== 0) {
    return false;
  }
  if (!BASE64_PAYLOAD_PATTERN.test(payload)) {
    return false;
  }

  const firstPadding = payload.indexOf("=");
  return firstPadding === -1 || /^={1,2}$/.test(payload.slice(firstPadding));
}
