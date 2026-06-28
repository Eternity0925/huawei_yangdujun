import { router } from '@kit.ArkUI';
import { AppRoutes } from '../common/AppRoutes';
import { Greenhouse } from '../models/AppModels';
import { AppService } from '../services/AppService';

@Entry
@Component
struct GreenhouseListPage {
  private greenhouses: Greenhouse[] = AppService.getGreenhouses();

  build() {
    Column({ space: 12 }) {
      Row() {
        Text('<')
          .fontSize(22)
          .fontColor('#238B45')
          .onClick(() => router.back())
        Text('大棚列表')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#143D2A')
          .margin({ left: 12 })
        Blank()
        Button('新增')
          .height(34)
          .backgroundColor('#238B45')
          .onClick(() => router.pushUrl({ url: AppRoutes.ADD_GREENHOUSE }))
      }
      .width('100%')

      ForEach(this.greenhouses, (item: Greenhouse) => {
        Column({ space: 6 }) {
          Text(item.name)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1F2937')
          Text(`${item.location}  ${item.area}㎡  ${item.stage}`)
            .fontSize(13)
            .fontColor('#667085')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(8)
      }, (item: Greenhouse) => item.id)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 18 })
    .backgroundColor('#F6FBF6')
  }
}
