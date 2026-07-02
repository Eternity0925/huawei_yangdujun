import { promptAction, router } from '@kit.ArkUI';
import { AndroidBackTopBar } from '../common/AndroidWidgets';
import { AppRoutes } from '../common/AppRoutes';
import { Greenhouse } from '../models/AppModels';
import { AppService } from '../services/AppService';

@Entry
@Component
struct GreenhouseListPage {
  @State greenhouses: Greenhouse[] = AppService.getGreenhouses();
  @State loading: boolean = false;

  aboutToAppear(): void {
    this.refreshList();
  }

  private refreshList(): void {
    this.greenhouses = AppService.getGreenhouses();
    this.loading = true;
    AppService.refreshGreenhousesFromDatabase().then((items: Greenhouse[]) => {
      this.greenhouses = items;
      this.loading = false;
    }).catch(() => {
      this.loading = false;
    });
  }

  private async deleteGreenhouse(item: Greenhouse): Promise<void> {
    const ok = await AppService.deleteGreenhouseFromDatabase(item.id);
    if (!ok) {
      promptAction.showToast({ message: '删除失败，请稍后重试' });
      return;
    }
    promptAction.showToast({ message: '已删除大棚' });
    this.greenhouses = AppService.getGreenhouses();
    this.refreshList();
  }

  @Builder
  GreenhouseCard(item: Greenhouse) {
    Row() {
      Column({ space: 6 }) {
        Text(item.name)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1F2937')
          .maxLines(1)
        Text(`${item.location}  ${item.area}㎡  ${item.stage}`)
          .fontSize(13)
          .fontColor('#667085')
          .maxLines(1)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Button('删除')
        .width(58)
        .height(32)
        .fontSize(13)
        .fontColor(Color.White)
        .backgroundColor('#D14343')
        .borderRadius(16)
        .onClick(() => this.deleteGreenhouse(item))
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(14)
    .shadow({ radius: 2, color: '#18000000', offsetX: 0, offsetY: 1 })
  }

  build() {
    Column({ space: 12 }) {
      AndroidBackTopBar({ title: '大棚列表' })
      Row() {
        Text(this.loading ? '正在刷新...' : `共 ${this.greenhouses.length} 个大棚`)
          .fontSize(13)
          .fontColor('#667085')
        Blank()
        Button('新增')
          .height(34)
          .backgroundColor('#238B45')
          .borderRadius(17)
          .onClick(() => router.pushUrl({ url: AppRoutes.ADD_GREENHOUSE }))
      }
      .width('100%')

      Scroll() {
        Column({ space: 12 }) {
          ForEach(this.greenhouses, (item: Greenhouse) => {
            this.GreenhouseCard(item)
          }, (item: Greenhouse) => `${item.id}-${item.name}`)
        }
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 10 })
    .backgroundColor('#E9F2E6')
  }
}
