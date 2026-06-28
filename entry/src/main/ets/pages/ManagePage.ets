import { router } from '@kit.ArkUI';
import { AndroidBottomNav } from '../common/AndroidWidgets';
import { AndroidColor } from '../common/AndroidStyle';
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
    { icon: '设', title: '设备状态管理', tint: '#A8C69F', route: AppRoutes.DEVICE_MANAGE },
    { icon: '阈', title: '告警阈值设置', tint: '#E0EADD', route: AppRoutes.ALARM_THRESHOLD },
    { icon: '史', title: '历史数据分析', tint: '#C8D6C5', route: AppRoutes.HISTORY_ANALYSIS },
    { icon: '实', title: '实时数据分析', tint: '#A8C69F', route: AppRoutes.REALTIME_ANALYSIS },
    { icon: '控', title: '设备调控', tint: '#CFDDCB', route: AppRoutes.DEVICE_MONITOR },
    { icon: '警', title: '告警记录', tint: '#A8C69F', route: AppRoutes.ALARM_RECORD }
  ];

  private alarms: AlarmRecord[] = AppService.getAlarms().slice(0, 5);

  @Builder
  GridEntry(item: ManageGridItem) {
    Column({ space: 8 }) {
      Text(item.icon)
        .width(60)
        .height(60)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(AndroidColor.GREEN_LABEL)
        .textAlign(TextAlign.Center)
        .backgroundColor(item.tint)
        .borderRadius(30)
      Text(item.title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(AndroidColor.GREEN_LABEL)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(AndroidColor.INPUT_BG)
    .borderRadius(12)
    .onClick(() => router.pushUrl({ url: item.route }))
  }

  @Builder
  AlarmItem(item: AlarmRecord) {
    Column({ space: 6 }) {
      Row() {
        Text(item.title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(AndroidColor.GREEN_TEXT)
        Blank()
        Text(item.status)
          .fontSize(12)
          .fontColor(Color.White)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .backgroundColor(item.status.indexOf('已') >= 0 ? '#2E7D32' : '#C62828')
          .borderRadius(4)
      }
      Text(`${item.level}级  ${item.createdAt}`)
        .fontSize(13)
        .fontColor(AndroidColor.TEXT_SECONDARY)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .margin({ bottom: 8 })
    .onClick(() => router.pushUrl({ url: AppRoutes.ALARM_RECORD }))
  }

  build() {
    Stack() {
      Circle()
        .width(280)
        .height(280)
        .fill(AndroidColor.GREEN_SOFT)
        .opacity(0.1)
        .position({ x: -60, y: -80 })

      Column() {
        Text('大棚管理')
          .width('100%')
          .height(70)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .backgroundColor(AndroidColor.GREEN_HEADER)
          .borderRadius(15)
          .margin(10)
          .padding(16)
          .shadow({ radius: 6, color: '#33000000', offsetX: 0, offsetY: 2 })

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
          .height(480)
          .padding(12)
        }
        .margin({ left: 16, right: 16, top: 16, bottom: 12 })
        .backgroundColor('#EBF6E5')
        .borderRadius(24)
        .shadow({ radius: 4, color: '#22000000', offsetX: 0, offsetY: 2 })

        Text('处理告警信息')
          .width('100%')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AndroidColor.GREEN_DARK)
          .padding({ left: 24, right: 24, top: 8, bottom: 8 })

        Scroll() {
          Column() {
            if (this.alarms.length === 0) {
              Text('暂无告警信息')
                .fontSize(15)
                .fontColor(AndroidColor.TEXT_SECONDARY)
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding(24)
                .backgroundColor(Color.White)
                .borderRadius(8)
            } else {
              ForEach(this.alarms, (item: AlarmRecord) => {
                this.AlarmItem(item)
              }, (item: AlarmRecord) => item.id)
            }
          }
          .padding({ left: 16, right: 16 })
        }
        .layoutWeight(1)
        .backgroundColor(AndroidColor.PAGE_BG)

        AndroidBottomNav({ active: 'manage' })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AndroidColor.PAGE_BG)
  }
}
