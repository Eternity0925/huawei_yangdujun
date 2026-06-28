import { router } from '@kit.ArkUI';
import { SensorData } from '../models/AppModels';
import { AppService } from '../services/AppService';

@Entry
@Component
struct RealTimeAnalysisPage {
  private data: SensorData = AppService.getSensorData('default');

  build() {
    Column({ space: 12 }) {
      this.Header('实时分析')
      this.AnalysisCard('温湿度', `空气 ${this.data.airTemperature}℃ / ${this.data.airHumidity}%`, '当前环境适合维持出菇阶段，注意空气湿度不要低于 80%。')
      this.AnalysisCard('土壤环境', `土温 ${this.data.soilTemperature}℃ / 土湿 ${this.data.soilHumidity}%`, '土壤温湿度处于羊肚菌生长可控范围，持续观察变化趋势。')
      this.AnalysisCard('光照', `${this.data.light} lux`, '光照强度偏温和，可根据生长阶段调整遮光板。')
      this.AnalysisCard('CO2 / O2 / pH', `${this.data.co2} ppm / ${this.data.o2}% / ${this.data.ph}`, 'CO2 在可控范围内，建议保持低档通风。')
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 18 })
    .backgroundColor('#F6FBF6')
  }

  @Builder
  Header(title: string) {
    Row() {
      Text('<').fontSize(22).fontColor('#238B45').onClick(() => router.back())
      Text(title).fontSize(24).fontWeight(FontWeight.Bold).fontColor('#143D2A').margin({ left: 12 })
    }.width('100%')
  }

  @Builder
  AnalysisCard(title: string, value: string, desc: string) {
    Column({ space: 8 }) {
      Text(title).fontSize(14).fontColor('#667085')
      Text(value).fontSize(24).fontWeight(FontWeight.Bold).fontColor('#238B45')
      Text(desc).fontSize(14).fontColor('#1F2937')
    }.alignItems(HorizontalAlign.Start).width('100%').padding(16).backgroundColor(Color.White).borderRadius(8)
  }
}
