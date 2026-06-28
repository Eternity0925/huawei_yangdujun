import { router } from '@kit.ArkUI';
import { AndroidColor, AndroidDimen } from './AndroidStyle';
import { AppRoutes } from './AppRoutes';

@Component
export struct AndroidBottomNav {
  active: string = 'greenhouse';

  @Builder
  NavCell(icon: string, label: string, route: string, key: string) {
    Column({ space: 2 }) {
      Text(icon)
        .width(44)
        .height(44)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AndroidColor.GREEN_LABEL)
        .textAlign(TextAlign.Center)
        .backgroundColor(AndroidColor.NAV_ICON_BG)
        .borderRadius(22)
      Text(label)
        .fontSize(14)
        .fontColor(this.active === key ? AndroidColor.GREEN_DARK : AndroidColor.TEXT_SECONDARY)
        .fontWeight(this.active === key ? FontWeight.Bold : FontWeight.Regular)
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (this.active !== key) {
        router.replaceUrl({ url: route });
      }
    })
  }

  build() {
    Row() {
      this.NavCell('棚', '大棚', AppRoutes.HOME, 'greenhouse')
      this.NavCell('管', '管理', AppRoutes.MANAGE, 'manage')
      this.NavCell('我', '我的', AppRoutes.MINE, 'mine')
    }
    .width('100%')
    .height(AndroidDimen.NAV_HEIGHT)
    .padding(AndroidDimen.PAD_5)
    .backgroundColor(AndroidColor.CARD_BG)
    .shadow({ radius: 5, color: '#33000000', offsetX: 0, offsetY: -1 })
  }
}

@Component
export struct AndroidTopBar {
  title: string = '';

  build() {
    Row() {
      Text(this.title)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .height(70)
    .margin(10)
    .backgroundColor(AndroidColor.GREEN_HEADER)
    .borderRadius(AndroidDimen.HEADER_RADIUS)
    .shadow({ radius: 6, color: '#33000000', offsetX: 0, offsetY: 2 })
  }
}
