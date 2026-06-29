import { router } from '@kit.ArkUI';
import { AndroidColor, AndroidDimen } from './AndroidStyle';
import { AppRoutes } from './AppRoutes';

@Component
export struct AndroidBottomNav {
  active: string = 'greenhouse';

  @Builder
  NavCell(icon: string, label: string, route: string, key: string) {
    Column({ space: 3 }) {
      Text(icon)
        .width(36)
        .height(36)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.active === key ? Color.White : AndroidColor.GREEN_LABEL)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.active === key ? AndroidColor.GREEN_DARK : AndroidColor.NAV_ICON_BG)
        .borderRadius(18)
      Text(label)
        .fontSize(13)
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
    .padding({ left: 6, right: 6, top: 4, bottom: 4 })
    .backgroundColor(AndroidColor.CARD_BG)
    .shadow({ radius: 5, color: '#22000000', offsetX: 0, offsetY: -1 })
  }
}

@Component
export struct AndroidTopBar {
  title: string = '';

  build() {
    Row() {
      Text(this.title)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .height(60)
    .margin({ left: 10, right: 10, top: 8, bottom: 8 })
    .backgroundColor(AndroidColor.GREEN_HEADER)
    .borderRadius(14)
    .shadow({ radius: 5, color: '#22000000', offsetX: 0, offsetY: 2 })
  }
}

@Component
export struct AndroidBackTopBar {
  title: string = '';

  build() {
    Row() {
      Text('<')
        .width(42)
        .height(42)
        .fontSize(24)
        .fontColor(Color.White)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .backgroundColor('#6F9F62')
        .borderRadius(21)
        .onClick(() => router.back())
      Text(this.title)
        .layoutWeight(1)
        .fontSize(21)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .margin({ right: 42 })
    }
    .width('100%')
    .height(62)
    .padding({ left: 14, right: 14 })
    .backgroundColor(AndroidColor.GREEN_HEADER)
    .borderRadius(14)
    .shadow({ radius: 5, color: '#22000000', offsetX: 0, offsetY: 2 })
  }
}
