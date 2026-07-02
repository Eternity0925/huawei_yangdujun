import { promptAction, router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
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
  private static readonly LOG_DOMAIN: number = 0x0001;
  private static readonly LOG_TAG: string = 'GreenhouseCloud';
  @State selectedIndex: number = 0;
  @State sensorData: SensorData = AppService.emptyCloudSensorData();
  @State isLoadingAi: boolean = false;
  @State aiSuggestion: string = '';
  @State greenhouses: Greenhouse[] = AppService.getGreenhouses();
  private refreshTimer: number = -1;
  private stages: StageItem[] = [
    { name: '\u83cc\u4e1d\u751f\u957f\u671f', image: $r('app.media.deep_image_1') },
    { name: '\u50ac\u83c7\u671f', image: $r('app.media.deep_image_2') },
    { name: '\u539f\u57fa\u5f62\u6210\u671f', image: $r('app.media.deep_image_3') },
    { name: '\u51fa\u83c7\u7ba1\u7406\u671f', image: $r('app.media.deep_image_4') }
  ];

  aboutToAppear(): void {
    this.refreshSensor();
    this.refreshGreenhouses();
    if (this.refreshTimer < 0) {
      this.refreshTimer = setInterval(() => {
        this.refreshSensor();
      }, 5000);
    }
  }

  aboutToDisappear(): void {
    if (this.refreshTimer >= 0) {
      clearInterval(this.refreshTimer);
      this.refreshTimer = -1;
    }
  }

  private currentGreenhouse(): Greenhouse {
    if (this.selectedIndex >= 0 && this.selectedIndex < this.greenhouses.length) {
      return this.greenhouses[this.selectedIndex];
    }
    if (this.greenhouses.length > 0) {
      return this.greenhouses[0];
    }
    return {
      id: '1',
      name: 'A01 \u7f8a\u809a\u83cc\u667a\u80fd\u5927\u68da',
      location: '',
      area: '',
      stage: ''
    };
  }

  private refreshSensor(): void {
    AppService.refreshSensorFromBackend(this.currentGreenhouse().id).then((data: SensorData) => {
      hilog.info(GreenhouseHomePage.LOG_DOMAIN, GreenhouseHomePage.LOG_TAG,
        'home assign Temp=%{public}f Humi=%{public}f Lumi=%{public}f SoilHumi=%{public}f CO2=%{public}f',
        data.airTemperature, data.airHumidity, data.light, data.soilHumidity, data.co2);
      this.sensorData = data;
    }).catch((err: Error) => {
      hilog.error(GreenhouseHomePage.LOG_DOMAIN, GreenhouseHomePage.LOG_TAG,
        'home refresh failed: %{public}s', JSON.stringify(err));
    });
  }

  private refreshGreenhouses(): void {
    AppService.refreshGreenhousesFromDatabase().then((items: Greenhouse[]) => {
      if (items.length === 0) {
        this.refreshSensor();
        return;
      }
      this.greenhouses = items;
      if (this.selectedIndex >= this.greenhouses.length) {
        this.selectedIndex = 0;
      }
      this.refreshSensor();
    }).catch(() => {
      this.refreshSensor();
    });
  }

  private async setSwitch(key: string, value: boolean, commandName: string): Promise<void> {
    if (key === 'medicine') {
      promptAction.showToast({ message: '药泵暂不支持控制，仅显示状态' });
      return;
    }
    if (!AppService.canSendCloudCommand(this.currentGreenhouse().id)) {
      promptAction.showToast({ message: '\u53ea\u6709\u4e00\u53f7\u5927\u68da\u652f\u6301\u4e91\u7aef\u547d\u4ee4\u4e0b\u53d1' });
      this.refreshSensor();
      return;
    }
    const success = await AppService.sendDeviceCommand(this.currentGreenhouse().id, commandName, value ? 'ON' : 'OFF');
    if (success) {
      this.sensorData = AppService.setDeviceStatus(this.currentGreenhouse().id, key, value);
      promptAction.showToast({ message: value ? '\u5df2\u5f00\u542f' : '\u5df2\u5173\u95ed' });
      this.refreshSensor();
    } else {
      promptAction.showToast({ message: '\u547d\u4ee4\u4e0b\u53d1\u5931\u8d25\uff0c\u8bbe\u5907\u53ef\u80fd\u4e0d\u5728\u7ebf' });
      this.refreshSensor();
    }
  }

  private async changeFan(delta: number): Promise<void> {
    if (!AppService.canSendCloudCommand(this.currentGreenhouse().id)) {
      promptAction.showToast({ message: '\u53ea\u6709\u4e00\u53f7\u5927\u68da\u652f\u6301\u4e91\u7aef\u547d\u4ee4\u4e0b\u53d1' });
      this.refreshSensor();
      return;
    }
    const nextGear = Math.max(0, Math.min(9, this.sensorData.fanGear + delta));
    const success = await AppService.sendDeviceCommand(this.currentGreenhouse().id, 'Fengd', nextGear);
    if (success) {
      this.sensorData = AppService.setFanGear(this.currentGreenhouse().id, nextGear);
      promptAction.showToast({
        message: this.sensorData.fanGear === 0 ? '\u98ce\u673a\u5df2\u5173\u95ed' : `\u98ce\u901f\u8c03\u81f3${this.sensorData.fanGear}\u6863`
      });
      this.refreshSensor();
    } else {
      promptAction.showToast({ message: '\u98ce\u673a\u547d\u4ee4\u4e0b\u53d1\u5931\u8d25\uff0c\u8bbe\u5907\u53ef\u80fd\u4e0d\u5728\u7ebf' });
      this.refreshSensor();
    }
  }

  private async requestAiSuggestion(): Promise<void> {
    if (this.isLoadingAi) {
      promptAction.showToast({ message: '\u6b63\u5728\u83b7\u53d6 AI \u5efa\u8bae\uff0c\u8bf7\u7a0d\u5019' });
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
    if (this.sensorData.growthStage <= 0) {
      return '--';
    }
    const stage = Math.max(1, Math.min(4, this.sensorData.growthStage));
    return this.stages[stage - 1].name;
  }

  private sensorItems(): SensorCardItem[] {
    return [
      { title: '\u7a7a\u6c14\u6e29\u5ea6(\u2103)', value: this.cloudValue(this.sensorData.airTemperature), image: $r('app.media.sun_temp') },
      { title: '\u7a7a\u6c14\u6e7f\u5ea6(RH%)', value: this.cloudValue(this.sensorData.airHumidity), image: $r('app.media.o_water') },
      { title: '\u5149\u7167\u5f3a\u5ea6(lux)', value: this.cloudValue(this.sensorData.light), image: $r('app.media.sun') },
      { title: '\u8ddd\u79bb(cm)', value: this.cloudValue(this.sensorData.distance), image: $r('app.media.jun_temp') },
      { title: '\u571f\u58e4\u6e29\u5ea6(\u2103)', value: this.cloudValue(this.sensorData.soilTemperature), image: $r('app.media.jun_temp') },
      { title: '\u571f\u58e4\u6e7f\u5ea6(RH%)', value: this.cloudValue(this.sensorData.soilHumidity), image: $r('app.media.jun_water') },
      { title: 'CO2(ppm)', value: this.cloudValue(this.sensorData.co2), image: $r('app.media.co2') },
      { title: 'pH', value: this.cloudValue(this.sensorData.ph), image: $r('app.media.ph') }
    ];
  }

  private cloudValue(value: number): string {
    return value < 0 ? '--' : `${value}`;
  }

  private gearValue(value: number): string {
    return value < 0 ? '--' : value + ' \u6863';
  }

  private switchStatus(value: boolean): string {
    return value ? '\u5f00\u542f' : '\u5173\u95ed';
  }

  private textValue(value: string): string {
    return value && value.length > 0 ? value : '--';
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
        .width(112)
      Column({ space: 2 }) {
        Text(this.switchStatus(enabled))
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(enabled ? AndroidColor.GREEN_MAIN : '#667085')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
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
      AndroidTopBar({ title: '\u5927\u68da' })
      Scroll() {
        Column() {
          Column() {
            Row() {
              Text('\u8bf7\u9009\u62e9\u5927\u68da')
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
            this.SectionTitle('\u751f\u957f\u9636\u6bb5')
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
              Text('AI\u9884\u8b66\uff1a' + this.textValue(this.sensorData.aiWarning))
                .fontSize(14)
                .fontColor('#5A713F')
            }
            .width('100%')

            Text('\u66f4\u65b0\u65f6\u95f4\uff1a' + this.sensorData.updatedAt)
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
            this.SectionTitle('\u5b9e\u65f6\u73af\u5883\u6570\u636e')
            Grid() {
              ForEach(this.sensorItems(), (item: SensorCardItem) => {
                GridItem() {
                  this.SensorCard(item)
                }
              }, (item: SensorCardItem) => `${item.title}-${item.value}`)
            }
            .columnsTemplate('1fr 1fr')
            .columnsGap(10)
            .rowsGap(10)
            .height(492)
          }
          .padding(10)
          .backgroundColor(AndroidColor.SECTION_BG)
          .borderRadius(14)
          .margin({ bottom: 12 })

          Column({ space: 10 }) {
            this.SectionTitle('AI \u79cd\u690d\u5efa\u8bae')
            Text('\u6839\u636e\u5f53\u524d\u5927\u68da\u73af\u5883\u6570\u636e\u751f\u6210\u79cd\u690d\u5efa\u8bae')
              .fontSize(14)
              .fontColor('#5A713F')
            Button(this.isLoadingAi ? '\u6b63\u5728\u751f\u6210...' : '\u83b7\u53d6 AI \u5efa\u8bae')
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
            this.SectionTitle('\u89c6\u9891\u76d1\u63a7')
            Scroll() {
              Row({ space: 10 }) {
                this.VideoCell($r('app.media.mogu1'), '\u5927\u68da1\u53f7\u89c6\u9891')
                this.VideoCell($r('app.media.mogu2'), '\u5927\u68da2\u53f7\u89c6\u9891')
                this.VideoCell($r('app.media.mogu3'), '\u5927\u68da3\u53f7\u89c6\u9891')
                this.VideoCell($r('app.media.mogu4'), '\u5927\u68da4\u53f7\u89c6\u9891')
                this.VideoCell($r('app.media.mogu6'), '\u5927\u68da5\u53f7\u89c6\u9891')
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
            this.SectionTitle('\u8bbe\u5907\u72b6\u6001')
            this.DeviceRow('\u6321\u5149\u677f\u72b6\u6001', 'board', 'DangGuangBan', this.sensorData.boardOn)
            this.DeviceRow('\u836f\u6cf5\u72b6\u6001', 'medicine', 'BUMP', this.sensorData.medicinePumpOn)
            this.DeviceRow('\u6c34\u6cf5\u72b6\u6001', 'water', 'BUMP', this.sensorData.waterPumpOn)
            this.DeviceRow('\u706f\u6ce1\u72b6\u6001', 'light', 'LightSt', this.sensorData.lightOn)

            Row() {
              Text('\u98ce\u673a\u6863\u4f4d')
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#141E17')
                .width(112)
              Column({ space: 2 }) {
                Text(this.gearValue(this.sensorData.fanGear))
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.sensorData.fanGear > 0 ? AndroidColor.GREEN_MAIN : '#141E17')
              }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              Button('\u8c03\u9ad8')
                .width(56)
                .height(32)
                .fontSize(12)
                .fontColor(Color.White)
                .backgroundColor(AndroidColor.GREEN_MAIN)
                .borderRadius(16)
                .margin({ right: 8 })
                .onClick(() => this.changeFan(1))
              Button('\u8c03\u4f4e')
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
