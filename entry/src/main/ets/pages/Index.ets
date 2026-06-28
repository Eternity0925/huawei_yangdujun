import { router } from '@kit.ArkUI';
import { AndroidColor, AndroidDimen } from '../common/AndroidStyle';
import { AppRoutes } from '../common/AppRoutes';
import { AppState } from '../storage/AppState';

@Entry
@Component
struct Index {
  aboutToAppear(): void {
    if (AppState.isLoggedIn()) {
      router.replaceUrl({ url: AppRoutes.HOME });
    }
  }

  build() {
    Stack() {
      Image($r('app.media.image_9'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .opacity(0.22)

      Circle()
        .width(400)
        .height(400)
        .fill(AndroidColor.GREEN_SOFT)
        .opacity(0.2)
        .position({ x: -8, y: -150 })

      Column() {
        Blank()

        Column() {
          Text('羊肚菌智慧大棚')
            .width('100%')
            .textAlign(TextAlign.Center)
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(AndroidColor.GREEN_TEXT)
            .margin({ bottom: 16 })

          Stack() {
            Image($r('app.media.image_14'))
              .width(180)
              .height(180)
              .objectFit(ImageFit.Contain)
          }
          .width(180)
          .height(180)
          .borderRadius(90)
          .shadow({ radius: 15, color: '#33000000', offsetX: 0, offsetY: 4 })
          .margin({ bottom: 16 })

          Text('创新惠农       科技助农')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(AndroidColor.GREEN_MUTED)
            .textAlign(TextAlign.Center)
            .margin({ bottom: 40 })

          Button('登录')
            .width('100%')
            .height(AndroidDimen.BUTTON_HEIGHT)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .backgroundColor(AndroidColor.GREEN_DARK)
            .borderRadius(25)
            .onClick(() => router.pushUrl({ url: AppRoutes.LOGIN }))

          Button('注册')
            .width('100%')
            .height(AndroidDimen.BUTTON_HEIGHT)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .backgroundColor(AndroidColor.GREEN_SOFT)
            .borderRadius(25)
            .margin({ top: AndroidDimen.MARGIN_15 })
            .onClick(() => router.pushUrl({ url: AppRoutes.REGISTER }))
        }
        .width('100%')
        .padding({ left: 16, right: 16 })

        Blank()
      }
      .width('100%')
      .height('100%')

      Circle()
        .width(25)
        .height(25)
        .fill(AndroidColor.GREEN_DARK)
        .opacity(0.5)
        .position({ x: 330, y: 760 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AndroidColor.PAGE_BG)
  }
}
