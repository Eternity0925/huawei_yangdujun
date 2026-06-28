import { promptAction, router } from '@kit.ArkUI';
import { AndroidColor } from '../common/AndroidStyle';
import { AppRoutes } from '../common/AppRoutes';
import { AppService } from '../services/AppService';

@Entry
@Component
struct LoginPage {
  @State phone: string = '';
  @State password: string = '';
  @State agreed: boolean = false;

  private async submit(): Promise<void> {
    const ok = await AppService.login(this.phone, this.password);
    if (!ok) {
      promptAction.showToast({ message: '请输入手机号和密码' });
      return;
    }
    router.replaceUrl({ url: AppRoutes.HOME });
  }

  @Builder
  InputRow(label: string, placeholder: string, isPassword: boolean) {
    Row() {
      Text(label)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(AndroidColor.GREEN_LABEL)
        .margin({ right: 12 })

      TextInput({ placeholder })
        .layoutWeight(1)
        .height(48)
        .fontSize(16)
        .fontColor(AndroidColor.GREEN_LABEL)
        .placeholderColor(AndroidColor.GREEN_HINT)
        .backgroundColor(Color.Transparent)
        .type(isPassword ? InputType.Password : InputType.PhoneNumber)
        .onChange((value: string) => {
          if (isPassword) {
            this.password = value;
          } else {
            this.phone = value;
          }
        })

      if (isPassword) {
        Text('显')
          .fontSize(16)
          .fontColor(AndroidColor.GREEN_HINT)
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
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
            .margin({ bottom: 25 })

          Image($r('app.media.image_14'))
            .width(120)
            .height(135)
            .objectFit(ImageFit.Contain)
            .borderRadius(20)
            .shadow({ radius: 10, color: '#33000000', offsetX: 0, offsetY: 4 })

          Column() {
            this.InputRow('+86', '请输入手机号', false)

            Row() {
              this.InputRow('密码', '请输入密码', true)
            }
            .margin({ top: 16 })

            Row() {
              Button('忘记密码')
                .type(ButtonType.Normal)
                .fontSize(14)
                .fontColor('#5A7153')
                .backgroundColor('#DFEFE0')
                .padding(8)
                .onClick(() => router.pushUrl({ url: AppRoutes.NEW_PASSWORD }))

              Divider()
                .vertical(true)
                .height(12)
                .color(AndroidColor.PAGE_BG)
                .margin({ left: 15, right: 15 })

              Button('注册账号')
                .type(ButtonType.Normal)
                .fontSize(14)
                .fontColor('#5A7153')
                .backgroundColor('#DFEFE0')
                .padding(8)
                .onClick(() => router.pushUrl({ url: AppRoutes.REGISTER }))
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .margin({ top: 12 })

            Row() {
              Checkbox()
                .select(this.agreed)
                .selectedColor(AndroidColor.GREEN_DARK)
                .onChange((value: boolean) => this.agreed = value)
              Text('我已阅读并同意《用户协议》《隐私政策》')
                .fontSize(12)
                .fontColor(AndroidColor.GREEN_HINT)
                .margin({ left: 4 })
            }
            .justifyContent(FlexAlign.Center)
            .width('100%')
            .margin({ top: 20 })

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
          .padding(25)
          .backgroundColor(Color.White)
          .borderRadius(28)
          .shadow({ radius: 6, color: '#33000000', offsetX: 0, offsetY: 3 })
          .margin({ left: 25, right: 25, top: 30 })
        }
        .width('100%')
        .padding({ top: 30, bottom: 30 })
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
