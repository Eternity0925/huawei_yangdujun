import { promptAction, router } from '@kit.ArkUI';
import { AndroidBottomNav, AndroidTopBar } from '../common/AndroidWidgets';
import { AndroidColor, AndroidDimen } from '../common/AndroidStyle';
import { AppRoutes } from '../common/AppRoutes';
import { Greenhouse, SensorData } from '../models/AppModels';
import { AppService } from '../services/AppService';

interface SensorCardItem {
  title: string;
  value: string;
  image: Resource;
}

interface SelectItem {
  value: string;
}

@Entry
@Component
struct GreenhouseHomePage {
  @State selectedIndex: number = 0;
  @State sensorData: SensorData = AppService.getSensorData('default');
  @State isLoadingAi: boolean = false;
  @State aiSuggestion: string = '';
  private greenhouses: Greenhouse[] = AppService.getGreenhouses();

  aboutToAppear(): void {
    this.refreshSensor();
  }

  private currentGreenhouse(): Greenhouse {
    if (this.selectedIndex >= 0 && this.selectedIndex < this.greenhouses.length) {
      return this.greenhouses[this.selectedIndex];
    }
    return this.greenhouses[0];
  }

  private refreshSensor(): void {
    this.sensorData = AppService.getSensorData(this.currentGreenhouse().id);
    AppService.refreshSensorFromBackend(this.currentGreenhouse().id).then((data: SensorData) => {
      this.sensorData = data;
    });
  }

  private async setSwitch(key: string, value: boolean, commandName: string): Promise<void> {
    this.sensorData = AppService.setDeviceStatus(this.currentGreenhouse().id, key, value);
    const success = await AppService.sendDeviceCommand(this.currentGreenhouse().id, commandName, value ? 'ON' : 'OFF');
    promptAction.showToast({ message: success ? (value ? '已开启' : '已关闭') : '命令下发失败' });
  }

  private async changeFan(delta: number): Promise<void> {
    this.sensorData = AppService.setFanGear(this.currentGreenhouse().id, this.sensorData.fanGear + delta);
    await AppService.sendDeviceCommand(this.currentGreenhouse().id, 'Fengd', this.sensorData.fanGear);
    promptAction.showToast({ message: this.sensorData.fanGear === 0 ? '风机已关闭' : `风速调至 ${this.sensorData.fanGear} 档` });
  }

  private async requestAiSuggestion(): Promise<void> {
    if (this.isLoadingAi) {
      promptAction.showToast({ message: '正在获取 AI 建议，请稍候' });
      return;
    }
    this.isLoadingAi = true;
    try {
      this.aiSuggestion = await AppService.requestAiSuggestion(this.currentGreenhouse(), this.sensorData);
    } finally {
      this.isLoadingAi = false;
    }
  }

  private greenhouseOptions(): SelectItem[] {
    const options: SelectItem[] = [];
    for (let i = 0; i < this.greenhouses.length; i++) {
      options.push({ value: this.greenhouses[i].name });
    }
    return options;
  }

  private stageName(): string {
    const stage = Math.max(1, Math.min(4, this.sensorData.growthStage));
    if (stage === 1) {
      return '菌丝生长期';
    }
    if (stage === 2) {
      return '催菇期';
    }
    if (stage === 3) {
      return '原基形成期';
    }
    return '出菇管理期';
  }

  private sensorItems(): SensorCardItem[] {
    return [
      { title: '土壤温度(℃)', value: `${this.sensorData.soilTemperature}`, image: $r('app.media.jun_temp') },
      { title: '空气温度(℃)', value: `${this.sensorData.airTemperature}`, image: $r('app.media.sun_temp') },
      { title: '土壤湿度(RH%)', value: `${this.sensorData.soilHumidity}`, image: $r('app.media.jun_water') },
      { title: '空气湿度(RH%)', value: `${this.sensorData.airHumidity}`, image: $r('app.media.o_water') },
      { title: '光照强度(lux)', value: `${this.sensorData.light}`, image: $r('app.media.sun') },
      { title: 'CO2(ppm)', value: `${this.sensorData.co2}`, image: $r('app.media.co2') },
      { title: 'O2(%)', value: `${this.sensorData.o2}`, image: $r('app.media.o2') },
      { title: 'pH', value: `${this.sensorData.ph}`, image: $r('app.media.ph') }
    ];
  }

