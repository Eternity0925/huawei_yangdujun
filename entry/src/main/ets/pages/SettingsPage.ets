import { router } from '@kit.ArkUI';
import { SettingItem } from '../models/AppModels';
import { AppState } from '../storage/AppState';

@Entry
@Component
struct SettingsPage {
  @State settings: SettingItem[] = AppState.settings;

  build() {
    Column({ space: 12 }) {
      Row() {
        Text('<')
          .fontSize(22)
          .fontColor('#238B45')
          .onClick(() => router.back())
        Text('应用设置')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#143D2A')
          .margin({ left: 12 })
      }
      .width('100%')

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
              AppState.settings[index].enabled = value;
            })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(8)
      }, (item: SettingItem) => item.id)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 18 })
    .backgroundColor('#F6FBF6')
  }
}
