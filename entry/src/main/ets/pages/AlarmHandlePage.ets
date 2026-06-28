import { promptAction, router } from '@kit.ArkUI';
import { AlarmRecord } from '../models/AppModels';
import { AppService } from '../services/AppService';

@Entry
@Component
struct AlarmHandlePage {
  @State note: string = '';
  private alarm: AlarmRecord | null = AppService.getAlarms().length > 0 ? AppService.getAlarms()[0] : null;

  build() {
    Column({ space: 12 }) {
      Row() {
        Text('<').fontSize(22).fontColor('#238B45').onClick(() => router.back())
        Text('处理告警').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#143D2A').margin({ left: 12 })
      }.width('100%')

      if (this.alarm) {
        Column({ space: 6 }) {
          Text(this.alarm.title).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#1F2937')
          Text(`${this.alarm.greenhouseName}  ${this.alarm.device}`).fontSize(14).fontColor('#667085')
          Text(this.alarm.content).fontSize(14).fontColor('#344054')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(8)
      }

      TextArea({ placeholder: '填写处理说明' })
        .height(180)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .padding(12)
        .onChange((value: string) => this.note = value)

      Button('提交处理')
        .width('100%')
        .height(46)
        .backgroundColor('#238B45')
        .borderRadius(8)
        .onClick(() => {
          if (this.alarm) {
            AppService.handleAlarm(this.alarm.id);
          }
          promptAction.showToast({ message: '处理记录已保存' });
          router.back();
        })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 18 })
    .backgroundColor('#F6FBF6')
  }
}
