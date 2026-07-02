export class SecureEndpointConfig {
  // Backend proxy address. Keys for DeepSeek and Huawei Cloud stay on the backend.
  static readonly API_BASE_URL: string = 'http://172.22.17.189:8080';
  static readonly API_BASE_URLS: string[] = [
    SecureEndpointConfig.API_BASE_URL,
    'http://127.0.0.1:8080',
    'http://localhost:8080'
  ];

  static readonly AI_CHAT_PATH: string = '/ai/chat';
  static readonly AI_SUGGESTION_PATH: string = '/ai/suggestion';
  static readonly AUTH_LOGIN_PATH: string = '/auth/login';
  static readonly AUTH_REGISTER_PATH: string = '/auth/register';
  static readonly AUTH_RESET_PASSWORD_PATH: string = '/auth/reset-password';
  static readonly GREENHOUSES_PATH: string = '/greenhouses';
  static readonly GREENHOUSE_DELETE_PATH: string = '/greenhouse/delete';
  static readonly DEVICES_PATH: string = '/devices';
  static readonly ALARMS_PATH: string = '/alarms';
  static readonly ALARM_HANDLE_PATH: string = '/alarm/handle';
  static readonly THRESHOLD_PATH: string = '/threshold';
  static readonly HUAWEI_IOT_SHADOW_PATH: string = '/iot/shadow';
  static readonly HUAWEI_IOT_COMMAND_PATH: string = '/iot/command';
  static readonly SENSOR_LATEST_PATH: string = '/sensor/latest';
  static readonly SENSOR_HISTORY_PATH: string = '/sensor/history';
  static readonly FEEDBACK_PATH: string = '/feedback';

  static hasBackend(): boolean {
    return SecureEndpointConfig.API_BASE_URLS.length > 0;
  }
}
