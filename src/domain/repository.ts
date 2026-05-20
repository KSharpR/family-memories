import type { Album, MemoryItem, NewMemoryInput, UpdateMemoryInput } from "./memory";

export interface MemoryRepository {
  loadAlbum(): Promise<Album>;
  saveAlbum(album: Album): Promise<void>;
  addMemory(input: NewMemoryInput): Promise<MemoryItem>;
  updateMemory(id: string, input: UpdateMemoryInput): Promise<MemoryItem>;
  deleteMemory(id: string): Promise<void>;
  exportAlbum(): Promise<string>;
  importAlbum(serialized: string): Promise<Album>;
}
