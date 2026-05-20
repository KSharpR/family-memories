import { describe, expect, it } from "vitest";
import { createEmptyAlbum } from "./serializers";
import { createLocalMemoryRepository, type StorageLike } from "./localMemoryRepository";
import type { Album } from "../domain/memory";

class MemoryStorage implements StorageLike {
  private values = new Map<string, string>();

  getItem(key: string): string | null {
    return this.values.get(key) ?? null;
  }

  setItem(key: string, value: string): void {
    this.values.set(key, value);
  }

  removeItem(key: string): void {
    this.values.delete(key);
  }

  savedValue(key: string): string | null {
    return this.getItem(key);
  }
}

const storageKey = "family-memories:album:v1";

describe("local memory repository", () => {
  it("loads an empty album when storage is empty", async () => {
    const repository = createLocalMemoryRepository({
      storage: new MemoryStorage(),
      now: () => "2026-05-20T00:00:00.000Z",
      createId: () => "memory-1"
    });

    await expect(repository.loadAlbum()).resolves.toMatchObject({
      id: "local-album",
      memories: []
    });
  });

  it("adds, updates, deletes, exports, and imports memories", async () => {
    const storage = new MemoryStorage();
    let idCounter = 0;
    const repository = createLocalMemoryRepository({
      storage,
      now: () => "2026-05-20T00:00:00.000Z",
      createId: () => `memory-${++idCounter}`
    });

    const added = await repository.addMemory({
      photoDataUrl: "data:image/png;base64,YWJj",
      story: "第一张照片",
      date: "2026-05-20",
      people: [" 爸爸 ", "爸爸", "我"],
      filter: "none"
    });

    expect(added).toMatchObject({
      id: "memory-1",
      people: ["爸爸", "我"]
    });

    const updated = await repository.updateMemory("memory-1", {
      story: "更新后的故事",
      filter: "sepia"
    });

    expect(updated.story).toBe("更新后的故事");
    expect(updated.filter).toBe("sepia");

    const exported = await repository.exportAlbum();
    const secondRepository = createLocalMemoryRepository({
      storage: new MemoryStorage(),
      now: () => "2026-05-20T00:00:00.000Z",
      createId: () => "memory-2"
    });

    const imported = await secondRepository.importAlbum(exported);
    expect(imported.memories).toHaveLength(1);

    await secondRepository.deleteMemory("memory-1");
    await expect(secondRepository.loadAlbum()).resolves.toMatchObject({
      memories: []
    });
  });

  it("throws a clear error when updating a missing memory", async () => {
    const repository = createLocalMemoryRepository({
      storage: new MemoryStorage(),
      now: () => "2026-05-20T00:00:00.000Z",
      createId: () => "memory-1"
    });

    await expect(repository.updateMemory("missing", { story: "x" })).rejects.toThrow(
      "Memory was not found"
    );
  });

  it("does not persist albums that cannot be loaded again", async () => {
    const storage = new MemoryStorage();
    const repository = createLocalMemoryRepository({
      storage,
      now: () => "2026-05-20T00:00:00.000Z",
      createId: () => "memory-1"
    });
    const invalidAlbum: Album = {
      ...createEmptyAlbum("2026-05-20T00:00:00.000Z"),
      memories: [
        {
          id: "memory-1",
          photoDataUrl: "data:image/png;base64,a",
          story: "bad image",
          date: "2026-05-20",
          people: [],
          filter: "none",
          createdAt: "2026-05-20T00:00:00.000Z",
          updatedAt: "2026-05-20T00:00:00.000Z"
        }
      ]
    };

    await expect(repository.saveAlbum(invalidAlbum)).rejects.toThrow(
      "Album import file is not compatible"
    );
    expect(storage.savedValue(storageKey)).toBeNull();
  });
});
