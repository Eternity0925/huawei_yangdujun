import { promptAction, router } from '@kit.ArkUI';
import { AppService } from '../services/AppService';

@Entry
@Component
struct AddGreenhousePage {
  @State name: string = '';
  @State location: string = '';
  @State area: string = '';

  private submit(): void {
    if (this.name.trim().length === 0) {
      promptAction.showToast({ message: '请输入大棚名称' });
      return;
    }
    AppService.addGreenhouse(this.name, this.location || '未填写位置', this.area || '0');
    promptAction.showToast({ message: '大棚已新增' });
    router.back();
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        Text('<')
          .fontSize(22)
          .fontColor('#238B45')
          .onClick(() => router.back())
        Text('新增大棚')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#143D2A')
          .margin({ left: 12 })
      }
      .width('100%')

      TextInput({ placeholder: '大棚名称' })
        .height(48)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .padding({ left: 14, right: 14 })
        .onChange((value: string) => this.name = value)
      TextInput({ placeholder: '位置' })
        .height(48)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .padding({ left: 14, right: 14 })
        .onChange((value: string) => this.location = value)
      TextInput({ placeholder: '面积' })
        .height(48)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .padding({ left: 14, right: 14 })
        .onChange((value: string) => this.area = value)

      Button('保存')
        .width('100%')
        .height(46)
        .backgroundColor('#238B45')
        .borderRadius(8)
        .onClick(() => this.submit())
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 18 })
    .backgroundColor('#F6FBF6')
  }
}
