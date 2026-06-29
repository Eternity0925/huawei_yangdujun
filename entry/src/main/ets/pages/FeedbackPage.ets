import { promptAction, router } from '@kit.ArkUI';
import { AndroidBackTopBar } from '../common/AndroidWidgets';
import { AppService } from '../services/AppService';

@Entry
@Component
struct FeedbackPage {
  @State content: string = '';

  build() {
    Column({ space: 12 }) {
      AndroidBackTopBar({ title: '意见反馈' })

      TextArea({ placeholder: '请输入反馈内容' })
        .height(220)
        .backgroundColor(Color.White)
        .borderRadius(14)
        .padding(12)
        .shadow({ radius: 2, color: '#18000000', offsetX: 0, offsetY: 1 })
        .onChange((value: string) => this.content = value)

      Button('提交')
        .width('100%')
        .height(46)
        .backgroundColor('#238B45')
        .borderRadius(23)
        .onClick(() => {
          const ok = AppService.submitFeedback(this.content);
          if (!ok) {
            promptAction.showToast({ message: '请输入反馈内容' });
            return;
          }
          promptAction.showToast({ message: '反馈已保存' });
          router.back();
        })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 10 })
    .backgroundColor('#E9F2E6')
  }
}
