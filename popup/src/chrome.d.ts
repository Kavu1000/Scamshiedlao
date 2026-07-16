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
    callback: (tabs: Array<{ id?: number }>) => void
  ): void;
  reload(tabId: number): void;
}

declare const chrome: {
  storage: { local: ChromeStorageLocal };
  runtime: { sendMessage: (message: unknown) => void };
  tabs: ChromeTabs;
};