  @Builder
  SensorCard(item: SensorCardItem) {
    Column({ space: 4 }) {
      Image(item.image)
        .width(58)
        .height(58)
        .objectFit(ImageFit.Contain)
      Text(item.title)
        .fontSize(14)
        .fontColor(Color.Black)
        .textAlign(TextAlign.Center)
      Text(item.value)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F2937')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(132)
    .padding(AndroidDimen.PAD_5)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#E9F2E9')
    .borderRadius(24)
    .shadow({ radius: 4, color: '#22000000', offsetX: 0, offsetY: 2 })
  }

  @Builder
  DeviceRow(label: string, value: string, key: string, commandName: string, enabled: boolean) {
    Row() {
      Text(`   ${label}：`)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#141E17')
      Text(value)
        .layoutWeight(1)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#141E17')
      Button(enabled ? '关' : '开')
        .width(80)
        .height(32)
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor(AndroidColor.GREEN_MAIN)
        .borderRadius(16)
        .margin({ right: 16 })
        .onClick(() => this.setSwitch(key, !enabled, commandName))
    }
    .height(48)
    .width('100%')
  }

  @Builder
  SectionTitle(title: string) {
    Text(` ${title}`)
      .fontSize(20)
      .fontWeight(FontWeight.Bold)
      .fontColor(AndroidColor.GREEN_SECTION_TITLE)
      .width('100%')
      .margin({ bottom: 8 })
  }

  @Builder
  VideoCell(image: Resource, label: string) {
    Column({ space: 5 }) {
      Button()
        .width('100%')
        .height(80)
        .backgroundColor(Color.Transparent)
        .backgroundImage(image)
        .backgroundImageSize(ImageSize.Cover)
        .onClick(() => router.pushUrl({ url: AppRoutes.VIDEO, params: { title: label } }))
      Text(label)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#5A713F')
    }
    .width(150)
    .height(120)
    .padding(8)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(AndroidColor.SECTION_BG)
  }

  build() {
    Column() {
      AndroidTopBar({ title: '大棚' })
      Scroll() {
        Column() {
          Column() {
            Row() {
              Text('● 请选择大棚')
                .fontColor(AndroidColor.GREEN_PRIMARY)
                .fontWeight(FontWeight.Bold)
              Select(this.greenhouseOptions())
                .selected(this.selectedIndex)
                .value(this.currentGreenhouse().name)
                .layoutWeight(1)
                .height(48)
                .margin({ left: 12 })
                .onSelect((index: number) => {
                  this.selectedIndex = index;
                  this.refreshSensor();
                })
            }
            .width('100%')
            .height(72)
            .padding(16)
          }
          .width('100%')
          .backgroundColor(Color.White)
          .borderRadius(24)
          .shadow({ radius: 4, color: '#22000000', offsetX: 0, offsetY: 2 })
          .margin({ bottom: 16 })

          Column({ space: 8 }) {
            this.SectionTitle('生长阶段')
            Row({ space: 8 }) {
              Text(this.stageName())
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#238B45')
              Text(`AI预警：${this.sensorData.aiWarning}`)
                .fontSize(14)
                .fontColor('#5A713F')
            }
            .width('100%')
            Text(`更新时间：${this.sensorData.updatedAt}`)
              .fontSize(13)
              .fontColor('#667085')
              .width('100%')
          }
          .width('100%')
          .padding(12)
          .backgroundColor(AndroidColor.SECTION_BG)
          .borderRadius(24)
          .shadow({ radius: 4, color: '#22000000', offsetX: 0, offsetY: 2 })
          .margin({ bottom: 16 })

          Column() {
            this.SectionTitle('实时环境数据')
            Grid() {
              ForEach(this.sensorItems(), (item: SensorCardItem) => {
                GridItem() {
                  this.SensorCard(item)
                }
              }, (item: SensorCardItem) => item.title)
            }
            .columnsTemplate('1fr 1fr')
            .columnsGap(12)
            .rowsGap(16)
            .height(576)
          }
          .padding(8)
          .backgroundColor(AndroidColor.SECTION_BG)
          .borderRadius(24)
          .shadow({ radius: 4, color: '#22000000', offsetX: 0, offsetY: 2 })
          .margin({ bottom: 16 })

          Column({ space: 10 }) {
            this.SectionTitle('AI 智能建议')
            Text('根据当前大棚环境数据生成种植建议')
              .fontSize(14)
              .fontColor('#5A713F')
            Button(this.isLoadingAi ? '正在获取...' : '获取AI建议')
              .width('100%')
              .height(45)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .backgroundColor(AndroidColor.GREEN_MAIN)
              .borderRadius(22)
              .onClick(() => this.requestAiSuggestion())
            if (this.aiSuggestion.length > 0) {
              Text(this.aiSuggestion)
                .fontSize(14)
                .fontColor('#1F2937')
                .lineHeight(22)
                .width('100%')
                .padding(12)
                .backgroundColor(Color.White)
                .borderRadius(8)
            }
          }
          .width('100%')
          .padding(12)
          .backgroundColor(AndroidColor.SECTION_BG)
          .borderRadius(24)
          .shadow({ radius: 4, color: '#22000000', offsetX: 0, offsetY: 2 })
          .margin({ bottom: 16 })

          Column() {
            this.SectionTitle('视频监控')
            Scroll() {
              Row({ space: 10 }) {
                this.VideoCell($r('app.media.mogu1'), '大棚1号视频')
                this.VideoCell($r('app.media.mogu2'), '大棚2号视频')
                this.VideoCell($r('app.media.mogu3'), '大棚3号视频')
                this.VideoCell($r('app.media.mogu4'), '大棚4号视频')
                this.VideoCell($r('app.media.mogu6'), '大棚5号视频')
              }
            }
            .scrollable(ScrollDirection.Horizontal)
            .height(130)
          }
          .width('100%')
          .padding(12)
          .backgroundColor(AndroidColor.SECTION_BG)
          .borderRadius(24)
          .shadow({ radius: 4, color: '#22000000', offsetX: 0, offsetY: 2 })
          .margin({ bottom: 16 })

          Column() {
            this.SectionTitle('设备状态')
            this.DeviceRow('挡光板状态', this.sensorData.boardOn ? 'ON' : 'OFF', 'board', 'DangGuangBan', this.sensorData.boardOn)
            this.DeviceRow('药泵状态', this.sensorData.medicinePumpOn ? 'ON' : 'OFF', 'medicine', 'BUMP', this.sensorData.medicinePumpOn)
            this.DeviceRow('水泵状态', this.sensorData.waterPumpOn ? 'ON' : 'OFF', 'water', 'BUMP', this.sensorData.waterPumpOn)
            this.DeviceRow('灯泡状态', this.sensorData.lightOn ? 'ON' : 'OFF', 'light', 'LightSt', this.sensorData.lightOn)

            Row() {
              Text('   风扇档位：')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#141E17')
              Text(`${this.sensorData.fanGear}`)
                .layoutWeight(1)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#141E17')
              Button('调高')
                .width(56)
                .height(32)
                .fontSize(12)
                .fontColor(Color.White)
                .backgroundColor(AndroidColor.GREEN_MAIN)
                .borderRadius(16)
                .margin({ right: 8 })
                .onClick(() => this.changeFan(1))
              Button('调低')
                .width(56)
                .height(32)
                .fontSize(12)
                .fontColor(Color.White)
                .backgroundColor(AndroidColor.GREEN_MAIN)
                .borderRadius(16)
                .margin({ right: 16 })
                .onClick(() => this.changeFan(-1))
            }
            .height(48)
            .width('100%')
          }
          .width('100%')
          .padding(12)
          .backgroundColor(AndroidColor.SECTION_BG)
          .borderRadius(24)
          .shadow({ radius: 4, color: '#22000000', offsetX: 0, offsetY: 2 })
          .margin({ bottom: 16 })
        }
        .padding({ left: 12, right: 12 })
      }
      .layoutWeight(1)
      .backgroundColor(AndroidColor.PAGE_BG)
      AndroidBottomNav({ active: 'greenhouse' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AndroidColor.PAGE_BG)
  }
}
