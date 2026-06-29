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
      promptAction.showToast({ message: '请输入提问内容' });
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
      AndroidBackTopBar({ title: 'AI 种植助手' })
        .margin({ bottom: 12 })

      Scroll() {
        Column({ space: 12 }) {
          Text('按住说话 / 文字提问')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#143D2A')
            .width('100%')

          Text('语音识别需要后端代理华为云 SIS。当前页面已保留语音入口，文字提问会通过后端代理调用 DeepSeek。')
            .fontSize(13)
            .fontColor('#667085')
            .lineHeight(20)
            .width('100%')

          Button('按住说话')
            .width('100%')
            .height(48)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .backgroundColor('#238B45')
            .borderRadius(24)
            .onClick(() => promptAction.showToast({ message: '语音识别接口已预留，请接入后端 /voice/asr' }))

          TextInput({ placeholder: '请输入你的问题', text: this.inputText })
            .width('100%')
            .height(48)
            .backgroundColor(Color.White)
            .borderRadius(8)
            .onChange((value: string) => {
              this.inputText = value;
            })

          Button(this.isLoading ? '发送中...' : '发送')
            .width('100%')
            .height(46)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .backgroundColor('#238B45')
            .borderRadius(23)
            .onClick(() => this.sendText())

          if (this.latestAnswer.length > 0) {
            Column({ space: 8 }) {
              Text('AI 回复')
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
            Text('历史记录')
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor('#143D2A')
              .width('100%')
            Text(this.history.length > 0 ? this.history : '暂无历史记录')
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
