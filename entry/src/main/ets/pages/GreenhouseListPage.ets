import { router } from '@kit.ArkUI';
import { AndroidBackTopBar } from '../common/AndroidWidgets';
import { AppRoutes } from '../common/AppRoutes';
import { Greenhouse } from '../models/AppModels';
import { AppService } from '../services/AppService';

@Entry
@Component
struct GreenhouseListPage {
  private greenhouses: Greenhouse[] = AppService.getGreenhouses();

  build() {
    Column({ space: 12 }) {
      AndroidBackTopBar({ title: '大棚列表' })
      Row() {
        Blank()
        Button('新增')
          .height(34)
          .backgroundColor('#238B45')
          .borderRadius(17)
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
        .borderRadius(14)
        .shadow({ radius: 2, color: '#18000000', offsetX: 0, offsetY: 1 })
      }, (item: Greenhouse) => item.id)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 10 })
    .backgroundColor('#E9F2E6')
  }
}
