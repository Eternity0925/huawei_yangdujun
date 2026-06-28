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
    { icon: '天', title: '智能天气', bg: '#E0F7FA', color: AndroidColor.GREEN_TEXT, route: AppRoutes.WEATHER },
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
        .width(48)
        .height(48)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(item.color)
        .textAlign(TextAlign.Center)
        .backgroundColor(item.bg)
        .borderRadius(8)
      Text(item.title)
        .layoutWeight(1)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(item.color)
        .margin({ left: 12 })
      Text('>')
        .fontSize(24)
        .fontColor('#999999')
        .opacity(0.6)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })
    .margin({ left: 16, right: 16, top: 12 })
    .onClick(() => router.pushUrl({ url: item.route }))
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          Row() {
            Image($r('app.media.image_1'))
              .width(100)
              .height(100)
              .objectFit(ImageFit.Cover)
              .borderRadius(50)
              .padding(2)
              .backgroundColor(Color.White)
              .shadow({ radius: 4, color: '#22000000', offsetX: 0, offsetY: 2 })
              .onClick(() => router.pushUrl({ url: AppRoutes.EDIT_PROFILE }))

            Text(this.nickname())
              .fontSize(30)
              .fontWeight(FontWeight.Bold)
              .fontColor(AndroidColor.GREEN_TEXT)
              .margin({ left: 52 })
              .onClick(() => router.pushUrl({ url: AppRoutes.EDIT_PROFILE }))
          }
          .width('100%')
          .height(172)
          .padding({ left: 48, top: 72 })
          .alignItems(VerticalAlign.Center)

          Blank()
            .height(68)

          ForEach(this.entries, (item: MineEntry) => {
            this.RowEntry(item)
          }, (item: MineEntry) => item.title)

          Row() {
            Text('退')
              .width(48)
              .height(48)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#D32F2F')
              .textAlign(TextAlign.Center)
              .backgroundColor('#FFEBEE')
              .borderRadius(8)
            Text('退出登录')
              .layoutWeight(1)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#D32F2F')
              .margin({ left: 12 })
            Text('>')
              .fontSize(24)
              .fontColor('#999999')
              .opacity(0.6)
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)
          .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })
          .margin({ left: 16, right: 16, top: 12, bottom: 12 })
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
