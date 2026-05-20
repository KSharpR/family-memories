export type Language = "zh" | "en";

export const LANGUAGE_STORAGE_KEY = "family-memories:language";

const englishMonthNames = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December"
];

export interface AppCopy {
  language: {
    ariaLabel: string;
    current: string;
    menuLabel: string;
    zh: string;
    en: string;
  };
  appTitle: string;
  albumActionsLabel: string;
  viewTabsLabel: string;
  photoCount(count: number): string;
  actions: {
    addPhotos: string;
    import: string;
    export: string;
  };
  views: {
    timeline: string;
    album: string;
    familyTree: string;
    slideshow: string;
  };
  states: {
    loading: string;
    retry: string;
  };
  errors: {
    loadFailed: string;
    exportFailed: string;
    importFailed: string;
    deleteFailed: string;
    readImageFailed: string;
    saveFailed: string;
    invalidImageType: string;
    imageTooLarge: string;
  };
  toasts: {
    exportSuccess: string;
    importSuccess: string;
    saveNew: string;
    saveEdit: string;
    delete: string;
  };
  upload: {
    title: string;
    copy: string;
    reading: string;
  };
  timeline: {
    emptyTitle: string;
    emptyCopy: string;
    ariaLabel: string;
    formatMonth(year: string, month: string): string;
  };
  memoryCard: {
    fallbackStory: string;
    fallbackDate: string;
    peopleLabel: string;
    edit: string;
    delete: string;
  };
  editor: {
    newTitle: string;
    editTitle: string;
    close: string;
    story: string;
    storyPlaceholder: string;
    date: string;
    filter: string;
    filterNone: string;
    filterSepia: string;
    people: string;
    peoplePlaceholder: string;
    cancel: string;
    saving: string;
    save: string;
  };
  album: {
    emptyTitle: string;
    emptyCopy: string;
    ariaLabel: string;
    pageControlsLabel: string;
    fallbackStory: string;
    fallbackDate: string;
    pageNumberLabel: string;
    peopleLabel: string;
    previous: string;
    next: string;
  };
  familyTree: {
    emptyTitle: string;
    emptyCopy: string;
    title: string;
    intro: string;
    graphLabel: string;
    summaryTitle: string;
    summaryLabel: string;
    describeGraph(nodeCount: number, linkCount: number): string;
    nodeSummary(name: string, count: number): string;
    linkSummary(source: string, target: string, count: number): string;
  };
  slideshow: {
    emptyTitle: string;
    emptyCopy: string;
    ariaLabel: string;
    captionLabel: string;
    controlsLabel: string;
    pageNumberLabel: string;
    peopleLabel: string;
    fallbackStory: string;
    fallbackDate: string;
    previous: string;
    play: string;
    pause: string;
    next: string;
  };
}

