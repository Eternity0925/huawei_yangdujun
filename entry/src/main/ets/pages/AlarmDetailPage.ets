import { router } from '@kit.ArkUI';
import { AlarmRecord } from '../models/AppModels';
import { AppService } from '../services/AppService';

@Entry
@Component
struct AlarmDetailPage {
  private alarm: AlarmRecord = AppService.getAlarms().length > 0 ? AppService.getAlarms()[0] : {
    id: '',
    greenhouseId: 'default',
    greenhouseName: '默认大棚',
    device: '环境传感器',
    title: '暂无告警',
    content: '当前没有待查看的告警记录。',
    level: '低',
    status: '已处理',
    createdAt: ''
  };

  build() {
    Column({ space: 12 }) {
      this.Header('告警详情')
      this.Card('告警标题', this.alarm.title)
      this.Card('所属大棚', this.alarm.greenhouseName)
      this.Card('告警设备', this.alarm.device)
      this.Card('告警等级', `${this.alarm.level}级`)
      this.Card('处理状态', this.alarm.status)
      this.Card('发生时间', this.alarm.createdAt)
      this.Card('风险说明', this.alarm.content)
      this.Card('建议操作', '先复核传感器数据，再根据大棚生长阶段调整风机、水泵和遮光板。处理完成后请在告警处理页提交说明。')
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 18 })
    .backgroundColor('#F6FBF6')
  }

  @Builder
  Header(title: string) {
    Row() {
      Text('<').fontSize(22).fontColor('#238B45').onClick(() => router.back())
      Text(title).fontSize(24).fontWeight(FontWeight.Bold).fontColor('#143D2A').margin({ left: 12 })
    }.width('100%')
  }

  @Builder
  Card(title: string, content: string) {
    Column({ space: 6 }) {
      Text(title).fontSize(14).fontColor('#667085')
      Text(content).fontSize(16).fontColor('#1F2937')
    }.alignItems(HorizontalAlign.Start).width('100%').padding(16).backgroundColor(Color.White).borderRadius(8)
  }
}
