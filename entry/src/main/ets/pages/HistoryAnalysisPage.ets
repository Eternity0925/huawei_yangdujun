import { router } from '@kit.ArkUI';

interface TrendItem {
  day: string;
  temp: string;
  humi: string;
  soil: string;
}

@Entry
@Component
struct HistoryAnalysisPage {
  private trends: TrendItem[] = [
    { day: '06-18', temp: '17.8℃', humi: '84%', soil: '70%' },
    { day: '06-19', temp: '18.1℃', humi: '86%', soil: '72%' },
    { day: '06-20', temp: '18.6℃', humi: '83%', soil: '69%' },
    { day: '06-21', temp: '17.9℃', humi: '88%', soil: '74%' },
    { day: '06-22', temp: '18.3℃', humi: '85%', soil: '71%' }
  ];

  build() {
    Column({ space: 12 }) {
      Row() {
        Text('<').fontSize(22).fontColor('#238B45').onClick(() => router.back())
        Text('历史分析').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#143D2A').margin({ left: 12 })
      }.width('100%')

      Row() {
        Text('日期').fontSize(13).fontColor('#667085').layoutWeight(1)
        Text('温度').fontSize(13).fontColor('#667085').layoutWeight(1).textAlign(TextAlign.Center)
        Text('空气湿度').fontSize(13).fontColor('#667085').layoutWeight(1).textAlign(TextAlign.Center)
        Text('土壤湿度').fontSize(13).fontColor('#667085').layoutWeight(1).textAlign(TextAlign.End)
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      ForEach(this.trends, (item: TrendItem) => {
        Row() {
          Text(item.day).fontSize(15).fontColor('#667085').layoutWeight(1)
          Text(item.temp).fontSize(16).fontColor('#D9480F').layoutWeight(1).textAlign(TextAlign.Center)
          Text(item.humi).fontSize(16).fontColor('#1971C2').layoutWeight(1).textAlign(TextAlign.Center)
          Text(item.soil).fontSize(16).fontColor('#238B45').layoutWeight(1).textAlign(TextAlign.End)
        }.width('100%').padding(16).backgroundColor(Color.White).borderRadius(8)
      }, (item: TrendItem) => item.day)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 18 })
    .backgroundColor('#F6FBF6')
  }
}
