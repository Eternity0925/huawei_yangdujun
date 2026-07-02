import { router } from '@kit.ArkUI';
import { AppRoutes } from '../common/AppRoutes';
import { AlarmRecord } from '../models/AppModels';
import { AppService } from '../services/AppService';

@Entry
@Component
struct AlarmRecordPage {
  @State currentTab: number = 0;
  @State alarms: AlarmRecord[] = AppService.getAlarms();

  aboutToAppear(): void {
    this.alarms = AppService.getAlarms();
    AppService.refreshAlarmsFromDatabase().then((items: AlarmRecord[]) => {
      this.alarms = items;
    }).catch(() => {
    });
  }

  private isHandled(item: AlarmRecord): boolean {
    return item.status.indexOf('已') >= 0;
  }

  private currentAlarms(): AlarmRecord[] {
    return this.alarms.filter((item: AlarmRecord) => this.currentTab === 1 ? this.isHandled(item) : !this.isHandled(item));
  }

  @Builder
  Header() {
    Row() {
      Button('返回')
        .width(70)
        .height(36)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .backgroundColor('#A8C69F')
        .borderRadius(18)
        .onClick(() => router.back())
      Text('告警记录')
        .layoutWeight(1)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .margin({ right: 70 })
    }
    .width('100%')
    .height(75)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#A8C69F')
    .borderRadius(30)
    .shadow({ radius: 10, color: '#33000000', offsetX: 0, offsetY: 3 })
  }

  @Builder
  TabButton(text: string, index: number) {
    Text(text)
      .layoutWeight(1)
      .height('100%')
      .fontSize(14)
      .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Regular)
      .fontColor(this.currentTab === index ? '#2E7D32' : '#6E8569')
      .textAlign(TextAlign.Center)
      .backgroundColor(this.currentTab === index ? Color.White : '#D9E6D5')
      .borderRadius(23)
      .onClick(() => {
        this.currentTab = index;
      })
  }

  @Builder
  Tabs() {
    Row() {
      this.TabButton('未处理', 0)
      this.TabButton('已处理', 1)
    }
    .width('100%')
    .height(54)
    .padding(4)
    .backgroundColor('#D9E6D5')
    .borderRadius(27)
    .margin({ left: 20, right: 20, bottom: 16 })
  }

  @Builder
  AlarmCard(item: AlarmRecord) {
    Stack() {
      Column()
        .width(80)
        .height(80)
        .backgroundColor('#A8C69F')
        .opacity(0.14)
        .borderRadius(40)
        .position({ x: 260, y: -20 })
      Column()
        .width(24)
        .height(24)
        .backgroundColor('#A8C69F')
        .opacity(0.5)
        .borderRadius(12)
        .position({ x: 10, y: 126 })
      Column({ space: 10 }) {
        Row() {
          Text(item.greenhouseName)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2E7D32')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(' · ')
            .fontSize(18)
            .fontColor('#9EBA95')
          Text(item.device)
            .layoutWeight(1)
            .fontSize(14)
            .fontColor('#9EBA95')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.isHandled(item) ? '已处理' : '未处理')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .padding({ left: 12, right: 12, top: 5, bottom: 5 })
            .backgroundColor(this.isHandled(item) ? '#748F75' : '#EA4B4B')
            .borderRadius(4)
        }
        Text(item.title)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#4A6142')
          .lineHeight(20)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(`告警时间：${item.createdAt}`)
          .fontSize(12)
          .fontColor('#9EBA95')
      }
      .width('100%')
      .padding(16)
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(Color.White)
      .borderRadius(20)
      .shadow({ radius: 3, color: '#22000000', offsetX: 0, offsetY: 2 })
    }
    .width('100%')
    .height(154)
    .margin({ left: 4, right: 4, top: 8, bottom: 12 })
    .onClick(() => {
      router.pushUrl({ url: this.isHandled(item) ? AppRoutes.ALARM_DETAIL : AppRoutes.ALARM_HANDLE, params: { alarmId: item.id } });
    })
  }

  build() {
    Stack() {
      Column()
        .width(320)
        .height(320)
        .backgroundColor('#A8C69F')
        .opacity(0.18)
        .borderRadius(160)
        .position({ x: -120, y: -80 })
      Column()
        .width(180)
        .height(180)
        .backgroundColor('#A8C69F')
        .opacity(0.1)
        .borderRadius(90)
        .position({ x: 280, y: 610 })
      Column()
        .width(60)
        .height(60)
        .backgroundColor('#A8C69F')
        .opacity(0.12)
        .borderRadius(30)
        .position({ x: 348, y: 220 })

      Column({ space: 16 }) {
        this.Header()
        this.Tabs()
        Scroll() {
          Column() {
            if (this.currentAlarms().length === 0) {
              Column({ space: 8 }) {
                Text('暂无告警记录')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#4A6142')
                Text('当前分类下没有告警信息')
                  .fontSize(14)
                  .fontColor('#9EBA95')
              }
              .width('100%')
              .padding(28)
              .alignItems(HorizontalAlign.Start)
              .backgroundColor(Color.White)
              .borderRadius(20)
            } else {
              ForEach(this.currentAlarms(), (item: AlarmRecord) => {
                this.AlarmCard(item)
              }, (item: AlarmRecord) => item.id)
            }
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Start)
          .padding({ top: 0, bottom: 40 })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
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
