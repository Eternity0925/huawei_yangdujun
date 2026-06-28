import { router } from '@kit.ArkUI';
import { AppRoutes } from '../common/AppRoutes';
import { AlarmRecord } from '../models/AppModels';
import { AppService } from '../services/AppService';

@Entry
@Component
struct AlarmRecordPage {
  private alarms: AlarmRecord[] = AppService.getAlarms();

  build() {
    Column({ space: 12 }) {
      Row() {
        Text('<').fontSize(22).fontColor('#238B45').onClick(() => router.back())
        Text('告警记录').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#143D2A').margin({ left: 12 })
      }.width('100%')

      Scroll() {
        Column({ space: 12 }) {
          if (this.alarms.length === 0) {
            Text('暂无告警记录')
              .width('100%')
              .fontSize(16)
              .fontColor('#667085')
              .textAlign(TextAlign.Center)
              .padding(24)
              .backgroundColor(Color.White)
              .borderRadius(8)
          } else {
            ForEach(this.alarms, (item: AlarmRecord) => {
              Column({ space: 8 }) {
                Row() {
                  Text(item.title).fontSize(17).fontWeight(FontWeight.Medium).fontColor('#1F2937')
                  Blank()
                  Text(item.level).fontSize(13).fontColor(item.level === '中' ? '#D9480F' : '#238B45')
                }
                Text(`${item.greenhouseName}  ${item.status}  ${item.createdAt}`).fontSize(13).fontColor('#667085')
                Text(item.content).fontSize(14).fontColor('#344054').maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                Row({ space: 8 }) {
                  Button('详情')
                    .height(34)
                    .backgroundColor('#E6F4EA')
                    .fontColor('#238B45')
                    .onClick(() => router.pushUrl({ url: AppRoutes.ALARM_DETAIL }))
                  Button('处理')
                    .height(34)
                    .backgroundColor('#238B45')
                    .onClick(() => router.pushUrl({ url: AppRoutes.ALARM_HANDLE }))
                }
              }
              .alignItems(HorizontalAlign.Start)
              .width('100%')
              .padding(16)
              .backgroundColor(Color.White)
              .borderRadius(8)
            }, (item: AlarmRecord) => item.id)
          }
        }
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 18 })
    .backgroundColor('#F6FBF6')
  }
}
