import type { Album, MemoryItem, NewMemoryInput, UpdateMemoryInput } from "../domain/memory";
import type { MemoryRepository } from "../domain/repository";
import { createEmptyAlbum, normalizePeople, parseAlbumJson, serializeAlbum } from "./serializers";

const STORAGE_KEY = "family-memories:album:v1";

export interface StorageLike {
  getItem(key: string): string | null;
  setItem(key: string, value: string): void;
  removeItem(key: string): void;
}

interface RepositoryOptions {
  storage?: StorageLike;
  now?: () => string;
  createId?: () => string;
}

export function createLocalMemoryRepository(
  options: RepositoryOptions = {}
): MemoryRepository {
  const storage = options.storage ?? window.localStorage;
  const now = options.now ?? (() => new Date().toISOString());
  const createId = options.createId ?? createMemoryId;

  async function loadAlbum(): Promise<Album> {
    const saved = storage.getItem(STORAGE_KEY);
    if (!saved) {
      return createEmptyAlbum(now());
    }

    return parseAlbumJson(saved);
  }

  async function saveAlbum(album: Album): Promise<void> {
    const nextAlbum: Album = {
      ...album,
      updatedAt: now()
    };
    const serialized = serializeAlbum(nextAlbum);
    parseAlbumJson(serialized);
    storage.setItem(STORAGE_KEY, serialized);
  }

  async function addMemory(input: NewMemoryInput): Promise<MemoryItem> {
    const album = await loadAlbum();
    const timestamp = now();
    const memory: MemoryItem = {
      id: createId(),
      photoDataUrl: input.photoDataUrl,
      story: input.story.trim(),
      date: input.date,
      people: normalizePeople(input.people),
      filter: input.filter ?? "none",
      createdAt: timestamp,
      updatedAt: timestamp
    };

    await saveAlbum({
      ...album,
      memories: [memory, ...album.memories]
    });

    return memory;
  }

  async function updateMemory(id: string, input: UpdateMemoryInput): Promise<MemoryItem> {
    const album = await loadAlbum();
    const index = album.memories.findIndex((memory) => memory.id === id);

    if (index === -1) {
      throw new Error("Memory was not found");
    }

    const current = album.memories[index];
    const updated: MemoryItem = {
      id: current.id,
      photoDataUrl: input.photoDataUrl ?? current.photoDataUrl,
      story: input.story === undefined ? current.story : input.story.trim(),
      date: input.date === undefined ? current.date : input.date,
      people: input.people === undefined ? current.people : normalizePeople(input.people),
      filter: input.filter ?? current.filter,
      createdAt: current.createdAt,
      updatedAt: now()
    };
    const memories = [...album.memories];
    memories[index] = updated;

    await saveAlbum({
      ...album,
      memories
    });

    return updated;
  }

  async function deleteMemory(id: string): Promise<void> {
    const album = await loadAlbum();
    await saveAlbum({
      ...album,
      memories: album.memories.filter((memory) => memory.id !== id)
    });
  }

  async function exportAlbum(): Promise<string> {
    return serializeAlbum(await loadAlbum());
  }

  async function importAlbum(serialized: string): Promise<Album> {
    const album = parseAlbumJson(serialized);
    await saveAlbum(album);
    return album;
  }

  return {
    loadAlbum,
    saveAlbum,
    addMemory,
    updateMemory,
    deleteMemory,
    exportAlbum,
    importAlbum
  };
}

function createMemoryId(): string {
  if (typeof crypto !== "undefined" && "randomUUID" in crypto) {
    return crypto.randomUUID();
  }

  return `memory-${Date.now()}-${Math.random().toString(36).slice(2)}`;
}
