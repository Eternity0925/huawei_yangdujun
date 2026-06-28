import { promptAction, router } from '@kit.ArkUI';
import { AndroidColor } from '../common/AndroidStyle';
import { Greenhouse, SensorData } from '../models/AppModels';
import { AppService } from '../services/AppService';

interface SelectItem {
  value: string;
}

@Entry
@Component
struct DeviceMonitorPage {
  @State greenhouseIndex: number = 0;
  @State deviceIndex: number = 0;
  @State operateIndex: number = 0;
  @State sensor: SensorData = AppService.getSensorData('default');
  private greenhouses: Greenhouse[] = AppService.getGreenhouses();
  private deviceNames: string[] = ['灯', '遮光板', '风扇', '水泵', '药泵'];
  private deviceIds: string[] = ['light_1', 'board_1', 'fan_1', 'water_pump_1', 'medicine_pump_1'];

  private currentGreenhouse(): Greenhouse {
    if (this.greenhouseIndex >= 0 && this.greenhouseIndex < this.greenhouses.length) {
      return this.greenhouses[this.greenhouseIndex];
    }
    return this.greenhouses[0];
  }

  private greenhouseNames(): string[] {
    const names: string[] = [];
    for (let i = 0; i < this.greenhouses.length; i++) {
      names.push(this.greenhouses[i].name);
    }
    return names;
  }

  private toSelectItems(values: string[]): SelectItem[] {
    const options: SelectItem[] = [];
    for (let i = 0; i < values.length; i++) {
      options.push({ value: values[i] });
    }
    return options;
  }

  private operateOptions(): string[] {
    const id = this.deviceIds[this.deviceIndex];
    if (id === 'fan_1') {
      return ['0档', '1档', '2档', '3档', '4档', '5档', '6档', '7档', '8档', '9档'];
    }
    return ['开启', '关闭'];
  }

  private statusText(): string {
    return `设备状态：
灯：${this.sensor.lightOn ? '开' : '关'}
遮光板：${this.sensor.boardOn ? '开' : '关'}
风扇：${this.sensor.fanGear}档
水泵：${this.sensor.waterPumpOn ? '开' : '关'}
药泵：${this.sensor.medicinePumpOn ? '开' : '关'}`;
  }

  private execute(): void {
    const greenhouseId = this.currentGreenhouse().id;
    const deviceId = this.deviceIds[this.deviceIndex];
    const operate = this.operateOptions()[this.operateIndex];
    if (!deviceId || !operate) {
      promptAction.showToast({ message: '请选择有效的设备和操作' });
      return;
    }

    if (deviceId === 'fan_1') {
      const gear = this.operateIndex;
      this.sensor = AppService.setFanGear(greenhouseId, gear);
      AppService.sendDeviceCommand(greenhouseId, 'Fengdegree', gear);
    } else {
      const enabled = operate === '开启';
      if (deviceId === 'light_1') {
        this.sensor = AppService.setDeviceStatus(greenhouseId, 'light', enabled);
        AppService.sendDeviceCommand(greenhouseId, 'Light', enabled ? 'ON' : 'OFF');
      } else if (deviceId === 'board_1') {
        this.sensor = AppService.setDeviceStatus(greenhouseId, 'board', enabled);
        AppService.sendDeviceCommand(greenhouseId, 'Board', enabled ? 'ON' : 'OFF');
      } else if (deviceId === 'water_pump_1') {
        this.sensor = AppService.setDeviceStatus(greenhouseId, 'water', enabled);
        AppService.sendDeviceCommand(greenhouseId, 'BUMP', enabled ? 'ON' : 'OFF');
      } else {
        this.sensor = AppService.setDeviceStatus(greenhouseId, 'medicine', enabled);
        AppService.sendDeviceCommand(greenhouseId, 'BUMP', enabled ? 'ON' : 'OFF');
      }
    }
    promptAction.showToast({ message: '命令已下发' });
  }

  @Builder
  SelectCard(label: string, values: string[], selected: number, type: string) {
    Row() {
      Text(`● ${label}`)
        .fontColor(AndroidColor.GREEN_PRIMARY)
        .fontWeight(FontWeight.Bold)
      Select(this.toSelectItems(values))
        .selected(selected)
        .value(values[selected])
        .layoutWeight(1)
        .height(48)
        .margin({ left: 12 })
        .onSelect((index: number) => {
          if (type === 'greenhouse') {
            this.greenhouseIndex = index;
            this.sensor = AppService.getSensorData(this.currentGreenhouse().id);
          } else if (type === 'device') {
            this.deviceIndex = index;
            this.operateIndex = 0;
          } else {
            this.operateIndex = index;
          }
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(24)
    .shadow({ radius: 4, color: '#22000000', offsetX: 0, offsetY: 2 })
    .margin({ bottom: 16 })
  }

  build() {
    Stack() {
      Circle()
        .width(411)
        .height(531)
        .fill(AndroidColor.GREEN_SOFT)
        .opacity(0.3)
        .position({ x: 80, y: -100 })

      Column() {
        Row() {
          Button('返回')
            .width(70)
            .height(38)
            .fontSize(13)
            .fontColor(Color.White)
            .backgroundColor('#8DAF83')
            .borderRadius(12)
            .margin({ left: 20 })
            .onClick(() => router.back())
          Text('设备调控')
            .layoutWeight(1)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
          Blank().width(90)
        }
        .height(100)
        .margin(16)
        .backgroundColor(AndroidColor.GREEN_SOFT)
        .borderRadius(32)
        .shadow({ radius: 12, color: '#33000000', offsetX: 0, offsetY: 4 })

        Scroll() {
          Column() {
            this.SelectCard('请选择大棚', this.greenhouseNames(), this.greenhouseIndex, 'greenhouse')
            this.SelectCard('请选择设备', this.deviceNames, this.deviceIndex, 'device')

            Column({ space: 8 }) {
              Text('当前运行状态')
                .fontSize(12)
                .fontColor('#8DAF83')
              Text(this.statusText())
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(AndroidColor.GREEN_LABEL)
                .width('100%')
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#F1F8F1')
            .borderRadius(24)
            .margin({ bottom: 16 })

            this.SelectCard('拟执行操作', this.operateOptions(), this.operateIndex, 'operate')
          }
          .padding(20)
        }
        .layoutWeight(1)

        Button('立即执行命令')
          .width('100%')
          .height(64)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .backgroundColor(AndroidColor.GREEN_SOFT)
          .borderRadius(20)
          .margin(24)
          .shadow({ radius: 8, color: '#33000000', offsetX: 0, offsetY: 3 })
          .onClick(() => this.execute())
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AndroidColor.PAGE_BG)
  }
}
