import { str } from './strings';

export const KEY_AUTODOWNLOAD_MASTER: string = 'autoDownloadMaster';
export const KEY_AUTODOWNLOAD_PHOTO_PRIVATE: string = 'autoDownloadPhotoPrivate';
export const KEY_AUTODOWNLOAD_PHOTO_GROUP: string = 'autoDownloadPhotoGroup';
export const KEY_AUTODOWNLOAD_PHOTO_CHANNEL: string = 'autoDownloadPhotoChannel';
export const KEY_AUTODOWNLOAD_VIDEO_PRIVATE: string = 'autoDownloadVideoPrivate';
export const KEY_AUTODOWNLOAD_VIDEO_GROUP: string = 'autoDownloadVideoGroup';
export const KEY_AUTODOWNLOAD_VIDEO_CHANNEL: string = 'autoDownloadVideoChannel';
export const KEY_AUTODOWNLOAD_VIDEO_MAX_MB: string = 'autoDownloadVideoMaxMb';
export const KEY_AUTODOWNLOAD_VIDEO_PRELOAD_LARGE: string = 'autoDownloadVideoPreloadLarge';
export const KEY_AUTODOWNLOAD_VIDEO_PRELOAD_MB: string = 'autoDownloadVideoPreloadMb';
export const KEY_AUTODOWNLOAD_FILE_PRIVATE: string = 'autoDownloadFilePrivate';
export const KEY_AUTODOWNLOAD_FILE_GROUP: string = 'autoDownloadFileGroup';
export const KEY_AUTODOWNLOAD_FILE_CHANNEL: string = 'autoDownloadFileChannel';
export const KEY_AUTODOWNLOAD_FILE_MAX_MB: string = 'autoDownloadFileMaxMb';

export const AUTODOWNLOAD_VIDEO_MAX_MB_STEPS: number[] = [1, 5, 10, 50, 100, 300, 500, 2048];
export const AUTODOWNLOAD_VIDEO_MAX_MB_DEFAULT: number = 10;
export const AUTODOWNLOAD_FILE_MAX_MB_DEFAULT: number = 10;
export const AUTODOWNLOAD_VIDEO_PRELOAD_MB_OPTIONS: number[] = [2, 5, 10, 20];
export const AUTODOWNLOAD_VIDEO_PRELOAD_MB_DEFAULT: number = 10;

const listeners: Set<() => void> = new Set();

export function isAutoDownloadKey(key: string): boolean {
  return key === KEY_AUTODOWNLOAD_MASTER ||
    key === KEY_AUTODOWNLOAD_PHOTO_PRIVATE ||
    key === KEY_AUTODOWNLOAD_PHOTO_GROUP ||
    key === KEY_AUTODOWNLOAD_PHOTO_CHANNEL ||
    key === KEY_AUTODOWNLOAD_VIDEO_PRIVATE ||
    key === KEY_AUTODOWNLOAD_VIDEO_GROUP ||
    key === KEY_AUTODOWNLOAD_VIDEO_CHANNEL ||
    key === KEY_AUTODOWNLOAD_VIDEO_MAX_MB ||
    key === KEY_AUTODOWNLOAD_VIDEO_PRELOAD_LARGE ||
    key === KEY_AUTODOWNLOAD_VIDEO_PRELOAD_MB ||
    key === KEY_AUTODOWNLOAD_FILE_PRIVATE ||
    key === KEY_AUTODOWNLOAD_FILE_GROUP ||
    key === KEY_AUTODOWNLOAD_FILE_CHANNEL ||
    key === KEY_AUTODOWNLOAD_FILE_MAX_MB;
}

export function normalizeAutoDownloadVideoMaxMb(raw: number): number {
  return AUTODOWNLOAD_VIDEO_MAX_MB_STEPS.indexOf(raw) >= 0 ? raw : AUTODOWNLOAD_VIDEO_MAX_MB_DEFAULT;
}

export function autoDownloadVideoMaxMbStepIndex(mb: number): number {
  const idx: number = AUTODOWNLOAD_VIDEO_MAX_MB_STEPS.indexOf(normalizeAutoDownloadVideoMaxMb(mb));
  return idx >= 0 ? idx : 2;
}

export function normalizeAutoDownloadVideoPreloadMb(raw: number): number {
  return AUTODOWNLOAD_VIDEO_PRELOAD_MB_OPTIONS.indexOf(raw) >= 0 ? raw : AUTODOWNLOAD_VIDEO_PRELOAD_MB_DEFAULT;
}

export function formatVideoLimitMb(mb: number): string {
  return mb >= 1024 ? `${Math.round(mb / 1024)} GB` : `${mb} MB`;
}

