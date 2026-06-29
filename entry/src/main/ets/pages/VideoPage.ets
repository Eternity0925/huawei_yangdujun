import { promptAction, router } from '@kit.ArkUI';
import { AndroidColor } from '../common/AndroidStyle';

@Entry
@Component
struct VideoPage {
  @State isPlaying: boolean = false;
  @State isPaused: boolean = false;
  @State status: string = '监控就绪';

  private playVideo(): void {
    if (this.isPlaying && !this.isPaused) {
      promptAction.showToast({ message: '视频已在播放中' });
      return;
    }
    if (this.isPaused) {
      this.isPaused = false;
      this.status = '继续播放';
      promptAction.showToast({ message: '继续播放' });
      return;
    }
    this.isPlaying = true;
    this.isPaused = false;
    this.status = '正在播放RTSP流';
    promptAction.showToast({ message: '开始播放' });
  }

  private pauseVideo(): void {
    if (!this.isPlaying) {
      promptAction.showToast({ message: '视频未播放，无法暂停' });
      return;
    }
    if (this.isPaused) {
      promptAction.showToast({ message: '视频已暂停' });
      return;
    }
    this.isPaused = true;
    this.status = '已暂停';
    promptAction.showToast({ message: '视频已暂停' });
  }

  private stopVideo(): void {
    if (!this.isPlaying) {
      promptAction.showToast({ message: '视频未播放' });
      return;
    }
    this.isPlaying = false;
    this.isPaused = false;
    this.status = '播放已停止';
    promptAction.showToast({ message: '视频已停止' });
  }

  private backToStart(): void {
    if (!this.isPlaying) {
      promptAction.showToast({ message: '视频未播放' });
      return;
    }
    this.isPaused = false;
    this.status = '重新播放';
    promptAction.showToast({ message: '重新播放视频' });
  }

  build() {
    Stack() {
      Circle()
        .width(300)
        .height(300)
        .fill(AndroidColor.GREEN_SOFT)
        .opacity(0.1)
        .position({ x: -60, y: 640 })

      Column() {
        Row() {
          Button('返回')
            .width(70)
            .height(36)
            .fontSize(13)
            .fontColor(Color.White)
            .backgroundColor('#6F9F62')
            .borderRadius(18)
            .onClick(() => {
              this.isPlaying = false;
              this.isPaused = false;
              router.back();
            })
          Text('大棚视频监控')
            .layoutWeight(1)
            .fontSize(21)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
          Blank()
            .width(70)
        }
        .width('100%')
        .height(62)
        .padding({ left: 14, right: 14 })
        .backgroundColor(AndroidColor.GREEN_HEADER)
        .borderRadius(14)
        .shadow({ radius: 5, color: '#22000000', offsetX: 0, offsetY: 2 })
        .margin({ bottom: 12 })

        Stack() {
          Column() {
            Text(this.isPlaying && !this.isPaused ? 'RTSP' : 'VIDEO')
              .fontSize(34)
              .fontWeight(FontWeight.Bold)
              .fontColor('#444444')
            Text(this.isPlaying ? this.status : '监控画面')
              .fontSize(14)
              .fontColor('#888888')
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .width('100%')
          .height(220)
          .backgroundColor(Color.Black)
          .borderRadius(14)

          Circle()
            .width(16)
            .height(16)
            .fill(AndroidColor.GREEN_DARK)
            .opacity(0.6)
            .position({ x: 330, y: -6 })
        }
        .width('100%')
        .height(236)
        .margin({ bottom: 16 })
        .shadow({ radius: 6, color: '#33000000', offsetX: 0, offsetY: 2 })

        Row({ space: 10 }) {
          Button(this.isPaused ? '继续' : '播放')
            .layoutWeight(1)
            .height(45)
            .fontSize(14)
            .fontColor(Color.White)
            .backgroundColor('#4CAF50')
            .borderRadius(12)
            .enabled(!this.isPlaying || this.isPaused)
            .onClick(() => this.playVideo())
          Button('暂停监控')
            .layoutWeight(1)
            .height(45)
            .fontSize(14)
            .fontColor(Color.White)
            .backgroundColor('#4CAF50')
            .borderRadius(12)
            .enabled(this.isPlaying && !this.isPaused)
            .onClick(() => this.pauseVideo())
          Button('重新播放')
            .layoutWeight(1)
            .height(45)
            .fontSize(14)
            .fontColor(Color.White)
            .backgroundColor('#4CAF50')
            .borderRadius(12)
            .enabled(this.isPlaying)
            .onClick(() => this.backToStart())
        }
        .margin({ bottom: 12 })

        Button('停止监控')
          .width('100%')
          .height(45)
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor('#C64B4B')
          .borderRadius(12)
          .enabled(this.isPlaying)
          .margin({ bottom: 16 })
          .onClick(() => this.stopVideo())

        Text(`状态：${this.status}`)
          .width('100%')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AndroidColor.GREEN_LABEL)
          .textAlign(TextAlign.Center)
          .padding(16)
          .backgroundColor('#C8D6C5')
          .borderRadius(8)
      }
      .width('100%')
      .height('100%')
      .padding(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#E9F2E6')
  }
}
