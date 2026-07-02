import { promptAction, router } from '@kit.ArkUI';
import { AndroidColor } from '../common/AndroidStyle';
import { AppRoutes } from '../common/AppRoutes';
import { AppService } from '../services/AppService';

@Entry
@Component
struct LoginPage {
  @State phone: string = 'farmer001';
  @State password: string = '';
  @State agreed: boolean = true;

  private async submit(): Promise<void> {
    if (!this.agreed) {
      promptAction.showToast({ message: '请先同意用户协议与隐私政策' });
      return;
    }

    const ok = await AppService.login(this.phone, this.password);
    if (!ok) {
      promptAction.showToast({ message: '农户账号或密码错误' });
      return;
    }
    router.replaceUrl({ url: AppRoutes.HOME });
  }

  @Builder
  InputRow(label: string, placeholder: string, isPassword: boolean) {
    Row() {
      Text(label)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(AndroidColor.GREEN_LABEL)
        .margin({ right: 14 })

      TextInput({ placeholder, text: isPassword ? this.password : this.phone })
        .layoutWeight(1)
        .height(48)
        .fontSize(15)
        .fontColor(AndroidColor.GREEN_LABEL)
        .placeholderColor(AndroidColor.GREEN_HINT)
        .backgroundColor(Color.Transparent)
        .type(isPassword ? InputType.Password : InputType.Normal)
        .onChange((value: string) => {
          if (isPassword) {
            this.password = value;
          } else {
            this.phone = value;
          }
        })
    }
    .width('100%')
    .height(54)
    .padding({ left: 18, right: 18 })
    .backgroundColor(AndroidColor.INPUT_BG)
  }

  build() {
    Stack() {
      Image($r('app.media.image_9'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .opacity(0.22)

      Circle()
        .width(350)
        .height(350)
        .fill(AndroidColor.GREEN_SOFT)
        .opacity(0.15)
        .position({ x: 220, y: -50 })

      Scroll() {
        Column() {
          Text('羊肚菌智慧大棚')
            .width('100%')
            .textAlign(TextAlign.Center)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(AndroidColor.GREEN_TEXT)
            .margin({ bottom: 22 })

          Image($r('app.media.image_14'))
            .width(112)
            .height(112)
            .objectFit(ImageFit.Contain)
            .borderRadius(22)
            .shadow({ radius: 8, color: '#22000000', offsetX: 0, offsetY: 3 })

          Column() {
              this.InputRow('账号', '请输入农户账号', false)

            Column() {
              this.InputRow('密码', '请输入密码', true)
            }
            .margin({ top: 12 })

            Row() {
              Button('忘记密码')
                .type(ButtonType.Normal)
                .fontSize(14)
                .fontColor('#5A7153')
                .backgroundColor('#DFEFE0')
                .padding({ left: 10, right: 10, top: 7, bottom: 7 })
                .onClick(() => router.pushUrl({ url: AppRoutes.NEW_PASSWORD }))

              Divider()
                .vertical(true)
                .height(12)
                .color(AndroidColor.PAGE_BG)
                .margin({ left: 14, right: 14 })

              Button('注册账号')
                .type(ButtonType.Normal)
                .fontSize(14)
                .fontColor('#5A7153')
                .backgroundColor('#DFEFE0')
                .padding({ left: 10, right: 10, top: 7, bottom: 7 })
                .onClick(() => router.pushUrl({ url: AppRoutes.REGISTER }))
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .margin({ top: 14 })

            Row() {
              Checkbox()
                .select(this.agreed)
                .selectedColor(AndroidColor.GREEN_DARK)
                .onChange((value: boolean) => this.agreed = value)
              Text('我已阅读并同意《用户协议》《隐私政策》')
                .fontSize(12)
                .fontColor(AndroidColor.GREEN_HINT)
                .margin({ left: 6 })
            }
            .justifyContent(FlexAlign.Center)
            .width('100%')
            .margin({ top: 18 })

            Button('登录')
              .width('100%')
              .height(54)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .backgroundColor(AndroidColor.GREEN_DARK)
              .borderRadius(27)
              .margin({ top: 20 })
              .onClick(() => this.submit())
          }
          .width('100%')
          .padding({ left: 24, right: 24, top: 28, bottom: 28 })
          .backgroundColor(Color.White)
          .borderRadius(14)
          .shadow({ radius: 5, color: '#22000000', offsetX: 0, offsetY: 2 })
          .margin({ left: 24, right: 24, top: 28 })
        }
        .width('100%')
        .padding({ top: 34, bottom: 30 })
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AndroidColor.PAGE_BG)
  }
}