export function publishAutoDownloadChanged(): void {
  listeners.forEach((listener: () => void): void => listener());
}

export function subscribeAutoDownloadChanged(listener: () => void): () => void {
  listeners.add(listener);
  return (): void => {
    listeners.delete(listener);
  };
}

export function shouldAutoDownloadPhoto(isGroup: boolean, isChannel: boolean): boolean {
  const masterOn: boolean = AppStorage.get<boolean>(KEY_AUTODOWNLOAD_MASTER) ?? true;
  if (!masterOn) {
    return false;
  }
  if (isChannel) {
    return AppStorage.get<boolean>(KEY_AUTODOWNLOAD_PHOTO_CHANNEL) ?? true;
  }
  if (isGroup) {
    return AppStorage.get<boolean>(KEY_AUTODOWNLOAD_PHOTO_GROUP) ?? true;
  }
  return AppStorage.get<boolean>(KEY_AUTODOWNLOAD_PHOTO_PRIVATE) ?? true;
}

export function shouldAutoDownloadVideoInScope(isGroup: boolean, isChannel: boolean): boolean {
  const masterOn: boolean = AppStorage.get<boolean>(KEY_AUTODOWNLOAD_MASTER) ?? true;
  if (!masterOn) {
    return false;
  }
  if (isChannel) {
    return AppStorage.get<boolean>(KEY_AUTODOWNLOAD_VIDEO_CHANNEL) ?? true;
  }
  if (isGroup) {
    return AppStorage.get<boolean>(KEY_AUTODOWNLOAD_VIDEO_GROUP) ?? true;
  }
  return AppStorage.get<boolean>(KEY_AUTODOWNLOAD_VIDEO_PRIVATE) ?? true;
}

export function shouldAutoDownloadFullVideo(isGroup: boolean, isChannel: boolean, fileSizeBytes: number): boolean {
  if (!shouldAutoDownloadVideoInScope(isGroup, isChannel)) {
    return false;
  }
  if (fileSizeBytes <= 0) {
    return false;
  }
  const maxMb: number = normalizeAutoDownloadVideoMaxMb(
    AppStorage.get<number>(KEY_AUTODOWNLOAD_VIDEO_MAX_MB) ?? AUTODOWNLOAD_VIDEO_MAX_MB_DEFAULT
  );
  const maxBytes: number = maxMb * 1024 * 1024;
  return fileSizeBytes <= maxBytes;
}

export function shouldPreloadLargeVideo(isGroup: boolean, isChannel: boolean, fileSizeBytes: number): boolean {
  if (!shouldAutoDownloadVideoInScope(isGroup, isChannel)) {
    return false;
  }
  const preloadOn: boolean = AppStorage.get<boolean>(KEY_AUTODOWNLOAD_VIDEO_PRELOAD_LARGE) ?? true;
  if (!preloadOn) {
    return false;
  }
  const maxMb: number = normalizeAutoDownloadVideoMaxMb(
    AppStorage.get<number>(KEY_AUTODOWNLOAD_VIDEO_MAX_MB) ?? AUTODOWNLOAD_VIDEO_MAX_MB_DEFAULT
  );
  const maxBytes: number = maxMb * 1024 * 1024;
  return fileSizeBytes <= 0 || fileSizeBytes > maxBytes;
}

export function autoDownloadVideoPreloadBytes(fileSizeBytes: number = 0): number {
  const preloadMb: number = normalizeAutoDownloadVideoPreloadMb(
    AppStorage.get<number>(KEY_AUTODOWNLOAD_VIDEO_PRELOAD_MB) ?? AUTODOWNLOAD_VIDEO_PRELOAD_MB_DEFAULT
  );
  const preloadBytes: number = preloadMb * 1024 * 1024;
  const tailReserveBytes: number = 1024 * 1024 + 256 * 1024;
  if (fileSizeBytes > 0 && preloadBytes + tailReserveBytes >= fileSizeBytes) {
    return Math.max(256 * 1024, fileSizeBytes - tailReserveBytes);
  }
  return preloadBytes;
}

export function shouldAutoDownloadFileInScope(isGroup: boolean, isChannel: boolean): boolean {
  const masterOn: boolean = AppStorage.get<boolean>(KEY_AUTODOWNLOAD_MASTER) ?? true;
  if (!masterOn) {
    return false;
  }
  if (isChannel) {
    return AppStorage.get<boolean>(KEY_AUTODOWNLOAD_FILE_CHANNEL) ?? false;
  }
  if (isGroup) {
    return AppStorage.get<boolean>(KEY_AUTODOWNLOAD_FILE_GROUP) ?? false;
  }
  return AppStorage.get<boolean>(KEY_AUTODOWNLOAD_FILE_PRIVATE) ?? false;
}

