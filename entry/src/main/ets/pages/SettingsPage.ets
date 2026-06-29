import { AndroidBackTopBar } from '../common/AndroidWidgets';
import { SettingItem } from '../models/AppModels';
import { AppService } from '../services/AppService';

@Entry
@Component
struct SettingsPage {
  @State settings: SettingItem[] = AppService.getSettings();

  aboutToAppear(): void {
    this.settings = AppService.getSettings();
  }

  build() {
    Column({ space: 12 }) {
      AndroidBackTopBar({ title: '应用设置' })

      ForEach(this.settings, (item: SettingItem, index: number) => {
        Row() {
          Column({ space: 4 }) {
            Text(item.title)
              .fontSize(16)
              .fontColor('#1F2937')
            Text(item.description)
              .fontSize(13)
              .fontColor('#667085')
          }
          .alignItems(HorizontalAlign.Start)
          Blank()
          Toggle({ type: ToggleType.Switch, isOn: item.enabled })
            .selectedColor('#238B45')
            .onChange((value: boolean) => {
              this.settings[index].enabled = value;
              AppService.updateSetting(item.id, value);
            })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(14)
        .shadow({ radius: 2, color: '#18000000', offsetX: 0, offsetY: 1 })
      }, (item: SettingItem) => item.id)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 10 })
    .backgroundColor('#E9F2E6')
  }
}
