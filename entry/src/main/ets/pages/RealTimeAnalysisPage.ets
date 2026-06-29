import { router } from '@kit.ArkUI';
import webview from '@ohos.web.webview';
import { Greenhouse, SensorData } from '../models/AppModels';
import { AppService } from '../services/AppService';

interface SelectItem {
  value: string;
}

interface HourPoint {
  label: string;
  airTemp: number;
  airHum: number;
  soilTemp: number;
  soilHum: number;
  light: number;
  co2: number;
  ph: number;
}

interface WebSeries {
  name: string;
  color: string;
  data: number[];
}

interface WebChart {
  title: string;
  type: string;
  badge: string;
  labels: string[];
  min: number;
  max: number;
  series: WebSeries[];
}

interface WebChartPayload {
  charts: WebChart[];
}

@Entry
@Component
struct RealTimeAnalysisPage {
  @State selectedIndex: number = 0;
  private controller: webview.WebviewController = new webview.WebviewController();
  private greenhouses: Greenhouse[] = AppService.getGreenhouses();

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

  private chartData(): HourPoint[] {
    const base: SensorData = AppService.getSensorData(this.currentGreenhouse().id);
    const data: HourPoint[] = [];
    for (let i = 23; i >= 0; i--) {
      const hour = (24 - i) % 24;
      const wave = (24 - i) % 6;
      data.push({
        label: `${hour < 10 ? '0' + hour : hour}时`,
        airTemp: Number((base.airTemperature + wave * 0.28 - 0.7).toFixed(1)),
        airHum: Math.round(base.airHumidity + wave - 3),
        soilTemp: Number((base.soilTemperature + wave * 0.18 - 0.4).toFixed(1)),
        soilHum: Math.round(base.soilHumidity + wave - 3),
        light: Math.max(360, Math.round(base.light + wave * 70 - 180)),
        co2: Math.max(360, Math.round(base.co2 + wave * 18 - 44)),
        ph: Number((base.ph + wave * 0.03 - 0.08).toFixed(2))
      });
    }
    return data;
  }

  private seriesValues(points: HourPoint[], key: string): number[] {
    const values: number[] = [];
    for (let i = 0; i < points.length; i++) {
      if (key === 'airTemp') {
        values.push(points[i].airTemp);
      } else if (key === 'airHum') {
        values.push(points[i].airHum);
      } else if (key === 'soilTemp') {
        values.push(points[i].soilTemp);
      } else if (key === 'soilHum') {
        values.push(points[i].soilHum);
      } else if (key === 'light') {
        values.push(points[i].light);
      } else if (key === 'co2') {
        values.push(points[i].co2);
      } else {
        values.push(points[i].ph);
      }
    }
    return values;
  }

  private labels(points: HourPoint[]): string[] {
    const labels: string[] = [];
    for (let i = 0; i < points.length; i++) {
      labels.push(points[i].label);
    }
    return labels;
  }

  private payload(): WebChartPayload {
    const points = this.chartData();
    const labels = this.labels(points);
    return {
      charts: [
        {
          title: '空气温湿度',
          type: 'area',
          badge: '面积图',
          labels,
          min: 0,
          max: 100,
          series: [
            { name: '温度 (℃)', color: '#FF5722', data: this.seriesValues(points, 'airTemp') },
            { name: '湿度 (%)', color: '#2196F3', data: this.seriesValues(points, 'airHum') }
          ]
        },
        {
          title: '土壤温湿度',
          type: 'column',
          badge: '柱状图',
          labels,
          min: 0,
          max: 100,
          series: [
            { name: '土壤温度 (℃)', color: '#FF5722', data: this.seriesValues(points, 'soilTemp') },
            { name: '土壤湿度 (%)', color: '#2196F3', data: this.seriesValues(points, 'soilHum') }
          ]
        },
        {
          title: '气体监测',
          type: 'column',
          badge: '柱状图',
          labels,
          min: 350,
          max: 900,
          series: [
            { name: '二氧化碳 (ppm)', color: '#9C27B0', data: this.seriesValues(points, 'co2') }
          ]
        },
        {
          title: '光照强度',
          type: 'spline',
          badge: '平滑曲线图',
          labels,
          min: 300,
          max: 1600,
          series: [
            { name: '光照强度', color: '#FFC107', data: this.seriesValues(points, 'light') }
          ]
        },
        {
          title: '土壤酸碱度pH值',
          type: 'spline',
          badge: '平滑曲线图',
          labels,
          min: 5.8,
          max: 7.4,
          series: [
            { name: '土壤pH值', color: '#F44336', data: this.seriesValues(points, 'ph') }
          ]
        }
      ]
    };
  }

  private injectCharts(): void {
    const script = `window.renderAACharts(${JSON.stringify(this.payload())});`;
    this.controller.runJavaScript(script).then(() => {
    }).catch(() => {
    });
  }

  @Builder
  Header(title: string) {
    Row() {
      Text('<')
        .width(40)
        .height(40)
        .fontSize(24)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .backgroundColor('#89AE63')
        .borderRadius(20)
        .onClick(() => router.back())
      Text(title)
        .layoutWeight(1)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .margin({ right: 40 })
    }
    .width('100%')
    .height(62)
    .padding({ left: 14, right: 14 })
    .backgroundColor('#558C58')
    .borderRadius(14)
    .shadow({ radius: 5, color: '#22000000', offsetX: 0, offsetY: 2 })
  }

  @Builder
  FilterCard() {
    Row() {
      Text('● 监测目标')
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#6BA878')
      Select(this.greenhouseOptions())
        .selected(this.selectedIndex)
        .value(this.currentGreenhouse().name)
        .layoutWeight(1)
        .height(48)
        .margin({ left: 12 })
        .onSelect((index: number) => {
          this.selectedIndex = index;
          setTimeout(() => this.injectCharts(), 30);
        })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 12, bottom: 12 })
    .backgroundColor(Color.White)
    .borderRadius(14)
    .shadow({ radius: 2, color: '#18000000', offsetX: 0, offsetY: 1 })
  }

  build() {
    Column({ space: 16 }) {
      this.Header('实时环境数据')
      this.FilterCard()
      Web({ src: $rawfile('aa_charts.html'), controller: this.controller })
        .layoutWeight(1)
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .fileAccess(true)
        .backgroundColor('#E9F2E6')
        .onPageEnd(() => this.injectCharts())
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .backgroundColor('#E9F2E6')
  }
}
