import { HdsSubDestination } from '../common/HdsSubDestination';
import {
  applyAutoDownloadSubpageToggle,
  setNumber,
  KEY_AUTODOWNLOAD_MASTER,
  KEY_AUTODOWNLOAD_VIDEO_PRIVATE,
  KEY_AUTODOWNLOAD_VIDEO_GROUP,
  KEY_AUTODOWNLOAD_VIDEO_CHANNEL,
  KEY_AUTODOWNLOAD_VIDEO_MAX_MB,
  KEY_AUTODOWNLOAD_VIDEO_PRELOAD_LARGE,
  KEY_AUTODOWNLOAD_VIDEO_PRELOAD_MB
} from '../../store/AppSettings';
import {
  AUTODOWNLOAD_VIDEO_MAX_MB_DEFAULT,
  AUTODOWNLOAD_VIDEO_MAX_MB_STEPS,
  AUTODOWNLOAD_VIDEO_PRELOAD_MB_DEFAULT,
  AUTODOWNLOAD_VIDEO_PRELOAD_MB_OPTIONS,
  autoDownloadVideoMaxMbStepIndex,
  formatVideoLimitMb,
  normalizeAutoDownloadVideoMaxMb,
  normalizeAutoDownloadVideoPreloadMb
} from '../../util/autoDownloadPolicy';
import {
  COLOR_DIVIDER,
  COLOR_PAGE_BG,
  COLOR_PRIMARY,
  COLOR_SURFACE,
  COLOR_TEXT_PRIMARY,
  COLOR_TEXT_SECONDARY,
  accentSoft
} from '../../util/theme';
import { str } from '../../util/strings';
import { LANGUAGE_EPOCH } from '../../util/appLanguage';

const CARD_RADIUS: number = 14;

@Builder
export function AutoDownloadVideoPageBuilder(): void {
  AutoDownloadVideoPage();
}

@Component
export struct AutoDownloadVideoPage {
  private pageScroller: Scroller = new Scroller();
  @StorageProp(LANGUAGE_EPOCH) langEpoch: number = 0;
  @StorageProp('bottomSafeHeight') bottomSafe: number = 0;
  @StorageProp(KEY_AUTODOWNLOAD_MASTER) autoDownloadMaster: boolean = true;
  @StorageProp(KEY_AUTODOWNLOAD_VIDEO_PRIVATE) videoPrivate: boolean = true;
  @StorageProp(KEY_AUTODOWNLOAD_VIDEO_GROUP) videoGroup: boolean = true;
  @StorageProp(KEY_AUTODOWNLOAD_VIDEO_CHANNEL) videoChannel: boolean = true;
  @StorageProp(KEY_AUTODOWNLOAD_VIDEO_MAX_MB) videoMaxMb: number = AUTODOWNLOAD_VIDEO_MAX_MB_DEFAULT;
  @StorageProp(KEY_AUTODOWNLOAD_VIDEO_PRELOAD_LARGE) preloadLarge: boolean = true;
  @StorageProp(KEY_AUTODOWNLOAD_VIDEO_PRELOAD_MB) preloadMb: number = AUTODOWNLOAD_VIDEO_PRELOAD_MB_DEFAULT;

  private onScopeToggle(scope: string, next: boolean): void {
    const key: string = scope === 'channel'
      ? KEY_AUTODOWNLOAD_VIDEO_CHANNEL
      : (scope === 'group' ? KEY_AUTODOWNLOAD_VIDEO_GROUP : KEY_AUTODOWNLOAD_VIDEO_PRIVATE);
    applyAutoDownloadSubpageToggle(key, next);
  }

  private onPreloadLargeToggle(next: boolean): void {
    applyAutoDownloadSubpageToggle(KEY_AUTODOWNLOAD_VIDEO_PRELOAD_LARGE, next);
  }

  private onSliderChange(stepValue: number): void {
    const idx: number = Math.max(
      0,
      Math.min(AUTODOWNLOAD_VIDEO_MAX_MB_STEPS.length - 1, Math.round(stepValue))
    );
    const mb: number = AUTODOWNLOAD_VIDEO_MAX_MB_STEPS[idx];
    if (mb !== undefined && mb !== normalizeAutoDownloadVideoMaxMb(this.videoMaxMb)) {
      setNumber(KEY_AUTODOWNLOAD_VIDEO_MAX_MB, mb);
    }
  }

  private currentLimitLabel(): string {
    return formatVideoLimitMb(normalizeAutoDownloadVideoMaxMb(this.videoMaxMb));
  }

  private currentPreloadMb(): number {
    return normalizeAutoDownloadVideoPreloadMb(this.preloadMb);
  }

  @Builder
  scopeRow(title: string, value: boolean, scope: string) {
    Row({ space: 10 }) {
      Text(title)
        .fontSize(15)
        .fontColor(COLOR_TEXT_PRIMARY)
        .layoutWeight(1);
      Toggle({ type: ToggleType.Switch, isOn: value })
        .selectedColor(COLOR_PRIMARY)
        .onChange((next: boolean): void => this.onScopeToggle(scope, next));
    }
    .width('100%')
    .height(48)
    .padding({ left: 14, right: 14 });
  }

