import { HdsSubDestination } from '../common/HdsSubDestination';
import { BLUR_MAX_VP, EDGE_OVERLAY_VP, topEdgeBlurStops } from '../../util/scrollEdgeBlur';
import {
  applyAutoDownloadSubpageToggle,
  KEY_AUTODOWNLOAD_MASTER,
  KEY_AUTODOWNLOAD_PHOTO_PRIVATE,
  KEY_AUTODOWNLOAD_PHOTO_GROUP,
  KEY_AUTODOWNLOAD_PHOTO_CHANNEL
} from '../../store/AppSettings';
import {
  COLOR_DIVIDER, COLOR_PAGE_BG, COLOR_PRIMARY, COLOR_SURFACE, COLOR_TEXT_PRIMARY
} from '../../util/theme';
import { str } from '../../util/strings';
import { LANGUAGE_EPOCH } from '../../util/appLanguage';

const CARD_RADIUS: number = 14;

@Builder
export function AutoDownloadPhotoPageBuilder(): void {
  AutoDownloadPhotoPage();
}

@Component
export struct AutoDownloadPhotoPage {
  private pageScroller: Scroller = new Scroller();
  @State private blurViewH: number = 0;
  @StorageProp(LANGUAGE_EPOCH) langEpoch: number = 0;
  @StorageProp('bottomSafeHeight') bottomSafe: number = 0;
  @StorageProp(KEY_AUTODOWNLOAD_MASTER) autoDownloadMaster: boolean = true;
  @StorageProp(KEY_AUTODOWNLOAD_PHOTO_PRIVATE) photoPrivate: boolean = true;
  @StorageProp(KEY_AUTODOWNLOAD_PHOTO_GROUP) photoGroup: boolean = true;
  @StorageProp(KEY_AUTODOWNLOAD_PHOTO_CHANNEL) photoChannel: boolean = true;

  private onScopeToggle(scope: string, next: boolean): void {
    const key: string = scope === 'channel'
      ? KEY_AUTODOWNLOAD_PHOTO_CHANNEL
      : (scope === 'group' ? KEY_AUTODOWNLOAD_PHOTO_GROUP : KEY_AUTODOWNLOAD_PHOTO_PRIVATE);
    applyAutoDownloadSubpageToggle(key, next);
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

  build() {
    Column() {
      HdsSubDestination({
        title: $r('app.string.ds_auto_download_photos'),
        pageBackground: COLOR_PAGE_BG,
        scroller: this.pageScroller
      }) {
        Scroll(this.pageScroller) {
          Column({ space: 12 }) {
            Column() {
              this.scopeRow(
                str('ds_auto_download_private'),
                this.autoDownloadMaster && this.photoPrivate,
                'private'
              );
              Divider().strokeWidth(0.5).color(COLOR_DIVIDER).margin({ left: 14 });
              this.scopeRow(
                str('ds_auto_download_group'),
                this.autoDownloadMaster && this.photoGroup,
                'group'
              );
              Divider().strokeWidth(0.5).color(COLOR_DIVIDER).margin({ left: 14 });
              this.scopeRow(
                str('ds_auto_download_channel'),
                this.autoDownloadMaster && this.photoChannel,
                'channel'
              );
            }
            .width('100%')
            .backgroundColor(COLOR_SURFACE)
            .borderRadius(CARD_RADIUS)
            .clip(true);
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
