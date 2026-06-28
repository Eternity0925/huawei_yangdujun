import { promptAction, router } from '@kit.ArkUI';
import { AndroidColor } from '../common/AndroidStyle';
import { AppRoutes } from '../common/AppRoutes';
import { AppService } from '../services/AppService';

@Entry
@Component
struct RegisterPage {
  @State phone: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State agreed: boolean = false;

  private async submit(): Promise<void> {
    if (!this.agreed) {
      promptAction.showToast({ message: '请先同意用户协议与隐私政策' });
      return;
    }
    if (this.phone.length !== 11) {
      promptAction.showToast({ message: '请输入正确的手机号码' });
      return;
    }
    if (this.password.length < 8) {
      promptAction.showToast({ message: '密码长度不能少于8位' });
      return;
    }
    if (!this.isPasswordStrong(this.password)) {
      promptAction.showToast({ message: '密码必须包含字母和数字' });
      return;
    }
    if (this.password !== this.confirmPassword) {
      promptAction.showToast({ message: '两次密码不一致' });
      return;
    }
    const ok = await AppService.register(this.phone, this.password);
    if (!ok) {
      promptAction.showToast({ message: '请填写注册信息' });
      return;
    }
    promptAction.showToast({ message: '注册成功，即将跳转到登录页' });
    setTimeout(() => {
      router.replaceUrl({ url: AppRoutes.LOGIN });
    }, 1200);
  }

  private isPasswordStrong(password: string): boolean {
    let hasLetter = false;
    let hasDigit = false;
    for (let i = 0; i < password.length; i++) {
      const code = password.charCodeAt(i);
      if ((code >= 65 && code <= 90) || (code >= 97 && code <= 122)) {
        hasLetter = true;
      }
      if (code >= 48 && code <= 57) {
        hasDigit = true;
      }
      if (hasLetter && hasDigit) {
        return true;
      }
    }
    return false;
  }

  @Builder
  Field(placeholder: string, isPassword: boolean, kind: string) {
    Row() {
      if (kind === 'phone') {
        Text('+86')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(AndroidColor.GREEN_LABEL)
          .margin({ right: 14 })
      }

      TextInput({ placeholder })
        .layoutWeight(1)
        .height(48)
        .fontSize(15)
        .fontColor(AndroidColor.GREEN_LABEL)
        .placeholderColor(AndroidColor.GREEN_HINT)
        .backgroundColor(Color.Transparent)
        .type(isPassword ? InputType.Password : InputType.PhoneNumber)
        .onChange((value: string) => {
          if (kind === 'phone') {
            this.phone = value;
          } else if (kind === 'password') {
            this.password = value;
          } else {
            this.confirmPassword = value;
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
        .width(300)
        .height(300)
        .fill(AndroidColor.GREEN_SOFT)
        .opacity(0.12)
        .position({ x: -80, y: -50 })

      Column() {
        Row() {
          Stack() {
            Text('<')
              .fontSize(24)
              .fontColor(AndroidColor.GREEN_DARK)
              .textAlign(TextAlign.Center)
          }
          .width(48)
          .height(48)
          .backgroundColor(Color.White)
          .borderRadius(24)
          .shadow({ radius: 2, color: '#22000000', offsetX: 0, offsetY: 1 })
          .onClick(() => router.back())

          Text('注册账号')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(AndroidColor.GREEN_TEXT)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Blank()
            .width(48)
        }
        .height(72)
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
              this.Field('请输入手机号', false, 'phone')
              Column() {
                this.Field('请设置密码', true, 'password')
              }
              .margin({ top: 12 })

              Text('至少8个字符，应同时包含字母和数字')
                .fontSize(12)
                .fontColor('#4F8A56')
                .margin({ top: 7, left: 36, bottom: 2 })
                .width('100%')

              Column() {
                this.Field('请确认密码', true, 'confirm')
              }
              .margin({ top: 10 })

              Button('完成注册')
                .width('100%')
                .height(54)
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
                .backgroundColor(AndroidColor.GREEN_DARK)
                .borderRadius(27)
                .margin({ top: 20 })
                .onClick(() => this.submit())

              Row() {
                Checkbox()
                  .select(this.agreed)
                  .selectedColor(AndroidColor.GREEN_DARK)
                  .onChange((value: boolean) => this.agreed = value)
                Text('同意《用户协议》与《隐私政策》')
                  .fontSize(12)
                  .fontColor(AndroidColor.GREEN_HINT)
                  .margin({ left: 6 })
              }
              .justifyContent(FlexAlign.Center)
              .margin({ top: 18 })

              Row() {
                Text('已有账号？')
                  .fontSize(14)
                  .fontColor(AndroidColor.GREEN_HINT)
                Text('立即登录')
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(AndroidColor.GREEN_DARK)
                  .padding({ left: 8, right: 8, top: 8, bottom: 8 })
                  .onClick(() => router.replaceUrl({ url: AppRoutes.LOGIN }))
              }
              .justifyContent(FlexAlign.Center)
              .margin({ top: 16 })
            }
            .width('100%')
            .padding({ left: 24, right: 24, top: 28, bottom: 28 })
            .backgroundColor(Color.White)
            .borderRadius(24)
            .shadow({ radius: 5, color: '#22000000', offsetX: 0, offsetY: 2 })
            .margin({ left: 24, right: 24 })
          }
          .width('100%')
          .padding({ bottom: 28 })
          .alignItems(HorizontalAlign.Center)
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
