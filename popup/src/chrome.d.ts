interface ChromeStorageLocal {
  get(
    keys: string | string[],
    callback: (items: Record<string, unknown>) => void
  ): void;
  set(items: Record<string, unknown>, callback?: () => void): void;
}

interface ChromeTabs {
  query(
    queryInfo: { active?: boolean; currentWindow?: boolean },
    callback: (tabs: Array<{ id?: number; url?: string }>) => void
  ): void;
  reload(tabId: number): void;
  sendMessage(
    tabId: number,
    message: unknown,
    callback: (response: unknown) => void
  ): void;
}

declare const chrome: {
  storage: { local: ChromeStorageLocal };
  runtime: {
    sendMessage: (message: unknown) => void;
    lastError?: { message?: string };
  };
  tabs: ChromeTabs;
};
