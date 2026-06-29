import { promptAction, router } from '@kit.ArkUI';
import { AndroidBottomNav, AndroidTopBar } from '../common/AndroidWidgets';
import { AndroidColor } from '../common/AndroidStyle';
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

interface StageItem {
  name: string;
  image: Resource;
}

@Entry
@Component
struct GreenhouseHomePage {
  @State selectedIndex: number = 0;
  @State sensorData: SensorData = AppService.getSensorData('default');
  @State isLoadingAi: boolean = false;
  @State aiSuggestion: string = '';
  private greenhouses: Greenhouse[] = AppService.getGreenhouses();
  private stages: StageItem[] = [
    { name: '菌丝生长期', image: $r('app.media.deep_image_1') },
    { name: '催菇期', image: $r('app.media.deep_image_2') },
    { name: '原基形成期', image: $r('app.media.deep_image_3') },
    { name: '出菇管理期', image: $r('app.media.deep_image_4') }
  ];

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
    promptAction.showToast({ message: this.sensorData.fanGear === 0 ? '风机已关闭' : `风速调至${this.sensorData.fanGear}档` });
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
    return this.stages[stage - 1].name;
  }

  private sensorItems(): SensorCardItem[] {
    return [
      { title: '土壤温度(℃)', value: `${this.sensorData.soilTemperature}`, image: $r('app.media.jun_temp') },
      { title: '空气温度(℃)', value: `${this.sensorData.airTemperature}`, image: $r('app.media.sun_temp') },
      { title: '土壤湿度(RH%)', value: `${this.sensorData.soilHumidity}`, image: $r('app.media.jun_water') },
      { title: '空气湿度(RH%)', value: `${this.sensorData.airHumidity}`, image: $r('app.media.o_water') },
      { title: '光照强度(lux)', value: `${this.sensorData.light}`, image: $r('app.media.sun') },
      { title: 'CO2(ppm)', value: `${this.sensorData.co2}`, image: $r('app.media.co2') },
      { title: 'pH', value: `${this.sensorData.ph}`, image: $r('app.media.ph') }
    ];
  }

  @Builder
  SensorCard(item: SensorCardItem) {
    Column({ space: 3 }) {
      Image(item.image)
        .width(48)
        .height(48)
        .objectFit(ImageFit.Contain)
      Text(item.title)
        .fontSize(13)
        .fontColor(Color.Black)
        .textAlign(TextAlign.Center)
      Text(item.value)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F2937')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(116)
    .padding(6)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#E9F2E9')
    .borderRadius(14)
  }

  @Builder
  StageCell(item: StageItem, index: number) {
    Column({ space: 6 }) {
      Image(item.image)
        .width(58)
        .height(58)
        .objectFit(ImageFit.Cover)
        .borderRadius(29)
        .opacity(index + 1 === this.sensorData.growthStage ? 1 : 0.32)
      Text(item.name)
        .fontSize(11)
        .fontWeight(index + 1 === this.sensorData.growthStage ? FontWeight.Bold : FontWeight.Regular)
        .fontColor(index + 1 === this.sensorData.growthStage ? '#238B45' : '#8AA08E')
        .maxLines(1)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  DeviceRow(label: string, key: string, commandName: string, enabled: boolean) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#141E17')
      Blank()
      Toggle({ type: ToggleType.Switch, isOn: enabled })
        .selectedColor(AndroidColor.GREEN_MAIN)
        .onChange((value: boolean) => this.setSwitch(key, value, commandName))
    }
    .height(46)
    .width('100%')
  }

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .fontSize(19)
      .fontWeight(FontWeight.Bold)
      .fontColor(AndroidColor.GREEN_SECTION_TITLE)
      .width('100%')
      .margin({ bottom: 8 })
  }

  @Builder
  VideoCell(image: Resource, label: string) {
    Column({ space: 6 }) {
      Image(image)
        .width('100%')
        .height(82)
        .objectFit(ImageFit.Cover)
        .borderRadius(12)
        .onClick(() => router.pushUrl({ url: AppRoutes.VIDEO, params: { title: label } }))
      Text(label)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#5A713F')
    }
    .width(148)
    .height(118)
    .padding(6)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.White)
    .borderRadius(14)
  }

  build() {
    Column() {
      AndroidTopBar({ title: '大棚' })
      Scroll() {
        Column() {
          Column() {
            Row() {
              Text('请选择大棚')
                .fontColor(AndroidColor.GREEN_PRIMARY)
                .fontWeight(FontWeight.Bold)
              Select(this.greenhouseOptions())
                .selected(this.selectedIndex)
                .value(this.currentGreenhouse().name)
                .layoutWeight(1)
                .height(44)
                .margin({ left: 12 })
                .onSelect((index: number) => {
                  this.selectedIndex = index;
                  this.refreshSensor();
                })
            }
            .width('100%')
            .height(64)
            .padding(14)
          }
          .width('100%')
          .backgroundColor(Color.White)
          .borderRadius(14)
          .margin({ bottom: 12 })

          Column({ space: 10 }) {
            this.SectionTitle('生长阶段')
            Row({ space: 6 }) {
              ForEach(this.stages, (item: StageItem, index: number) => {
                this.StageCell(item, index)
              }, (item: StageItem) => item.name)
            }
            .width('100%')

            Row() {
              Text(this.stageName())
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#238B45')
              Blank()
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
          .borderRadius(14)
          .margin({ bottom: 12 })

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
            .columnsGap(10)
            .rowsGap(10)
            .height(366)
          }
          .padding(10)
          .backgroundColor(AndroidColor.SECTION_BG)
          .borderRadius(14)
          .margin({ bottom: 12 })

          Column({ space: 10 }) {
            this.SectionTitle('AI 智能建议')
            Text('根据当前大棚环境数据生成种植建议')
              .fontSize(14)
              .fontColor('#5A713F')
            Button(this.isLoadingAi ? '正在获取...' : '获取AI建议')
              .width('100%')
              .height(44)
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
                .borderRadius(12)
            }
          }
          .width('100%')
          .padding(12)
          .backgroundColor(AndroidColor.SECTION_BG)
          .borderRadius(14)
          .margin({ bottom: 12 })

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
            .height(126)
          }
          .width('100%')
          .padding(12)
          .backgroundColor(AndroidColor.SECTION_BG)
          .borderRadius(14)
          .margin({ bottom: 12 })

          Column() {
            this.SectionTitle('设备状态')
            this.DeviceRow('挡光板状态', 'board', 'DangGuangBan', this.sensorData.boardOn)
            this.DeviceRow('药泵状态', 'medicine', 'BUMP', this.sensorData.medicinePumpOn)
            this.DeviceRow('水泵状态', 'water', 'BUMP', this.sensorData.waterPumpOn)
            this.DeviceRow('灯泡状态', 'light', 'LightSt', this.sensorData.lightOn)

            Row() {
              Text('风扇档位')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#141E17')
              Text(`${this.sensorData.fanGear} 档`)
                .layoutWeight(1)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#141E17')
                .textAlign(TextAlign.Center)
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
                .onClick(() => this.changeFan(-1))
            }
            .height(46)
            .width('100%')
          }
          .width('100%')
          .padding(12)
          .backgroundColor(AndroidColor.SECTION_BG)
          .borderRadius(14)
          .margin({ bottom: 12 })
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