export const translations: Record<Language, AppCopy> = {
  zh: {
    language: {
      ariaLabel: "语言 / Language",
      current: "中文",
      menuLabel: "选择语言",
      zh: "中文",
      en: "English"
    },
    appTitle: "家族回忆记录册",
    albumActionsLabel: "相册操作",
    viewTabsLabel: "相册视图",
    photoCount: (count) => `${count} 张照片正在记录`,
    actions: {
      addPhotos: "添加照片",
      import: "导入",
      export: "导出"
    },
    views: {
      timeline: "时间线",
      album: "翻页相册",
      familyTree: "人物关系",
      slideshow: "幻灯片"
    },
    states: {
      loading: "正在整理相册...",
      retry: "重试"
    },
    errors: {
      loadFailed: "相册数据加载失败",
      exportFailed: "相册导出失败",
      importFailed: "导入失败",
      deleteFailed: "删除回忆失败",
      readImageFailed: "图片读取失败",
      saveFailed: "回忆保存失败",
      invalidImageType: "请上传 JPG、PNG、WebP 或 GIF 图片",
      imageTooLarge: "单张图片不能超过 10MB"
    },
    toasts: {
      exportSuccess: "已导出备份文件",
      importSuccess: "已导入相册备份",
      saveNew: "已保存回忆",
      saveEdit: "已更新回忆",
      delete: "已删除回忆"
    },
    upload: {
      title: "把照片拖到这里",
      copy: "支持 JPG、PNG、WebP、GIF，单张不超过 10MB。",
      reading: "读取中..."
    },
    timeline: {
      emptyTitle: "还没有照片",
      emptyCopy: "添加第一张照片，开始整理家族回忆。",
      ariaLabel: "回忆时间线",
      formatMonth: (year, month) => `${year}年${month}月`
    },
    memoryCard: {
      fallbackStory: "这段回忆还没有文字。",
      fallbackDate: "未注明日期",
      peopleLabel: "照片中的人物",
      edit: "编辑",
      delete: "删除"
    },
    editor: {
      newTitle: "记录新回忆",
      editTitle: "编辑回忆",
      close: "关闭",
      story: "故事",
      storyPlaceholder: "写下这张照片背后的故事",
      date: "日期",
      filter: "滤镜",
      filterNone: "原图",
      filterSepia: "怀旧",
      people: "人物",
      peoplePlaceholder: "用逗号、中文逗号或换行分隔",
      cancel: "取消",
      saving: "保存中...",
      save: "保存回忆"
    },
    album: {
      emptyTitle: "相册还没有内容",
      emptyCopy: "回到时间线添加照片后，这里会生成翻页相册。",
      ariaLabel: "翻页相册",
      pageControlsLabel: "相册翻页",
      fallbackStory: "照片记录了这段时光。",
      fallbackDate: "未标注日期",
      pageNumberLabel: "页码",
      peopleLabel: "照片中的人物",
      previous: "上一页",
      next: "下一页"
    },
    familyTree: {
      emptyTitle: "还没有人物关系",
      emptyCopy: "在照片中添加人物标签后，这里会显示同框关系。",
      title: "人物同框关系",
      intro: "这里根据照片中的人物标签整理同框次数，只表示共同出现在照片中，不代表法律或家庭关系。",
      graphLabel: "人物同框关系图",
      summaryTitle: "同框摘要",
      summaryLabel: "人物同框关系摘要",
      describeGraph: (nodeCount, linkCount) =>
        `共有 ${nodeCount} 个人物节点和 ${linkCount} 条同框关系。详细关系见图下方同框摘要。`,
      nodeSummary: (name, count) => `${name}：${count} 张照片`,
      linkSummary: (source, target, count) => `${source} 和 ${target}：${count} 次同框`
    },
    slideshow: {
      emptyTitle: "还没有可播放的照片",
      emptyCopy: "回到时间线添加照片后，可以在这里播放回忆。",
      ariaLabel: "幻灯片播放",
      captionLabel: "幻灯片说明",
      controlsLabel: "幻灯片控制",
      pageNumberLabel: "幻灯片页码",
      peopleLabel: "照片中的人物",
      fallbackStory: "照片记录了这段时光。",
      fallbackDate: "未标注日期",
      previous: "上一张",
      play: "播放",
      pause: "暂停",
      next: "下一张"
    }
  },
  en: {
    language: {
      ariaLabel: "Language",
      current: "English",
      menuLabel: "Choose language",
      zh: "中文",
      en: "English"
    },
    appTitle: "Family Memory Album",
    albumActionsLabel: "Album actions",
    viewTabsLabel: "Album views",
    photoCount: (count) => `${count} ${count === 1 ? "photo" : "photos"} recorded`,
    actions: {
      addPhotos: "Add Photos",
      import: "Import",
      export: "Export"
    },
    views: {
      timeline: "Timeline",
      album: "Album",
      familyTree: "People Graph",
      slideshow: "Slideshow"
    },
    states: {
      loading: "Organizing album...",
      retry: "Retry"
    },
    errors: {
      loadFailed: "Album data failed to load",
      exportFailed: "Album export failed",
      importFailed: "Import failed",
      deleteFailed: "Failed to delete memory",
      readImageFailed: "Image read failed",
      saveFailed: "Failed to save memory",
      invalidImageType: "Upload a JPG, PNG, WebP, or GIF image",
      imageTooLarge: "Each image must be 10MB or smaller"
    },
    toasts: {
      exportSuccess: "Backup file exported",
      importSuccess: "Album backup imported",
      saveNew: "Memory saved",
      saveEdit: "Memory updated",
      delete: "Memory deleted"
    },
    upload: {
      title: "Drop photos here",
      copy: "Supports JPG, PNG, WebP, and GIF. Each file must be 10MB or smaller.",
      reading: "Reading..."
    },
    timeline: {
      emptyTitle: "No photos yet",
      emptyCopy: "Add the first photo to start organizing family memories.",
      ariaLabel: "Memory timeline",
      formatMonth: (year, month) => `${englishMonthNames[Number(month) - 1] ?? month} ${year}`
    },
    memoryCard: {
      fallbackStory: "This memory does not have a story yet.",
      fallbackDate: "Undated",
      peopleLabel: "People in this photo",
      edit: "Edit",
      delete: "Delete"
    },
    editor: {
      newTitle: "Record a New Memory",
      editTitle: "Edit Memory",
      close: "Close",
      story: "Story",
      storyPlaceholder: "Write the story behind this photo",
      date: "Date",
      filter: "Filter",
      filterNone: "Original",
      filterSepia: "Vintage",
      people: "People",
      peoplePlaceholder: "Separate names with commas or new lines",
      cancel: "Cancel",
      saving: "Saving...",
      save: "Save Memory"
    },
    album: {
      emptyTitle: "The album is empty",
      emptyCopy: "Add photos from the timeline to build a page-style album here.",
      ariaLabel: "Page-style album",
      pageControlsLabel: "Album page controls",
      fallbackStory: "This photo captured a family moment.",
      fallbackDate: "Undated",
      pageNumberLabel: "Page number",
      peopleLabel: "People in this photo",
      previous: "Previous Page",
      next: "Next Page"
    },
    familyTree: {
      emptyTitle: "No people graph yet",
      emptyCopy: "Add people tags to photos to see co-appearance relationships here.",
      title: "People Co-Appearance Graph",
      intro:
        "This graph counts how often people tags appear together in photos. It shows co-appearance, not legal or family relationships.",
      graphLabel: "People co-appearance graph",
      summaryTitle: "Co-Appearance Summary",
      summaryLabel: "People co-appearance summary",
      describeGraph: (nodeCount, linkCount) =>
        `There ${nodeCount === 1 ? "is" : "are"} ${nodeCount} ${
          nodeCount === 1 ? "person node" : "person nodes"
        } and ${linkCount} ${linkCount === 1 ? "co-appearance link" : "co-appearance links"}. Details are listed below the graph.`,
      nodeSummary: (name, count) => `${name}: ${count} ${count === 1 ? "photo" : "photos"}`,
      linkSummary: (source, target, count) =>
        `${source} and ${target}: ${count} ${count === 1 ? "co-appearance" : "co-appearances"}`
    },
    slideshow: {
      emptyTitle: "No photos to play",
      emptyCopy: "Add photos from the timeline to play memories here.",
      ariaLabel: "Slideshow playback",
      captionLabel: "Slide caption",
      controlsLabel: "Slideshow controls",
      pageNumberLabel: "Slide number",
      peopleLabel: "People in this photo",
      fallbackStory: "This photo captured a family moment.",
      fallbackDate: "Undated",
      previous: "Previous",
      play: "Play",
      pause: "Pause",
      next: "Next"
    }
  }
};

export function readStoredLanguage(): Language {
  try {
    return parseLanguage(window.localStorage.getItem(LANGUAGE_STORAGE_KEY));
  } catch {
    return "zh";
  }
}

export function writeStoredLanguage(language: Language): void {
  try {
    window.localStorage.setItem(LANGUAGE_STORAGE_KEY, language);
  } catch {
    // Language selection should still work in-memory if persistence is unavailable.
  }
}

function parseLanguage(value: string | null): Language {
  return value === "en" ? "en" : "zh";
}
