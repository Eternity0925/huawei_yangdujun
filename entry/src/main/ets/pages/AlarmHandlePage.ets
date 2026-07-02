import { promptAction, router } from '@kit.ArkUI';
import { AppRoutes } from '../common/AppRoutes';
import { AlarmRecord, Device, Greenhouse } from '../models/AppModels';
import { AppService } from '../services/AppService';

interface SelectItem {
  value: string;
}

@Entry
@Component
struct AlarmHandlePage {
  @State greenhouseIndex: number = 0;
  @State deviceIndex: number = 0;
  @State operateIndex: number = 0;
  @State alarm: AlarmRecord = {
    id: '',
    greenhouseId: 'default',
    greenhouseName: '默认大棚',
    device: '环境传感器',
    title: '暂无告警',
    content: '当前没有需要处理的告警。',
    level: '低',
    status: '未处理',
    createdAt: ''
  };
  @State greenhouses: Greenhouse[] = AppService.getGreenhouses();
  @State deviceList: Device[] = [];
  private operations: SelectItem[] = [
    { value: '开启风机' },
    { value: '开启水泵' },
    { value: '调整挡光板' },
    { value: '关闭设备' }
  ];

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    const alarmId = params && params.alarmId ? params.alarmId : '';
    const alarm = alarmId.length > 0 ? AppService.getAlarmById(alarmId) : null;
    if (alarm) {
      this.alarm = alarm;
      this.syncGreenhouseIndex(alarm.greenhouseId);
    }
    AppService.refreshGreenhousesFromDatabase().then((items: Greenhouse[]) => {
      this.greenhouses = items;
      this.syncGreenhouseIndex(this.alarm.greenhouseId);
      this.refreshDevices();
    }).catch(() => {
      this.refreshDevices();
    });
  }

  private syncGreenhouseIndex(greenhouseId: string): void {
    const index = this.greenhouses.findIndex((item: Greenhouse) => item.id === greenhouseId);
    this.greenhouseIndex = index >= 0 ? index : 0;
    this.deviceIndex = 0;
  }

  private greenhouseOptions(): SelectItem[] {
    const options: SelectItem[] = [];
    for (let i = 0; i < this.greenhouses.length; i++) {
      options.push({ value: this.greenhouses[i].name });
    }
    return options;
  }

  private devices(): Device[] {
    if (this.deviceList.length > 0) {
      return this.deviceList;
    }
    return AppService.getDevices(this.greenhouses[this.greenhouseIndex]?.id || 'default');
  }

  private refreshDevices(): void {
    AppService.refreshDevicesFromDatabase(this.greenhouses[this.greenhouseIndex]?.id || 'default').then((items: Device[]) => {
      this.deviceList = items;
    }).catch(() => {
      this.deviceList = AppService.getDevices(this.greenhouses[this.greenhouseIndex]?.id || 'default');
    });
  }

  private deviceOptions(): SelectItem[] {
    const devices = this.devices();
    const options: SelectItem[] = [];
    for (let i = 0; i < devices.length; i++) {
      options.push({ value: devices[i].name });
    }
    if (options.length === 0) {
      options.push({ value: this.alarm.device });
    }
    return options;
  }

  private nowText(): string {
    return new Date().toLocaleString();
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
        .backgroundColor('#9DBF80')
        .borderRadius(18)
        .onClick(() => router.back())
      Text('告警处理')
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
  InfoLine(label: string, value: string, bold: boolean = false) {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(12)
        .fontColor('#9EBA95')
      Text(value)
        .fontSize(bold ? 16 : 15)
        .fontWeight(bold ? FontWeight.Bold : FontWeight.Regular)
        .fontColor('#4A6142')
        .lineHeight(21)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  AlarmInfoCard() {
    Column({ space: 12 }) {
      this.InfoLine('告警位置', `${this.alarm.greenhouseName}${this.alarm.device}`, true)
      this.InfoLine('告警策略：', this.alarm.title)
      this.InfoLine('告警详情', this.alarm.content)
      Divider().color('#F0F5EF')
      Row() {
        Text('告警时间')
          .fontSize(14)
          .fontColor('#9EBA95')
        Blank()
        Text(this.alarm.createdAt)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#4A6142')
      }
      .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(26)
    .shadow({ radius: 4, color: '#22000000', offsetX: 0, offsetY: 2 })
    .margin({ bottom: 16 })
  }

  @Builder
  SelectRow(label: string, options: SelectItem[], index: number, kind: string) {
    Row() {
      Text(`● ${label}`)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#6BA878')
      Select(options)
        .selected(index)
        .value(options[index]?.value || '')
        .layoutWeight(1)
        .height(48)
        .margin({ left: 12 })
        .onSelect((selected: number) => {
          if (kind === 'greenhouse') {
            this.greenhouseIndex = selected;
            this.deviceIndex = 0;
            this.refreshDevices();
          } else if (kind === 'device') {
            this.deviceIndex = selected;
          } else {
            this.operateIndex = selected;
          }
        })
    }
    .width('100%')
    .margin({ top: kind === 'greenhouse' ? 0 : 12 })
  }

  @Builder
  OperateCard() {
    Column({ space: 16 }) {
      Text('● 执行干预操作')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#5A7D54')
      this.SelectRow('请选择大棚', this.greenhouseOptions(), this.greenhouseIndex, 'greenhouse')
      this.SelectRow('请选择设备', this.deviceOptions(), this.deviceIndex, 'device')
      this.SelectRow('拟执行操作', this.operations, this.operateIndex, 'operate')
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(26)
    .shadow({ radius: 4, color: '#22000000', offsetX: 0, offsetY: 2 })
    .margin({ bottom: 16 })
  }

  @Builder
  SubmitTimeCard() {
    Row() {
      Text('提交时间')
        .fontSize(14)
        .fontColor('#9EBA95')
      Blank()
      Text(this.nowText())
        .fontSize(14)
        .fontColor('#4A6142')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#F8FCF7')
    .borderRadius(26)
    .margin({ bottom: 32 })
  }

  build() {
    Stack() {
      Column()
        .width(300)
        .height(300)
        .backgroundColor('#A8C69F')
        .opacity(0.15)
        .borderRadius(150)
        .position({ x: 210, y: -50 })
      Column()
        .width(150)
        .height(150)
        .backgroundColor('#A8C69F')
        .opacity(0.08)
        .borderRadius(75)
        .position({ x: -30, y: 610 })

      Column({ space: 16 }) {
        this.Header()
        Scroll() {
          Column() {
            this.AlarmInfoCard()
            this.OperateCard()
            this.SubmitTimeCard()
          }
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        Button('确认操作并提交')
          .width('100%')
          .height(60)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .backgroundColor('#A8C69F')
          .borderRadius(16)
          .shadow({ radius: 8, color: '#33000000', offsetX: 0, offsetY: 3 })
          .margin({ bottom: 8 })
          .onClick(async () => {
            if (this.alarm.id.length === 0) {
              promptAction.showToast({ message: '当前没有可处理的告警' });
              return;
            }
            const ok = await AppService.handleAlarmWithDatabase(this.alarm.id);
            if (!ok) {
              promptAction.showToast({ message: '告警处理失败，请返回重试' });
              return;
            }
            promptAction.showToast({ message: '处理成功' });
            router.replaceUrl({ url: AppRoutes.ALARM_DETAIL, params: { alarmId: this.alarm.id } });
          })
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
