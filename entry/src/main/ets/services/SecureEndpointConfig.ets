export class SecureEndpointConfig {
  // Backend proxy address. Keys for DeepSeek, Huawei Cloud, Baidu, etc. stay on the backend.
  static readonly API_BASE_URL: string = 'http://172.20.10.3:8080';
  static readonly API_BASE_URLS: string[] = [
    SecureEndpointConfig.API_BASE_URL,
    'http://127.0.0.1:8080',
    'http://localhost:8080'
  ];

  static readonly AI_CHAT_PATH: string = '/ai/chat';
  static readonly AI_SUGGESTION_PATH: string = '/ai/suggestion';
  static readonly HUAWEI_IOT_SHADOW_PATH: string = '/iot/shadow';
  static readonly HUAWEI_IOT_COMMAND_PATH: string = '/iot/command';
  static readonly HUAWEI_ASR_PATH: string = '/voice/asr';
  static readonly BAIDU_MAP_TOKEN_PATH: string = '/map/baidu/token';

  static hasBackend(): boolean {
    return SecureEndpointConfig.API_BASE_URLS.length > 0;
  }
}
