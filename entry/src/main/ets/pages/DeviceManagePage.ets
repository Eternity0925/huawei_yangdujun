import { router } from '@kit.ArkUI';
import { AndroidBackTopBar } from '../common/AndroidWidgets';
import { AppRoutes } from '../common/AppRoutes';
import { Device, Greenhouse } from '../models/AppModels';
import { AppService } from '../services/AppService';

interface SelectItem {
  value: string;
}

@Entry
@Component
struct DeviceManagePage {
  @State selectedIndex: number = 0;
  @State greenhouses: Greenhouse[] = AppService.getGreenhouses();
  @State deviceList: Device[] = [];

  aboutToAppear(): void {
    this.refreshData();
  }

  private currentGreenhouse(): Greenhouse {
    return this.greenhouses[this.selectedIndex] || this.greenhouses[0];
  }

  private devices(): Device[] {
    return this.deviceList.length > 0 ? this.deviceList : AppService.getDevices(this.currentGreenhouse().id);
  }

  private refreshData(): void {
    AppService.refreshGreenhousesFromDatabase().then((items: Greenhouse[]) => {
      this.greenhouses = items;
      if (this.selectedIndex >= this.greenhouses.length) {
        this.selectedIndex = 0;
      }
      this.refreshDevices();
    }).catch(() => {
      this.refreshDevices();
    });
  }

  private refreshDevices(): void {
    AppService.refreshDevicesFromDatabase(this.currentGreenhouse().id).then((items: Device[]) => {
      this.deviceList = items;
    }).catch(() => {
      this.deviceList = AppService.getDevices(this.currentGreenhouse().id);
    });
  }

  private greenhouseOptions(): SelectItem[] {
    const options: SelectItem[] = [];
    for (let i = 0; i < this.greenhouses.length; i++) {
      options.push({ value: this.greenhouses[i].name });
    }
    return options;
  }

  build() {
    Column({ space: 12 }) {
      AndroidBackTopBar({ title: '设备管理' })

      Select(this.greenhouseOptions())
        .selected(this.selectedIndex)
        .value(this.currentGreenhouse().name)
        .height(48)
        .width('100%')
        .onSelect((index: number) => {
          this.selectedIndex = index;
          this.refreshDevices();
        })

      ForEach(this.devices(), (item: Device) => {
        Row() {
          Column({ space: 4 }) {
            Text(item.name)
              .fontSize(17)
              .fontColor('#1F2937')
              .fontWeight(FontWeight.Bold)
            Text(`${item.type}  ${item.status}`)
              .fontSize(13)
              .fontColor('#667085')
          }
          .alignItems(HorizontalAlign.Start)
          Blank()
          Text(item.enabled ? '在线' : '离线')
            .fontSize(13)
            .fontColor(item.enabled ? '#238B45' : '#9CA3AF')
            .margin({ right: 12 })
          Button('监控')
            .height(34)
            .backgroundColor('#238B45')
            .onClick(() => router.pushUrl({
              url: AppRoutes.DEVICE_MONITOR,
              params: {
                greenhouseId: item.greenhouseId,
                deviceId: item.id
              }
            }))
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(14)
        .shadow({ radius: 2, color: '#18000000', offsetX: 0, offsetY: 1 })
      }, (item: Device) => item.id)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 10 })
    .backgroundColor('#E9F2E6')
  }
}
