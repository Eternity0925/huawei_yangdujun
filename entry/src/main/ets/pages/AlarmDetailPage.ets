import { router } from '@kit.ArkUI';
import { AlarmRecord } from '../models/AppModels';
import { AppService } from '../services/AppService';

@Entry
@Component
struct AlarmDetailPage {
  @State alarm: AlarmRecord = {
    id: 'alarm-empty',
    greenhouseId: 'default',
    greenhouseName: '默认大棚',
    device: '环境传感器',
    title: '暂无告警',
    content: '当前没有可查看的告警处理详情。',
    level: '低',
    status: '已处理',
    createdAt: ''
  };

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    const alarmId = params && params.alarmId ? params.alarmId : '';
    const alarm = alarmId.length > 0 ? AppService.getAlarmById(alarmId) : null;
    if (alarm) {
      this.alarm = alarm;
    }
  }

  private orderId(): string {
    return this.alarm.id.length > 0 ? this.alarm.id.replace('alarm-', '20260624') : '20260624093001';
  }

  private handledTime(): string {
    return this.alarm.handledAt || '暂无';
  }

  private handler(): string {
    return this.alarm.handlerName || '暂无';
  }

  @Builder
  Header() {
    Row() {
      Button('返回')
        .width(74)
        .height(38)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .backgroundColor('#99BF92')
        .borderRadius(19)
        .onClick(() => router.back())
      Text('告警处理详情')
        .layoutWeight(1)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .margin({ right: 74 })
    }
    .width('100%')
    .height(80)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#A8C69F')
    .borderRadius(28)
    .shadow({ radius: 12, color: '#33000000', offsetX: 0, offsetY: 3 })
    .margin(16)
  }

  @Builder
  DoneBlock() {
    Column({ space: 8 }) {
      Text('✓')
        .width(90)
        .height(90)
        .fontSize(44)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .backgroundColor('#A8C69F')
        .borderRadius(45)
      Text('任务已处理完成')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#5A7D54')
    }
    .width('100%')
    .padding(10)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  InfoRow(label: string, value: string, highlight: boolean = false) {
    Column() {
      Row() {
        Text(label)
          .fontSize(14)
          .fontColor('#9EBA95')
        Blank()
        Text(value)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(highlight ? '#A8C69F' : '#4A6142')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      Divider()
        .color('#F0F5EF')
        .margin({ top: 12 })
    }
    .width('100%')
    .margin({ bottom: 12 })
  }

  @Builder
  DetailInfoCard() {
    Column() {
      this.InfoRow('工单编号', this.orderId())
      this.InfoRow('告警位置', `${this.alarm.greenhouseName}${this.alarm.device}`)
      this.InfoRow('告警时间', this.alarm.createdAt)
      this.InfoRow('责任人', this.handler(), true)
      Row() {
        Text('联系电话')
          .fontSize(14)
          .fontColor('#9EBA95')
        Blank()
        Text('暂无')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#4A6142')
      }
      .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(24)
    .shadow({ radius: 6, color: '#22000000', offsetX: 0, offsetY: 2 })
    .margin({ top: 16 })
  }

  @Builder
  ContentCard() {
    Column({ space: 8 }) {
      Text('内容')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1B320E')
      Text(`${this.alarm.greenhouseName}${this.alarm.device}${this.alarm.title}`)
        .fontSize(16)
        .fontColor('#666666')
        .lineHeight(24)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(24)
    .shadow({ radius: 6, color: '#22000000', offsetX: 0, offsetY: 2 })
    .margin({ top: 16 })
  }

  @Builder
  TimelinePoint(title: string, time: string, detail: string = '') {
    Row() {
      Column()
        .width(12)
        .height(12)
        .backgroundColor('#A8C69F')
        .borderRadius(6)
        .margin({ top: 4 })
      Column({ space: 4 }) {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#4A6142')
        Text(time)
          .fontSize(12)
          .fontColor('#4A6142')
        if (detail.length > 0) {
          Text(detail)
            .width('100%')
            .fontSize(14)
            .fontColor('#7A9A71')
            .padding(10)
            .backgroundColor('#F8FCF7')
            .borderRadius(6)
            .margin({ top: 8 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
    }
    .width('100%')
  }

  @Builder
  TimelineCard() {
    Column({ space: 0 }) {
      Text('处理进度')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#4A6142')
        .margin({ bottom: 20 })
      this.TimelinePoint('发布告警', this.alarm.createdAt)
      Column()
        .width(2)
        .height(30)
        .backgroundColor('#E9F2E6')
        .margin({ left: 5 })
      this.TimelinePoint('处理完成', this.handledTime(), `已经通过APP手动处理${this.alarm.greenhouseName}${this.alarm.device}，执行${this.alarm.title}`)
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(24)
    .shadow({ radius: 6, color: '#22000000', offsetX: 0, offsetY: 2 })
    .margin({ top: 16, bottom: 32 })
  }

  build() {
    Stack() {
      Column()
        .width(268)
        .height(268)
        .backgroundColor('#A8C69F')
        .opacity(0.2)
        .borderRadius(134)
        .position({ x: -60, y: -80 })
      Column()
        .width(120)
        .height(120)
        .backgroundColor('#A8C69F')
        .opacity(0.08)
        .borderRadius(60)
        .position({ x: 250, y: 360 })
      Column() {
        this.Header()
        Scroll() {
          Column() {
            this.DoneBlock()
            this.DetailInfoCard()
            this.ContentCard()
            this.TimelineCard()
          }
          .padding({ left: 16, right: 16, bottom: 20 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#E9F2E6')
  }
}
