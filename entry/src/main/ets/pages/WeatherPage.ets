import { AndroidBackTopBar } from '../common/AndroidWidgets';

@Entry
@Component
struct WeatherPage {
  build() {
    Column({ space: 12 }) {
      AndroidBackTopBar({ title: '天气' })

      Column({ space: 10 }) {
        Text('基地天气').fontSize(16).fontColor('#667085')
        Text('18℃').fontSize(44).fontWeight(FontWeight.Bold).fontColor('#238B45')
        Text('阴，空气湿度较高，适合保持通风巡检。').fontSize(15).fontColor('#1F2937')
      }.alignItems(HorizontalAlign.Start).width('100%').padding(20).backgroundColor(Color.White).borderRadius(14).shadow({ radius: 2, color: '#18000000', offsetX: 0, offsetY: 1 })

      Row({ space: 12 }) {
        this.WeatherItem('湿度', '86%')
        this.WeatherItem('风向', '东北风')
        this.WeatherItem('风力', '2级')
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 10 })
    .backgroundColor('#E9F2E6')
  }

  @Builder
  WeatherItem(title: string, value: string) {
    Column({ space: 6 }) {
      Text(title).fontSize(13).fontColor('#667085')
      Text(value).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#143D2A')
    }
    .layoutWeight(1)
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius(14)
    .shadow({ radius: 2, color: '#18000000', offsetX: 0, offsetY: 1 })
  }
}
