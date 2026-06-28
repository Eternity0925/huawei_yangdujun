import { promptAction, router } from '@kit.ArkUI';
import { AndroidColor } from '../common/AndroidStyle';
import { AppRoutes } from '../common/AppRoutes';
import { AppService } from '../services/AppService';

@Entry
@Component
struct NewPasswordPage {
  @State phone: string = '';
  @State password: string = '';
  @State showPassword: boolean = false;

  private isAllLetterOrDigit(value: string): boolean {
    let isAllLetter = true;
    let isAllDigit = true;
    for (let i = 0; i < value.length; i++) {
      const code = value.charCodeAt(i);
      const isLetter = (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
      const isDigit = code >= 48 && code <= 57;
      if (!isLetter) {
        isAllLetter = false;
      }
      if (!isDigit) {
        isAllDigit = false;
      }
    }
    return isAllLetter || isAllDigit;
  }

  private submit(): void {
    if (this.phone.length !== 11) {
      promptAction.showToast({ message: '请输入正确的手机号码' });
      return;
    }
    if (this.password.length < 8) {
      promptAction.showToast({ message: '密码长度不能少于8位' });
      return;
    }
    if (this.isAllLetterOrDigit(this.password)) {
      promptAction.showToast({ message: '密码不能全是字母或数字，请重新设置' });
      return;
    }
    promptAction.showToast({ message: '重置密码中...' });
    const ok = AppService.resetPassword(this.phone, this.password);
    if (!ok) {
      promptAction.showToast({ message: '重置密码失败，请稍后重试' });
      return;
    }
    promptAction.showToast({ message: '密码修改成功，即将返回登录页' });
    router.replaceUrl({ url: AppRoutes.LOGIN });
  }

  build() {
    Stack() {
      Image($r('app.media.image_9'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .opacity(0.22)

      Circle()
        .width(320)
        .height(320)
        .fill(AndroidColor.GREEN_SOFT)
        .opacity(0.1)
        .position({ x: 170, y: 610 })

      Column() {
        Row() {
          Text('<')
            .width(40)
            .height(40)
            .fontSize(24)
            .fontColor(AndroidColor.GREEN_DARK)
            .textAlign(TextAlign.Center)
            .backgroundColor(Color.White)
            .borderRadius(20)
            .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })
            .onClick(() => router.replaceUrl({ url: AppRoutes.LOGIN }))
          Text('找回密码')
            .layoutWeight(1)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(AndroidColor.GREEN_TEXT)
            .textAlign(TextAlign.Center)
          Blank().width(40)
        }
        .height(64)
        .padding({ left: 16, right: 16 })
        .margin({ top: 20 })

        Scroll() {
          Column() {
            Image($r('app.media.image_14'))
              .width(140)
              .height(125)
              .objectFit(ImageFit.Contain)
              .borderRadius(20)
              .shadow({ radius: 12, color: '#33000000', offsetX: 0, offsetY: 4 })
              .margin({ bottom: 30 })

            Column() {
              Row() {
                Text('+86')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AndroidColor.GREEN_LABEL)
                  .margin({ right: 12 })
                TextInput({ placeholder: '手机号' })
                  .layoutWeight(1)
                  .height(48)
                  .fontSize(16)
                  .fontColor(AndroidColor.GREEN_LABEL)
                  .placeholderColor(AndroidColor.GREEN_HINT)
                  .backgroundColor(Color.Transparent)
                  .type(InputType.PhoneNumber)
                  .onChange((value: string) => this.phone = value)
                Text('号').fontSize(16).fontColor(AndroidColor.GREEN_DARK)
              }
              .height(56)
              .padding({ left: 16, right: 16 })
              .backgroundColor(AndroidColor.INPUT_BG)

              Row() {
                TextInput({ placeholder: '新密码' })
                  .layoutWeight(1)
                  .height(48)
                  .fontSize(16)
                  .fontColor(AndroidColor.GREEN_LABEL)
                  .placeholderColor(AndroidColor.GREEN_HINT)
                  .backgroundColor(Color.Transparent)
                  .type(this.showPassword ? InputType.Normal : InputType.Password)
                  .onChange((value: string) => this.password = value)
                Text(this.showPassword ? '隐' : '显')
                  .fontSize(16)
                  .fontColor(AndroidColor.GREEN_HINT)
                  .onClick(() => this.showPassword = !this.showPassword)
              }
              .height(56)
              .padding({ left: 16, right: 16 })
              .backgroundColor(AndroidColor.INPUT_BG)
              .margin({ top: 16 })

              Text('至少8个字符，不能全是字母或数字')
                .fontSize(12)
                .fontStyle(FontStyle.Italic)
                .fontColor(AndroidColor.GREEN_DARK)
                .margin({ top: 12, left: 4 })
                .width('100%')

              Button('确认更改')
                .width('100%')
                .height(54)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
                .backgroundColor(AndroidColor.GREEN_DARK)
                .borderRadius(27)
                .margin({ top: 24 })
                .onClick(() => this.submit())
            }
            .width('100%')
            .padding(25)
            .backgroundColor(Color.White)
            .borderRadius(28)
            .shadow({ radius: 6, color: '#33000000', offsetX: 0, offsetY: 3 })
            .margin({ left: 25, right: 25 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 20 })
        }
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AndroidColor.PAGE_BG)
  }
}
