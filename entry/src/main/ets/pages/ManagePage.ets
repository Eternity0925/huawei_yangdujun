import { router } from '@kit.ArkUI';
import { AndroidBottomNav } from '../common/AndroidWidgets';
import { AppRoutes } from '../common/AppRoutes';
import { AlarmRecord } from '../models/AppModels';
import { AppService } from '../services/AppService';

interface ManageGridItem {
  icon: string;
  title: string;
  tint: string;
  route: string;
}

@Entry
@Component
struct ManagePage {
  private items: ManageGridItem[] = [
    { icon: '📱', title: '设备状态管理', tint: '#A8C69F', route: AppRoutes.DEVICE_MANAGE },
    { icon: '⚙️', title: '告警阈值设置', tint: '#E0EADD', route: AppRoutes.ALARM_THRESHOLD },
    { icon: '📊', title: '历史数据分析', tint: '#C8D6C5', route: AppRoutes.HISTORY_ANALYSIS },
    { icon: '📈', title: '实时数据分析', tint: '#A8C69F', route: AppRoutes.REALTIME_ANALYSIS },
    { icon: '🔧', title: '设备调控', tint: '#CFDDCB', route: AppRoutes.DEVICE_MONITOR },
    { icon: '🔔', title: '告警记录', tint: '#A8C69F', route: AppRoutes.ALARM_RECORD }
  ];

  @State alarms: AlarmRecord[] = AppService.getAlarms().slice(0, 5);

  aboutToAppear(): void {
    this.alarms = AppService.getAlarms().slice(0, 5);
  }

  private isHandled(item: AlarmRecord): boolean {
    return item.status.indexOf('已') >= 0;
  }

  @Builder
  GridEntry(item: ManageGridItem) {
    Column({ space: 8 }) {
      Text(item.icon)
        .width(60)
        .height(60)
        .fontSize(34)
        .textAlign(TextAlign.Center)
        .backgroundColor(item.tint)
        .borderRadius(30)
      Text(item.title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#4A6142')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(120)
    .padding(16)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F2F6F1')
    .borderRadius(12)
    .onClick(() => router.pushUrl({ url: item.route }))
  }

  @Builder
  AlarmItem(item: AlarmRecord) {
    Stack() {
      Column()
        .width(82)
        .height(82)
        .backgroundColor('#A8C69F')
        .opacity(0.16)
        .borderRadius(41)
        .position({ x: 265, y: -24 })
      Column()
        .width(24)
        .height(24)
        .backgroundColor('#A8C69F')
        .opacity(0.45)
        .borderRadius(12)
        .position({ x: 10, y: 86 })
      Column({ space: 8 }) {
        Row() {
          Text(item.greenhouseName)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2E7D32')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text('  ·  ')
            .fontSize(14)
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
            .padding({ left: 12, right: 12, top: 4, bottom: 4 })
            .backgroundColor(this.isHandled(item) ? '#748F75' : '#EA4B4B')
            .borderRadius(4)
        }
        Text(item.title)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#4A6142')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(item.createdAt)
          .fontSize(12)
          .fontColor('#9EBA95')
          .width('100%')
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)
      .borderRadius(20)
      .shadow({ radius: 4, color: '#22000000', offsetX: 0, offsetY: 2 })
    }
    .width('100%')
    .height(116)
    .margin({ bottom: 10 })
    .onClick(() => router.pushUrl({ url: AppRoutes.ALARM_RECORD }))
  }

  build() {
    Stack() {
      Column()
        .width(280)
        .height(280)
        .backgroundColor('#A8C69F')
        .opacity(0.1)
        .borderRadius(140)
        .position({ x: -60, y: -80 })

      Column() {
        Text('大棚管理')
          .width('100%')
          .height(70)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .backgroundColor('#558C58')
          .borderRadius(15)
          .margin(10)
          .padding(16)
          .shadow({ radius: 6, color: '#33000000', offsetX: 0, offsetY: 2 })

        Scroll() {
          Column() {
            Grid() {
              ForEach(this.items, (item: ManageGridItem) => {
                GridItem() {
                  this.GridEntry(item)
                }
              }, (item: ManageGridItem) => item.title)
            }
            .columnsTemplate('1fr 1fr')
            .columnsGap(12)
            .rowsGap(12)
            .height(408)
            .padding(12)
            .backgroundColor('#EBF6E5')
            .borderRadius(24)
            .shadow({ radius: 4, color: '#22000000', offsetX: 0, offsetY: 2 })
            .margin({ left: 16, right: 16, top: 16, bottom: 12 })

            Text('处理告警信息')
              .width('100%')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2E7D32')
              .padding({ left: 24, right: 24, top: 8, bottom: 8 })

            Column() {
              if (this.alarms.length === 0) {
                Text('暂无告警记录')
                  .width('100%')
                  .padding(24)
                  .fontSize(16)
                  .fontColor('#4A6142')
                  .fontWeight(FontWeight.Bold)
                  .textAlign(TextAlign.Center)
                  .backgroundColor(Color.White)
                  .borderRadius(20)
              } else {
                ForEach(this.alarms, (item: AlarmRecord) => {
                  this.AlarmItem(item)
                }, (item: AlarmRecord) => item.id)
              }
            }
            .padding({ left: 16, right: 16, bottom: 20 })
          }
        }
        .layoutWeight(1)

        AndroidBottomNav({ active: 'manage' })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#E9F2E6')
  }
}
