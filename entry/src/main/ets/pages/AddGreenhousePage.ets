import { promptAction, router } from '@kit.ArkUI';
import { AndroidBackTopBar } from '../common/AndroidWidgets';
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
      AndroidBackTopBar({ title: '新增大棚' })

      TextInput({ placeholder: '大棚名称' })
        .height(48)
        .backgroundColor(Color.White)
        .borderRadius(14)
        .padding({ left: 14, right: 14 })
        .shadow({ radius: 2, color: '#18000000', offsetX: 0, offsetY: 1 })
        .onChange((value: string) => this.name = value)
      TextInput({ placeholder: '位置' })
        .height(48)
        .backgroundColor(Color.White)
        .borderRadius(14)
        .padding({ left: 14, right: 14 })
        .shadow({ radius: 2, color: '#18000000', offsetX: 0, offsetY: 1 })
        .onChange((value: string) => this.location = value)
      TextInput({ placeholder: '面积' })
        .height(48)
        .backgroundColor(Color.White)
        .borderRadius(14)
        .padding({ left: 14, right: 14 })
        .shadow({ radius: 2, color: '#18000000', offsetX: 0, offsetY: 1 })
        .onChange((value: string) => this.area = value)

      Button('保存')
        .width('100%')
        .height(46)
        .backgroundColor('#238B45')
        .borderRadius(23)
        .onClick(() => this.submit())
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 10 })
    .backgroundColor('#E9F2E6')
  }
}
