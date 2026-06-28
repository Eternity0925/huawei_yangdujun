import { promptAction, router } from '@kit.ArkUI';

@Entry
@Component
struct FeedbackPage {
  @State content: string = '';

  build() {
    Column({ space: 12 }) {
      Row() {
        Text('<').fontSize(22).fontColor('#238B45').onClick(() => router.back())
        Text('意见反馈').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#143D2A').margin({ left: 12 })
      }.width('100%')

      TextArea({ placeholder: '请输入反馈内容' })
        .height(220)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .padding(12)
        .onChange((value: string) => this.content = value)

      Button('提交')
        .width('100%')
        .height(46)
        .backgroundColor('#238B45')
        .borderRadius(8)
        .onClick(() => {
          promptAction.showToast({ message: '反馈已保存' });
          router.back();
        })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 18 })
    .backgroundColor('#F6FBF6')
  }
}