export function shouldAutoDownloadFile(isGroup: boolean, isChannel: boolean, fileSizeBytes: number): boolean {
  if (!shouldAutoDownloadFileInScope(isGroup, isChannel)) {
    return false;
  }
  if (fileSizeBytes <= 0) {
    return false;
  }
  const maxMb: number = normalizeAutoDownloadVideoMaxMb(
    AppStorage.get<number>(KEY_AUTODOWNLOAD_FILE_MAX_MB) ?? AUTODOWNLOAD_FILE_MAX_MB_DEFAULT
  );
  const maxBytes: number = maxMb * 1024 * 1024;
  return fileSizeBytes <= maxBytes;
}

export function photoAutoDownloadSubtitle(
  masterOn: boolean,
  privateOn: boolean,
  groupOn: boolean,
  channelOn: boolean
): string {
  if (!masterOn) {
    return str('ds_auto_download_all_off');
  }
  if (privateOn && groupOn && channelOn) {
    return str('ds_auto_download_all_on');
  }
  if (!privateOn && !groupOn && !channelOn) {
    return str('ds_auto_download_all_off');
  }
  const scopes: string[] = [];
  if (privateOn) {
    scopes.push(str('ds_auto_download_private'));
  }
  if (groupOn) {
    scopes.push(str('ds_auto_download_group'));
  }
  if (channelOn) {
    scopes.push(str('ds_auto_download_channel'));
  }
  return scopes.join(str('list_separator'));
}

export function videoAutoDownloadSubtitle(
  masterOn: boolean,
  privateOn: boolean,
  groupOn: boolean,
  channelOn: boolean,
  maxMb: number
): string {
  if (!masterOn || (!privateOn && !groupOn && !channelOn)) {
    return str('ds_auto_download_all_off');
  }
  const limitText: string = formatVideoLimitMb(normalizeAutoDownloadVideoMaxMb(maxMb));
  if (privateOn && groupOn && channelOn) {
    return str('ds_auto_download_video_all_max', limitText);
  }
  const scopes: string[] = [];
  if (privateOn) {
    scopes.push(str('ds_auto_download_private'));
  }
  if (groupOn) {
    scopes.push(str('ds_auto_download_group'));
  }
  if (channelOn) {
    scopes.push(str('ds_auto_download_channel'));
  }
  return str('ds_auto_download_video_scopes_max', scopes.join(str('list_separator')), limitText);
}

export function fileAutoDownloadSubtitle(
  masterOn: boolean,
  privateOn: boolean,
  groupOn: boolean,
  channelOn: boolean,
  maxMb: number
): string {
  if (!masterOn || (!privateOn && !groupOn && !channelOn)) {
    return str('ds_auto_download_all_off');
  }
  const limitText: string = formatVideoLimitMb(normalizeAutoDownloadVideoMaxMb(maxMb));
  if (privateOn && groupOn && channelOn) {
    return str('ds_auto_download_video_all_max', limitText);
  }
  const scopes: string[] = [];
  if (privateOn) {
    scopes.push(str('ds_auto_download_private'));
  }
  if (groupOn) {
    scopes.push(str('ds_auto_download_group'));
  }
  if (channelOn) {
    scopes.push(str('ds_auto_download_channel'));
  }
  return str('ds_auto_download_file_scopes_max', limitText, scopes.join(str('list_separator')));
}

export function isAutoDownloadAtDefault(
  masterOn: boolean,
  photoPrivate: boolean,
  photoGroup: boolean,
  photoChannel: boolean,
  videoPrivate: boolean,
  videoGroup: boolean,
  videoChannel: boolean,
  videoMaxMb: number,
  videoPreloadLarge: boolean,
  videoPreloadMb: number,
  filePrivate: boolean,
  fileGroup: boolean,
  fileChannel: boolean,
  fileMaxMb: number
): boolean {
  return masterOn === true &&
    photoPrivate === true &&
    photoGroup === true &&
    photoChannel === true &&
    videoPrivate === true &&
    videoGroup === true &&
    videoChannel === true &&
    normalizeAutoDownloadVideoMaxMb(videoMaxMb) === AUTODOWNLOAD_VIDEO_MAX_MB_DEFAULT &&
    videoPreloadLarge === true &&
    normalizeAutoDownloadVideoPreloadMb(videoPreloadMb) === AUTODOWNLOAD_VIDEO_PRELOAD_MB_DEFAULT &&
    filePrivate === false &&
    fileGroup === false &&
    fileChannel === false &&
    normalizeAutoDownloadVideoMaxMb(fileMaxMb) === AUTODOWNLOAD_FILE_MAX_MB_DEFAULT;
}
