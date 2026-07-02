import { promptAction } from '@kit.ArkUI';
import { AndroidBackTopBar } from '../common/AndroidWidgets';
import { Greenhouse, ThresholdConfig } from '../models/AppModels';
import { AppService } from '../services/AppService';

interface SelectItem {
  value: string;
}

interface ThresholdItem {
  key: string;
  title: string;
  min: number;
  max: number;
  unit: string;
}

@Entry
@Component
struct AlarmThresholdPage {
  @State selectedIndex: number = 0;
  @State threshold: ThresholdConfig = AppService.getThreshold('default');
  @State greenhouses: Greenhouse[] = AppService.getGreenhouses();

  aboutToAppear(): void {
    AppService.refreshGreenhousesFromDatabase().then((items: Greenhouse[]) => {
      this.greenhouses = items;
      if (this.selectedIndex >= this.greenhouses.length) {
        this.selectedIndex = 0;
      }
      this.reloadThreshold();
    }).catch(() => {
      this.reloadThreshold();
    });
  }

  private currentGreenhouse(): Greenhouse {
    return this.greenhouses[this.selectedIndex] || this.greenhouses[0];
  }

  private greenhouseOptions(): SelectItem[] {
    const options: SelectItem[] = [];
    for (let i = 0; i < this.greenhouses.length; i++) {
      options.push({ value: this.greenhouses[i].name });
    }
    return options;
  }

  private reloadThreshold(): void {
    this.threshold = AppService.getThreshold(this.currentGreenhouse().id);
    AppService.refreshThresholdFromDatabase(this.currentGreenhouse().id).then((data: ThresholdConfig) => {
      this.threshold = data;
    }).catch(() => {
    });
  }

  private async saveThreshold(): Promise<void> {
    const ok = await AppService.updateThreshold(this.currentGreenhouse().id, this.threshold);
    promptAction.showToast({ message: ok ? '阈值已保存到数据库' : '保存失败，请检查后端连接' });
    if (ok) {
      this.reloadThreshold();
    }
  }

  private items(): ThresholdItem[] {
    return [
      { key: 'temp', title: '空气温度', min: this.threshold.tempMin, max: this.threshold.tempMax, unit: '℃' },
      { key: 'airHum', title: '空气湿度', min: this.threshold.airHumMin, max: this.threshold.airHumMax, unit: '%' },
      { key: 'soilTemp', title: '土壤温度', min: this.threshold.soilTempMin, max: this.threshold.soilTempMax, unit: '℃' },
      { key: 'soilHum', title: '土壤湿度', min: this.threshold.humMin, max: this.threshold.humMax, unit: '%' },
      { key: 'co2', title: '二氧化碳浓度', min: this.threshold.co2Min, max: this.threshold.co2Max, unit: 'ppm' },
      { key: 'ph', title: 'PH值', min: this.threshold.phMin, max: this.threshold.phMax, unit: '' },
      { key: 'light', title: '光照强度', min: this.threshold.lightMin, max: this.threshold.lightMax, unit: 'lux' }
    ];
  }

  private copyThreshold(): ThresholdConfig {
    return {
      tempMin: this.threshold.tempMin,
      tempMax: this.threshold.tempMax,
      airHumMin: this.threshold.airHumMin,
      airHumMax: this.threshold.airHumMax,
      soilTempMin: this.threshold.soilTempMin,
      soilTempMax: this.threshold.soilTempMax,
      humMin: this.threshold.humMin,
      humMax: this.threshold.humMax,
      co2Min: this.threshold.co2Min,
      co2Max: this.threshold.co2Max,
      o2Min: this.threshold.o2Min,
      o2Max: this.threshold.o2Max,
      phMin: this.threshold.phMin,
      phMax: this.threshold.phMax,
      lightMin: this.threshold.lightMin,
      lightMax: this.threshold.lightMax
    };
  }

  private changeValue(key: string, isMin: boolean, delta: number): void {
    const t = this.copyThreshold();
    if (key === 'temp') {
      if (isMin) {
        t.tempMin += delta;
      } else {
        t.tempMax += delta;
      }
    } else if (key === 'airHum') {
      if (isMin) {
        t.airHumMin += delta;
      } else {
        t.airHumMax += delta;
      }
    } else if (key === 'soilTemp') {
      if (isMin) {
        t.soilTempMin += delta;
      } else {
        t.soilTempMax += delta;
      }
    } else if (key === 'soilHum') {
      if (isMin) {
        t.humMin += delta;
      } else {
        t.humMax += delta;
      }
    } else if (key === 'co2') {
      if (isMin) {
        t.co2Min += delta;
      } else {
        t.co2Max += delta;
      }
    } else if (key === 'ph') {
      if (isMin) {
        t.phMin += delta;
      } else {
        t.phMax += delta;
      }
    } else {
      if (isMin) {
        t.lightMin += delta;
      } else {
        t.lightMax += delta;
      }
    }
    this.threshold = t;
  }

  @Builder
  ThresholdRow(item: ThresholdItem) {
    Column({ space: 10 }) {
      Row() {
        Text(item.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F2937')
        Blank()
        Text(`${item.min}${item.unit} - ${item.max}${item.unit}`)
          .fontSize(15)
          .fontColor('#238B45')
      }
      .width('100%')

      Row({ space: 8 }) {
        Button('下限-')
          .height(32)
          .backgroundColor('#E5E7EB')
          .fontColor('#1F2937')
          .onClick(() => this.changeValue(item.key, true, -1))
        Button('下限+')
          .height(32)
          .backgroundColor('#E5E7EB')
          .fontColor('#1F2937')
          .onClick(() => this.changeValue(item.key, true, 1))
        Button('上限-')
          .height(32)
          .backgroundColor('#E5E7EB')
          .fontColor('#1F2937')
          .onClick(() => this.changeValue(item.key, false, -1))
        Button('上限+')
          .height(32)
          .backgroundColor('#E5E7EB')
          .fontColor('#1F2937')
          .onClick(() => this.changeValue(item.key, false, 1))
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
  }

  build() {
    Column({ space: 12 }) {
      AndroidBackTopBar({ title: '阈值设置' })

      Select(this.greenhouseOptions())
        .selected(this.selectedIndex)
        .value(this.currentGreenhouse().name)
        .height(48)
        .width('100%')
        .onSelect((index: number) => {
          this.selectedIndex = index;
          this.reloadThreshold();
        })

      Scroll() {
        Column({ space: 12 }) {
          ForEach(this.items(), (item: ThresholdItem) => {
            this.ThresholdRow(item)
          }, (item: ThresholdItem) => item.key)
          Button('保存阈值')
            .width('100%')
            .height(46)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .backgroundColor('#238B45')
            .borderRadius(23)
            .onClick(() => this.saveThreshold())
        }
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 10 })
    .backgroundColor('#E9F2E6')
  }
}
