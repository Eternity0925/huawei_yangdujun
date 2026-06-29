import { promptAction, router } from '@kit.ArkUI';
import { AndroidBackTopBar } from '../common/AndroidWidgets';
import { AndroidColor } from '../common/AndroidStyle';
import { AppRoutes } from '../common/AppRoutes';
import { AppService } from '../services/AppService';

@Entry
@Component
struct NewPasswordPage {
  @State phone: string = '';
  @State password: string = '';

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

  @Builder
  InputRow(label: string, placeholder: string, isPassword: boolean) {
    Row() {
      Text(label)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(AndroidColor.GREEN_LABEL)
        .margin({ right: 14 })

      TextInput({ placeholder })
        .layoutWeight(1)
        .height(48)
        .fontSize(15)
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
        .width(320)
        .height(320)
        .fill(AndroidColor.GREEN_SOFT)
        .opacity(0.1)
        .position({ x: 170, y: 610 })

      Column() {
        AndroidBackTopBar({ title: '找回密码' })
        .padding({ left: 16, right: 16 })
        .margin({ top: 8 })

        Scroll() {
          Column() {
            Image($r('app.media.image_14'))
              .width(112)
              .height(112)
              .objectFit(ImageFit.Contain)
              .borderRadius(22)
              .shadow({ radius: 8, color: '#22000000', offsetX: 0, offsetY: 3 })
              .margin({ top: 8, bottom: 22 })

            Column() {
              this.InputRow('+86', '手机号', false)

              Column() {
                this.InputRow('密码', '新密码', true)
              }
              .margin({ top: 12 })

              Text('至少8个字符，不能全是字母或数字')
                .fontSize(12)
                .fontColor('#4F8A56')
                .margin({ top: 8, left: 36 })
                .width('100%')

              Button('确认更改')
                .width('100%')
                .height(54)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
                .backgroundColor(AndroidColor.GREEN_DARK)
                .borderRadius(27)
                .margin({ top: 22 })
                .onClick(() => this.submit())
            }
            .width('100%')
            .padding({ left: 24, right: 24, top: 28, bottom: 28 })
            .backgroundColor(Color.White)
            .borderRadius(14)
            .shadow({ radius: 5, color: '#22000000', offsetX: 0, offsetY: 2 })
            .margin({ left: 24, right: 24 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .padding({ bottom: 30 })
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
