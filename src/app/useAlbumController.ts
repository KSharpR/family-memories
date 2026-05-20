import { useCallback, useEffect, useState } from "react";
import type { Album, MemoryItem, NewMemoryInput, UpdateMemoryInput } from "../domain/memory";
import type { MemoryRepository } from "../domain/repository";
import { createEmptyAlbum } from "../storage/serializers";

export interface AlbumController {
  album: Album;
  memories: MemoryItem[];
  isLoading: boolean;
  error: string | null;
  reload(): Promise<void>;
  addMemory(input: NewMemoryInput): Promise<MemoryItem>;
  updateMemory(id: string, input: UpdateMemoryInput): Promise<MemoryItem>;
  deleteMemory(id: string): Promise<void>;
  exportAlbum(): Promise<string>;
  importAlbum(serialized: string): Promise<Album>;
}

export function useAlbumController(repository: MemoryRepository): AlbumController {
  const [album, setAlbum] = useState<Album>(() => createEmptyAlbum());
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const reload = useCallback(async () => {
    setIsLoading(true);
    setError(null);

    try {
      const nextAlbum = await repository.loadAlbum();
      setAlbum(nextAlbum);
    } catch (caught) {
      setError(readErrorMessage(caught));
    } finally {
      setIsLoading(false);
    }
  }, [repository]);

  useEffect(() => {
    void reload();
  }, [reload]);

  const addMemory = useCallback(
    async (input: NewMemoryInput) => {
      const memory = await repository.addMemory(input);
      await reload();
      return memory;
    },
    [repository, reload]
  );

  const updateMemory = useCallback(
    async (id: string, input: UpdateMemoryInput) => {
      const memory = await repository.updateMemory(id, input);
      await reload();
      return memory;
    },
    [repository, reload]
  );

  const deleteMemory = useCallback(
    async (id: string) => {
      await repository.deleteMemory(id);
      await reload();
    },
    [repository, reload]
  );

  const exportAlbum = useCallback(async () => repository.exportAlbum(), [repository]);

  const importAlbum = useCallback(
    async (serialized: string) => {
      const imported = await repository.importAlbum(serialized);
      await reload();
      return imported;
    },
    [repository, reload]
  );

  return {
    album,
    memories: album.memories,
    isLoading,
    error,
    reload,
    addMemory,
    updateMemory,
    deleteMemory,
    exportAlbum,
    importAlbum
  };
}

function readErrorMessage(error: unknown): string {
  return error instanceof Error ? error.message : "相册数据加载失败";
}
