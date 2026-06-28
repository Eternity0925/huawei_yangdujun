import { promptAction, router } from '@kit.ArkUI';
import { AndroidColor } from '../common/AndroidStyle';
import { AppService } from '../services/AppService';
import { User } from '../models/AppModels';

@Entry
@Component
struct EditProfilePage {
  @State nickname: string = '';
  @State phone: string = '';
  @State token: string = '';

  aboutToAppear(): void {
    const user: User | null = AppService.getCurrentUser();
    if (user) {
      this.nickname = user.nickname;
      this.phone = user.phone;
      this.token = user.token;
    }
  }

  private save(): void {
    if (this.nickname.trim().length === 0) {
      promptAction.showToast({ message: '昵称不能为空' });
      return;
    }
    const ok = AppService.updateCurrentUser(this.nickname.trim());
    promptAction.showToast({ message: ok ? '保存成功' : '保存失败，请重试' });
    if (ok) {
      router.back();
    }
  }

  @Builder
  Label(text: string) {
    Text(text)
      .fontSize(12)
      .fontColor(AndroidColor.GREEN_HINT)
      .width('100%')
  }

  build() {
    Stack() {
      Circle()
        .width(260)
        .height(260)
        .fill(AndroidColor.GREEN_SOFT)
        .opacity(0.15)
        .position({ x: -80, y: -60 })
      Circle()
        .width(140)
        .height(140)
        .fill(AndroidColor.GREEN_SOFT)
        .opacity(0.08)
        .position({ x: 260, y: 300 })

      Column() {
        Row() {
          Text('<')
            .width(40)
            .height(40)
            .fontSize(24)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
            .backgroundColor('#98C186')
            .borderRadius(20)
            .margin({ left: 16 })
            .onClick(() => router.back())
          Text('编辑个人信息')
            .layoutWeight(1)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
          Text('保存')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .margin({ right: 20 })
            .onClick(() => this.save())
        }
        .height(70)
        .width('100%')
        .backgroundColor(AndroidColor.GREEN_SOFT)
        .borderRadius(30)
        .shadow({ radius: 8, color: '#33000000', offsetX: 0, offsetY: 3 })
        .margin({ bottom: 20 })

        Scroll() {
          Column() {
            Stack() {
              Image($r('app.media.image_1'))
                .width(130)
                .height(130)
                .objectFit(ImageFit.Cover)
                .borderRadius(65)
                .padding(4)
                .backgroundColor(AndroidColor.GREEN_SOFT)
              Text('修改头像')
                .fontSize(11)
                .fontColor(Color.White)
                .backgroundColor(AndroidColor.GREEN_PRIMARY)
                .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                .borderRadius(8)
                .position({ x: 32, y: 118 })
            }
            .width(130)
            .height(150)
            .margin({ top: 10, bottom: 24 })

            Column() {
              this.Label('昵称')
              TextInput({ placeholder: '请输入昵称', text: this.nickname })
                .width('100%')
                .height(50)
                .fontSize(15)
                .fontColor(AndroidColor.GREEN_LABEL)
                .placeholderColor('#BDD1B8')
                .padding({ left: 16, right: 16 })
                .backgroundColor('#F8FCF7')
                .margin({ top: 6 })
                .onChange((value: string) => this.nickname = value)

              Blank().height(16)
              this.Label('手机号')
              Text(this.phone)
                .width('100%')
                .height(50)
                .fontSize(15)
                .fontColor('#7A9A71')
                .padding({ left: 16, right: 16, top: 15 })
                .backgroundColor('#F8FCF7')
                .margin({ top: 6 })

              Blank().height(16)
              this.Label('用户令牌 (Token)')
              Text(this.token)
                .width('100%')
                .height(60)
                .fontSize(13)
                .fontColor('#7A9A71')
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .padding({ left: 16, right: 16, top: 12 })
                .backgroundColor('#F8FCF7')
                .margin({ top: 6 })
            }
            .width('100%')
            .padding(24)
            .backgroundColor(Color.White)
            .borderRadius(30)
            .shadow({ radius: 4, color: '#22000000', offsetX: 0, offsetY: 2 })
            .margin({ bottom: 40 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .padding(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AndroidColor.PAGE_BG)
  }
}
