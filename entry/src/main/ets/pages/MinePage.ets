import { router } from '@kit.ArkUI';
import { AndroidBottomNav } from '../common/AndroidWidgets';
import { AndroidColor } from '../common/AndroidStyle';
import { AppRoutes } from '../common/AppRoutes';
import { AppService } from '../services/AppService';
import { AppState } from '../storage/AppState';

interface MineEntry {
  icon: string;
  title: string;
  bg: string;
  color: string;
  route: string;
}

@Entry
@Component
struct MinePage {
  private entries: MineEntry[] = [
    { icon: '棚', title: '我的大棚', bg: '#E8F5E9', color: AndroidColor.GREEN_TEXT, route: AppRoutes.GREENHOUSE_LIST },
    { icon: '馈', title: '问题反馈', bg: '#FFF3E0', color: AndroidColor.GREEN_TEXT, route: AppRoutes.FEEDBACK },
    { icon: 'AI', title: 'AI助手', bg: '#E3F2FD', color: AndroidColor.GREEN_TEXT, route: AppRoutes.AI },
    { icon: '设', title: '设置', bg: '#F3E5F5', color: AndroidColor.GREEN_TEXT, route: AppRoutes.SETTINGS }
  ];

  private nickname(): string {
    const user = AppService.getCurrentUser();
    return user ? user.nickname : '未登录';
  }

  @Builder
  RowEntry(item: MineEntry) {
    Row() {
      Text(item.icon)
        .width(42)
        .height(42)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(item.color)
        .textAlign(TextAlign.Center)
        .backgroundColor(item.bg)
        .borderRadius(10)
      Text(item.title)
        .layoutWeight(1)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(item.color)
        .margin({ left: 12 })
      Text('>')
        .fontSize(20)
        .fontColor('#A7A7A7')
        .opacity(0.45)
    }
    .width('100%')
    .height(66)
    .padding({ left: 14, right: 14 })
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 2, color: '#18000000', offsetX: 0, offsetY: 1 })
    .margin({ left: 16, right: 16, top: 10 })
    .onClick(() => router.pushUrl({ url: item.route }))
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          Row() {
            Image($r('app.media.image_1'))
              .width(88)
              .height(88)
              .objectFit(ImageFit.Cover)
              .borderRadius(44)
              .padding(2)
              .backgroundColor(Color.White)
              .shadow({ radius: 4, color: '#22000000', offsetX: 0, offsetY: 2 })
              .onClick(() => router.pushUrl({ url: AppRoutes.EDIT_PROFILE }))

            Column({ space: 6 }) {
              Text(this.nickname())
                .fontSize(26)
                .fontWeight(FontWeight.Bold)
                .fontColor(AndroidColor.GREEN_TEXT)
              Text('点击头像编辑资料')
                .fontSize(13)
                .fontColor(AndroidColor.TEXT_SECONDARY)
            }
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 22 })
            .onClick(() => router.pushUrl({ url: AppRoutes.EDIT_PROFILE }))
          }
          .width('100%')
          .height(150)
          .padding({ left: 28, right: 20, top: 12 })
          .alignItems(VerticalAlign.Center)

          ForEach(this.entries, (item: MineEntry) => {
            this.RowEntry(item)
          }, (item: MineEntry) => item.title)

          Row() {
            Text('退')
              .width(42)
              .height(42)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#D32F2F')
              .textAlign(TextAlign.Center)
              .backgroundColor('#FFEBEE')
              .borderRadius(10)
            Text('退出登录')
              .layoutWeight(1)
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor('#D32F2F')
              .margin({ left: 12 })
            Text('>')
              .fontSize(20)
              .fontColor('#A7A7A7')
              .opacity(0.45)
          }
          .width('100%')
          .height(66)
          .padding({ left: 14, right: 14 })
          .backgroundColor(Color.White)
          .borderRadius(12)
          .shadow({ radius: 2, color: '#18000000', offsetX: 0, offsetY: 1 })
          .margin({ left: 16, right: 16, top: 10, bottom: 12 })
          .onClick(() => {
            AppState.logout();
            router.replaceUrl({ url: AppRoutes.INDEX });
          })
        }
        .padding({ bottom: 12 })
      }
      .layoutWeight(1)

      AndroidBottomNav({ active: 'mine' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AndroidColor.INPUT_BG)
  }
}
