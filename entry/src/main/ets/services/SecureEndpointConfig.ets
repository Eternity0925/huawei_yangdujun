export class SecureEndpointConfig {
  // 后端代理服务地址。DeepSeek、华为云、百度等 Key 只放在后端，不写入 HAP。
  static readonly API_BASE_URL: string = '';

  static readonly AI_CHAT_PATH: string = '/ai/chat';
  static readonly AI_SUGGESTION_PATH: string = '/ai/suggestion';
  static readonly HUAWEI_IOT_SHADOW_PATH: string = '/iot/shadow';
  static readonly HUAWEI_IOT_COMMAND_PATH: string = '/iot/command';
  static readonly HUAWEI_ASR_PATH: string = '/voice/asr';
  static readonly BAIDU_MAP_TOKEN_PATH: string = '/map/baidu/token';

  static hasBackend(): boolean {
    return SecureEndpointConfig.API_BASE_URL.trim().length > 0;
  }
}