  @Builder
  preloadSizeRow() {
    Column({ space: 8 }) {
      Text(str('ds_video_preload_size'))
        .fontSize(14)
        .fontColor(COLOR_TEXT_SECONDARY)
        .width('100%');
      Row({ space: 6 }) {
        ForEach(AUTODOWNLOAD_VIDEO_PRELOAD_MB_OPTIONS, (mb: number): void => {
          Text(`${mb} MB`)
            .fontSize(13)
            .fontColor(this.currentPreloadMb() === mb ? COLOR_PRIMARY : COLOR_TEXT_PRIMARY)
            .fontWeight(this.currentPreloadMb() === mb ? FontWeight.Medium : FontWeight.Normal)
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
            .height(32)
            .borderRadius(16)
            .backgroundColor(this.currentPreloadMb() === mb ? accentSoft() : $r('app.color.reaction_chip'))
            .onClick((): void => {
              setNumber(KEY_AUTODOWNLOAD_VIDEO_PRELOAD_MB, mb);
            });
        }, (mb: number): string => `${mb}`);
      }
      .width('100%');
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 10, bottom: 12 });
  }

  @Builder
  sizeLimitCard() {
    Column() {
      Column({ space: 4 }) {
        Text(this.currentLimitLabel())
          .fontSize(14)
          .fontColor(COLOR_TEXT_SECONDARY)
          .width('100%')
          .textAlign(TextAlign.Center);
        Slider({
          value: autoDownloadVideoMaxMbStepIndex(this.videoMaxMb),
          min: 0,
          max: AUTODOWNLOAD_VIDEO_MAX_MB_STEPS.length - 1,
          step: 1,
          style: SliderStyle.OutSet
        })
          .width('100%')
          .showSteps(true)
          .trackColor(COLOR_DIVIDER)
          .selectedColor(COLOR_PRIMARY)
          .blockColor(COLOR_PRIMARY)
          .onChange((value: number): void => this.onSliderChange(value));
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 12, bottom: 6 });

      Divider().strokeWidth(0.5).color(COLOR_DIVIDER).margin({ left: 14 });

      Row({ space: 10 }) {
        Text(str('ds_video_preload_large'))
          .fontSize(15)
          .fontColor(COLOR_TEXT_PRIMARY)
          .layoutWeight(1);
        Toggle({
          type: ToggleType.Switch,
          isOn: this.autoDownloadMaster && this.preloadLarge
        })
          .selectedColor(COLOR_PRIMARY)
          .onChange((next: boolean): void => this.onPreloadLargeToggle(next));
      }
      .width('100%')
      .height(48)
      .padding({ left: 14, right: 14 });

      if (this.autoDownloadMaster && this.preloadLarge) {
        Divider().strokeWidth(0.5).color(COLOR_DIVIDER).margin({ left: 14 });
        this.preloadSizeRow();
      }
    }
    .width('100%')
    .backgroundColor(COLOR_SURFACE)
    .borderRadius(CARD_RADIUS)
    .clip(true);
  }

  build() {
    Column() {
      HdsSubDestination({
        title: $r('app.string.ds_auto_download_videos'),
        pageBackground: COLOR_PAGE_BG,
        scroller: this.pageScroller
      }) {
        Scroll(this.pageScroller) {
          Column({ space: 12 }) {
            Column() {
              this.scopeRow(
                str('ds_auto_download_private'),
                this.autoDownloadMaster && this.videoPrivate,
                'private'
              );
              Divider().strokeWidth(0.5).color(COLOR_DIVIDER).margin({ left: 14 });
              this.scopeRow(
                str('ds_auto_download_group'),
                this.autoDownloadMaster && this.videoGroup,
                'group'
              );
              Divider().strokeWidth(0.5).color(COLOR_DIVIDER).margin({ left: 14 });
              this.scopeRow(
                str('ds_auto_download_channel'),
                this.autoDownloadMaster && this.videoChannel,
                'channel'
              );
            }
            .width('100%')
            .backgroundColor(COLOR_SURFACE)
            .borderRadius(CARD_RADIUS)
            .clip(true);

            Text($r('app.string.ds_video_size_limit'))
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(COLOR_PRIMARY)
              .width('100%')
              .padding({ left: 4, top: 4 });

            this.sizeLimitCard();

            Text(str(
              'ds_video_preload_large_hint',
              this.currentLimitLabel(),
              `${this.currentPreloadMb()} MB`
            ))
              .fontSize(12)
              .fontColor(COLOR_TEXT_SECONDARY)
              .width('100%')
              .padding({ left: 14, right: 14 });
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 6, bottom: this.bottomSafe + 24 });
        }
        .align(Alignment.Top)
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
        .clip(false);
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLOR_PAGE_BG)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
  }
}
