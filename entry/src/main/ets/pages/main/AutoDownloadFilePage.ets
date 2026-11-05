import { HdsSubDestination } from '../common/HdsSubDestination';
import { BLUR_MAX_VP, EDGE_OVERLAY_VP, topEdgeBlurStops } from '../../util/scrollEdgeBlur';
import {
  applyAutoDownloadSubpageToggle,
  setNumber,
  KEY_AUTODOWNLOAD_MASTER,
  KEY_AUTODOWNLOAD_FILE_PRIVATE,
  KEY_AUTODOWNLOAD_FILE_GROUP,
  KEY_AUTODOWNLOAD_FILE_CHANNEL,
  KEY_AUTODOWNLOAD_FILE_MAX_MB
} from '../../store/AppSettings';
import {
  AUTODOWNLOAD_FILE_MAX_MB_DEFAULT,
  AUTODOWNLOAD_VIDEO_MAX_MB_STEPS,
  autoDownloadVideoMaxMbStepIndex,
  formatVideoLimitMb,
  normalizeAutoDownloadVideoMaxMb
} from '../../util/autoDownloadPolicy';
import {
  COLOR_DIVIDER,
  COLOR_PAGE_BG,
  COLOR_PRIMARY,
  COLOR_SURFACE,
  COLOR_TEXT_PRIMARY,
  COLOR_TEXT_SECONDARY
} from '../../util/theme';
import { str } from '../../util/strings';
import { LANGUAGE_EPOCH } from '../../util/appLanguage';

const CARD_RADIUS: number = 14;

@Builder
export function AutoDownloadFilePageBuilder(): void {
  AutoDownloadFilePage();
}

@Component
export struct AutoDownloadFilePage {
  private pageScroller: Scroller = new Scroller();
  @State private blurViewH: number = 0;
  @StorageProp(LANGUAGE_EPOCH) langEpoch: number = 0;
  @StorageProp('bottomSafeHeight') bottomSafe: number = 0;
  @StorageProp(KEY_AUTODOWNLOAD_MASTER) autoDownloadMaster: boolean = true;
  @StorageProp(KEY_AUTODOWNLOAD_FILE_PRIVATE) filePrivate: boolean = false;
  @StorageProp(KEY_AUTODOWNLOAD_FILE_GROUP) fileGroup: boolean = false;
  @StorageProp(KEY_AUTODOWNLOAD_FILE_CHANNEL) fileChannel: boolean = false;
  @StorageProp(KEY_AUTODOWNLOAD_FILE_MAX_MB) fileMaxMb: number = AUTODOWNLOAD_FILE_MAX_MB_DEFAULT;

  private onScopeToggle(scope: string, next: boolean): void {
    const key: string = scope === 'channel'
      ? KEY_AUTODOWNLOAD_FILE_CHANNEL
      : (scope === 'group' ? KEY_AUTODOWNLOAD_FILE_GROUP : KEY_AUTODOWNLOAD_FILE_PRIVATE);
    applyAutoDownloadSubpageToggle(key, next);
  }

  private onSliderChange(stepValue: number): void {
    const idx: number = Math.max(
      0,
      Math.min(AUTODOWNLOAD_VIDEO_MAX_MB_STEPS.length - 1, Math.round(stepValue))
    );
    const mb: number = AUTODOWNLOAD_VIDEO_MAX_MB_STEPS[idx];
    if (mb !== undefined && mb !== normalizeAutoDownloadVideoMaxMb(this.fileMaxMb)) {
      setNumber(KEY_AUTODOWNLOAD_FILE_MAX_MB, mb);
    }
  }

  private currentLimitLabel(): string {
    return formatVideoLimitMb(normalizeAutoDownloadVideoMaxMb(this.fileMaxMb));
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
  sizeLimitCard() {
    Column({ space: 4 }) {
      Text(this.currentLimitLabel())
        .fontSize(14)
        .fontColor(COLOR_TEXT_SECONDARY)
        .width('100%')
        .textAlign(TextAlign.Center);
      Slider({
        value: autoDownloadVideoMaxMbStepIndex(this.fileMaxMb),
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
    .padding({ left: 14, right: 14, top: 14, bottom: 10 })
    .backgroundColor(COLOR_SURFACE)
    .borderRadius(CARD_RADIUS)
    .clip(true);
  }

  build() {
    Column() {
      HdsSubDestination({
        title: str('ds_auto_download_files'),
        pageBackground: COLOR_PAGE_BG,
        scroller: this.pageScroller
      }) {
        Scroll(this.pageScroller) {
          Column({ space: 10 }) {
            Column() {
              this.scopeRow(
                str('ds_auto_download_private'),
                this.autoDownloadMaster && this.filePrivate,
                'private'
              );
              Divider().strokeWidth(0.5).color(COLOR_DIVIDER).margin({ left: 14 });
              this.scopeRow(
                str('ds_auto_download_group'),
                this.autoDownloadMaster && this.fileGroup,
                'group'
              );
              Divider().strokeWidth(0.5).color(COLOR_DIVIDER).margin({ left: 14 });
              this.scopeRow(
                str('ds_auto_download_channel'),
                this.autoDownloadMaster && this.fileChannel,
                'channel'
              );
            }
            .width('100%')
            .backgroundColor(COLOR_SURFACE)
            .borderRadius(CARD_RADIUS)
            .clip(true);

            Text(str('ds_video_size_limit'))
              .fontSize(13)
              .fontColor(COLOR_TEXT_SECONDARY)
              .width('100%')
              .padding({ left: 14, top: 6 });

            this.sizeLimitCard();
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: EDGE_OVERLAY_VP, bottom: this.bottomSafe + 24 });
        }
        .align(Alignment.Top)
        .layoutWeight(1)
        .width('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
        .clip(false)
        .linearGradientBlur(BLUR_MAX_VP, {
          fractionStops: topEdgeBlurStops(this.blurViewH),
          direction: GradientDirection.Bottom
        })
        .onAreaChange((_old: Area, area: Area): void => {
          const h: number = Number(area.height);
          if (h > 0 && Math.abs(h - this.blurViewH) > 0.5) {
            this.blurViewH = h;
          }
        });
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLOR_PAGE_BG)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]);
  }
}
