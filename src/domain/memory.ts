export type MemoryFilter = "none" | "sepia";
export type ThemeName = "warm-paper";
export type SortOrder = "asc" | "desc";

export interface AlbumSettings {
  theme: ThemeName;
  sortOrder: SortOrder;
}

export interface MemoryItem {
  id: string;
  photoDataUrl: string;
  story: string;
  date: string | null;
  people: string[];
  filter: MemoryFilter;
  createdAt: string;
  updatedAt: string;
}

export interface Album {
  id: string;
  title: string;
  memories: MemoryItem[];
  settings: AlbumSettings;
  createdAt: string;
  updatedAt: string;
}

export interface NewMemoryInput {
  photoDataUrl: string;
  story: string;
  date: string | null;
  people: string[];
  filter?: MemoryFilter;
}

export interface UpdateMemoryInput {
  photoDataUrl?: string;
  story?: string;
  date?: string | null;
  people?: string[];
  filter?: MemoryFilter;
}
