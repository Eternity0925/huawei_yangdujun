import { promptAction } from '@kit.ArkUI';
import { AndroidBackTopBar } from '../common/AndroidWidgets';
import { AppService } from '../services/AppService';

@Entry
@Component
struct AiSuggestionPage {
  @State inputText: string = '';
  @State latestAnswer: string = '';
  @State history: string = AppService.getChatHistory();
  @State isLoading: boolean = false;

  private async sendText(): Promise<void> {
    const text = this.inputText.trim();
    if (text.length === 0) {
      promptAction.showToast({ message: '\u8bf7\u8f93\u5165\u63d0\u95ee\u5185\u5bb9' });
      return;
    }
    if (this.isLoading) {
      return;
    }
    this.isLoading = true;
    try {
      this.latestAnswer = await AppService.requestAiChat(text);
      this.history = AppService.getChatHistory();
      this.inputText = '';
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      AndroidBackTopBar({ title: 'AI \u79cd\u690d\u52a9\u624b' })
        .margin({ bottom: 12 })

      Scroll() {
        Column({ space: 12 }) {
          Text('\u6587\u5b57\u63d0\u95ee')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#143D2A')
            .width('100%')

          Text('\u53ef\u4ee5\u8be2\u95ee\u7f8a\u809a\u83cc\u5927\u68da\u73af\u5883\u8c03\u63a7\u3001\u544a\u8b66\u5904\u7406\u3001\u751f\u957f\u9636\u6bb5\u7ba1\u7406\u7b49\u95ee\u9898\uff0c\u56de\u7b54\u7531\u540e\u7aef\u4ee3\u7406\u8c03\u7528 DeepSeek \u751f\u6210\u3002')
            .fontSize(13)
            .fontColor('#667085')
            .lineHeight(20)
            .width('100%')

          TextInput({ placeholder: '\u8bf7\u8f93\u5165\u4f60\u7684\u95ee\u9898', text: this.inputText })
            .width('100%')
            .height(48)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .onChange((value: string) => {
              this.inputText = value;
            })

          Button(this.isLoading ? '\u53d1\u9001\u4e2d...' : '\u53d1\u9001')
            .width('100%')
            .height(46)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .backgroundColor('#238B45')
            .borderRadius(23)
            .enabled(!this.isLoading)
            .onClick(() => this.sendText())

          if (this.latestAnswer.length > 0) {
            Column({ space: 8 }) {
              Text('AI \u56de\u590d')
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor('#143D2A')
                .width('100%')
              Text(this.latestAnswer)
                .fontSize(15)
                .fontColor('#1F2937')
                .lineHeight(24)
                .width('100%')
            }
            .width('100%')
            .padding(14)
            .backgroundColor(Color.White)
            .borderRadius(14)
          }

          Column({ space: 8 }) {
            Text('\u5386\u53f2\u8bb0\u5f55')
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor('#143D2A')
              .width('100%')
            Text(this.history.length > 0 ? this.history : '\u6682\u65e0\u5386\u53f2\u8bb0\u5f55')
              .fontSize(14)
              .fontColor('#1F2937')
              .lineHeight(22)
              .width('100%')
          }
          .width('100%')
          .padding(14)
          .backgroundColor(Color.White)
          .borderRadius(14)
        }
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 16 })
    .backgroundColor('#E9F2E6')
  }
}
