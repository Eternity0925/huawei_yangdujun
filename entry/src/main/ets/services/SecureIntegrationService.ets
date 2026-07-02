import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import util from '@ohos.util';
import { AlarmRecord, Device, EnvironmentPoint, Greenhouse, SensorData, ThresholdConfig, User } from '../models/AppModels';
import { SecureEndpointConfig } from './SecureEndpointConfig';

export interface DeviceCommand {
  greenhouseId: string;
  commandName: string;
  value: string | number | boolean;
}

export interface ShadowResponse {
  success: boolean;
  sensor?: SensorData;
}

interface AiSuggestionRequest {
  greenhouse: Greenhouse;
  sensor: SensorData;
  prompt: string;
}

interface AiTextRequest {
  text: string;
  history: string;
}

interface AiTextResponse {
  answer: string;
}

interface AiSuggestionResponse {
  suggestion: string;
}

interface SuccessResponse {
  success: boolean;
}

interface LoginResponse {
  success: boolean;
  user?: User;
}

interface SensorResponse {
  success: boolean;
  sensor?: SensorData;
}

interface GreenhouseListResponse {
  success: boolean;
  items?: Greenhouse[];
}

interface DeviceListResponse {
  success: boolean;
  items?: Device[];
}

interface AlarmListResponse {
  success: boolean;
  items?: AlarmRecord[];
}

interface ThresholdResponse {
  success: boolean;
  threshold?: ThresholdConfig;
}

interface HistoryResponse {
  success: boolean;
  items?: EnvironmentPoint[];
}

export class SecureIntegrationService {
  private static readonly LOG_DOMAIN: number = 0x0001;
  private static readonly LOG_TAG: string = 'GreenhouseCloud';
  static async loginFarmer(account: string, password: string): Promise<User | null> {
    if (!SecureEndpointConfig.hasBackend()) {
      return null;
    }

    try {
      const raw = await SecureIntegrationService.postJson(
        SecureEndpointConfig.AUTH_LOGIN_PATH,
        JSON.stringify({ account, password })
      );
      const result = JSON.parse(raw) as LoginResponse;
      if (result.success && result.user) {
        return result.user;
      }
    } catch (err) {
    }
    return null;
  }

  static async registerFarmer(phone: string, password: string): Promise<boolean> {
    if (!SecureEndpointConfig.hasBackend()) {
      return false;
    }

    try {
      const raw = await SecureIntegrationService.postJson(
        SecureEndpointConfig.AUTH_REGISTER_PATH,
        JSON.stringify({ phone, password })
      );
      const result = JSON.parse(raw) as SuccessResponse;
      return result.success === true;
    } catch (err) {
      return false;
    }
  }

  static async resetFarmerPassword(phone: string, password: string): Promise<boolean> {
    if (!SecureEndpointConfig.hasBackend()) {
      return false;
    }

    try {
      const raw = await SecureIntegrationService.postJson(
        SecureEndpointConfig.AUTH_RESET_PASSWORD_PATH,
        JSON.stringify({ phone, password })
      );
      const result = JSON.parse(raw) as SuccessResponse;
      return result.success === true;
    } catch (err) {
      return false;
    }
  }

  static async requestAiSuggestion(greenhouse: Greenhouse, sensor: SensorData, prompt: string): Promise<string> {
    if (!SecureEndpointConfig.hasBackend()) {
      return SecureIntegrationService.localAiSuggestion(greenhouse, sensor);
    }

    const request: AiSuggestionRequest = {
      greenhouse,
      sensor,
      prompt
    };
    try {
      const raw = await SecureIntegrationService.postJson(SecureEndpointConfig.AI_SUGGESTION_PATH, JSON.stringify(request));
      const result = JSON.parse(raw) as AiSuggestionResponse;
      return result.suggestion || SecureIntegrationService.localAiSuggestion(greenhouse, sensor);
    } catch (err) {
      return SecureIntegrationService.localAiSuggestion(greenhouse, sensor);
    }
  }

  static async requestAiChat(text: string, history: string): Promise<string> {
    if (!SecureEndpointConfig.hasBackend()) {
      return `我已收到你的问题：“${text}”。当前后端代理未配置，正式接入后这里会调用 DeepSeek 返回完整回答。`;
    }

    const request: AiTextRequest = { text, history };
    try {
      const raw = await SecureIntegrationService.postJson(SecureEndpointConfig.AI_CHAT_PATH, JSON.stringify(request));
      const result = JSON.parse(raw) as AiTextResponse;
      return result.answer || 'AI 暂未返回有效回答，请稍后重试。';
    } catch (err) {
      return 'AI 服务暂时不可用，请稍后重试。';
    }
  }

  static async sendHuaweiIoTCommand(command: DeviceCommand): Promise<boolean> {
    if (!SecureEndpointConfig.hasBackend()) {
      return false;
    }

    try {
      const raw = await SecureIntegrationService.postJson(SecureEndpointConfig.HUAWEI_IOT_COMMAND_PATH, JSON.stringify(command));
      const result = JSON.parse(raw) as SuccessResponse;
      return result.success === true;
    } catch (err) {
      return false;
    }
  }

  static async fetchHuaweiIoTShadow(greenhouseId: string): Promise<ShadowResponse> {
    if (SecureEndpointConfig.hasBackend()) {
      try {
        const raw = await SecureIntegrationService.postJson(SecureEndpointConfig.HUAWEI_IOT_SHADOW_PATH, JSON.stringify({ greenhouseId }));
        const result = JSON.parse(raw) as ShadowResponse;
        if (result.success && result.sensor) {
          return result;
        }
      } catch (err) {
      }
    }
    return { success: false };
  }

  static async fetchDatabaseSensor(greenhouseId: string): Promise<ShadowResponse> {
    if (!SecureEndpointConfig.hasBackend()) {
      return { success: false };
    }

    try {
      const path = `${SecureEndpointConfig.SENSOR_LATEST_PATH}?greenhouseId=${encodeURIComponent(greenhouseId)}`;
      const raw = await SecureIntegrationService.getJson(path);
      const result = JSON.parse(raw) as SensorResponse;
      if (result.success && result.sensor) {
        return {
          success: true,
          sensor: SecureIntegrationService.normalizeSensor(result.sensor)
        };
      }
    } catch (err) {
    }
    return { success: false };
  }

  static async fetchDatabaseGreenhouses(userId: string = ''): Promise<Greenhouse[]> {
    if (!SecureEndpointConfig.hasBackend()) {
      return [];
    }

    try {
      const path = userId.length > 0 ?
        `${SecureEndpointConfig.GREENHOUSES_PATH}?userId=${encodeURIComponent(userId)}` :
        SecureEndpointConfig.GREENHOUSES_PATH;
      const raw = await SecureIntegrationService.getJson(path);
      const result = JSON.parse(raw) as GreenhouseListResponse;
      if (result.success && Array.isArray(result.items)) {
        return result.items;
      }
    } catch (err) {
    }
    return [];
  }

  static async createDatabaseGreenhouse(userId: string, name: string, location: string, area: string): Promise<Greenhouse[]> {
    if (!SecureEndpointConfig.hasBackend()) {
      return [];
    }

    try {
      const raw = await SecureIntegrationService.postJson(
        SecureEndpointConfig.GREENHOUSES_PATH,
        JSON.stringify({ userId, name, location, area })
      );
      const result = JSON.parse(raw) as GreenhouseListResponse;
      if (result.success && Array.isArray(result.items)) {
        return result.items;
      }
    } catch (err) {
    }
    return [];
  }

  static async deleteDatabaseGreenhouse(userId: string, greenhouseId: string): Promise<boolean> {
    if (!SecureEndpointConfig.hasBackend()) {
      return false;
    }

    try {
      const raw = await SecureIntegrationService.postJson(
        SecureEndpointConfig.GREENHOUSE_DELETE_PATH,
        JSON.stringify({ userId, greenhouseId })
      );
      const result = JSON.parse(raw) as SuccessResponse;
      return result.success === true;
    } catch (err) {
      return false;
    }
  }

  static async fetchDatabaseDevices(greenhouseId: string): Promise<Device[]> {
    if (!SecureEndpointConfig.hasBackend()) {
      return [];
    }

    try {
      const path = `${SecureEndpointConfig.DEVICES_PATH}?greenhouseId=${encodeURIComponent(greenhouseId)}`;
      const raw = await SecureIntegrationService.getJson(path);
      const result = JSON.parse(raw) as DeviceListResponse;
      if (result.success && Array.isArray(result.items)) {
        return result.items;
      }
    } catch (err) {
    }
    return [];
  }

  static async fetchDatabaseAlarms(greenhouseId: string = ''): Promise<AlarmRecord[]> {
    if (!SecureEndpointConfig.hasBackend()) {
      return [];
    }

    try {
      const path = greenhouseId.length > 0 ?
        `${SecureEndpointConfig.ALARMS_PATH}?greenhouseId=${encodeURIComponent(greenhouseId)}` :
        SecureEndpointConfig.ALARMS_PATH;
      const raw = await SecureIntegrationService.getJson(path);
      const result = JSON.parse(raw) as AlarmListResponse;
      if (result.success && Array.isArray(result.items)) {
        return result.items;
      }
    } catch (err) {
    }
    return [];
  }

  static async handleDatabaseAlarm(alarmId: string, handlerName: string): Promise<boolean> {
    if (!SecureEndpointConfig.hasBackend()) {
      return false;
    }

    try {
      const raw = await SecureIntegrationService.postJson(
        SecureEndpointConfig.ALARM_HANDLE_PATH,
        JSON.stringify({ alarmId, handlerName })
      );
      const result = JSON.parse(raw) as SuccessResponse;
      return result.success === true;
    } catch (err) {
      return false;
    }
  }

  static async fetchDatabaseThreshold(greenhouseId: string): Promise<ThresholdConfig | null> {
    if (!SecureEndpointConfig.hasBackend()) {
      return null;
    }

    try {
      const path = `${SecureEndpointConfig.THRESHOLD_PATH}?greenhouseId=${encodeURIComponent(greenhouseId)}`;
      const raw = await SecureIntegrationService.getJson(path);
      const result = JSON.parse(raw) as ThresholdResponse;
      if (result.success && result.threshold) {
        return result.threshold;
      }
    } catch (err) {
    }
    return null;
  }

  static async saveDatabaseThreshold(greenhouseId: string, threshold: ThresholdConfig): Promise<boolean> {
    if (!SecureEndpointConfig.hasBackend()) {
      return false;
    }

    try {
      const raw = await SecureIntegrationService.postJson(
        SecureEndpointConfig.THRESHOLD_PATH,
        JSON.stringify({
          greenhouseId,
          tempMin: threshold.tempMin,
          tempMax: threshold.tempMax,
          airHumMin: threshold.airHumMin,
          airHumMax: threshold.airHumMax,
          soilTempMin: threshold.soilTempMin,
          soilTempMax: threshold.soilTempMax,
          humMin: threshold.humMin,
          humMax: threshold.humMax,
          co2Min: threshold.co2Min,
          co2Max: threshold.co2Max,
          o2Min: threshold.o2Min,
          o2Max: threshold.o2Max,
          phMin: threshold.phMin,
          phMax: threshold.phMax,
          lightMin: threshold.lightMin,
          lightMax: threshold.lightMax
        })
      );
      const result = JSON.parse(raw) as SuccessResponse;
      return result.success === true;
    } catch (err) {
      return false;
    }
  }

  static async fetchDatabaseHistory(greenhouseId: string, limit: number): Promise<EnvironmentPoint[]> {
    if (!SecureEndpointConfig.hasBackend()) {
      return [];
    }

    try {
      const path = `${SecureEndpointConfig.SENSOR_HISTORY_PATH}?greenhouseId=${encodeURIComponent(greenhouseId)}&limit=${limit}`;
      const raw = await SecureIntegrationService.getJson(path);
      const result = JSON.parse(raw) as HistoryResponse;
      if (result.success && Array.isArray(result.items)) {
        return result.items;
      }
    } catch (err) {
    }
    return [];
  }

  static async submitDatabaseFeedback(userId: string, content: string, contact: string): Promise<boolean> {
    if (!SecureEndpointConfig.hasBackend()) {
      return false;
    }

    try {
      const raw = await SecureIntegrationService.postJson(
        SecureEndpointConfig.FEEDBACK_PATH,
        JSON.stringify({ userId, content, contact })
      );
      const result = JSON.parse(raw) as SuccessResponse;
      return result.success === true;
    } catch (err) {
      return false;
    }
  }

  private static localAiSuggestion(greenhouse: Greenhouse, sensor: SensorData): string {
    const risk = sensor.airHumidity < 80 || sensor.soilHumidity < 65 || sensor.co2 > 900 ? '中' : '低';
    return `风险等级：${risk}
核心问题：${greenhouse.name} 当前处于${greenhouse.stage}，需要重点稳定温湿度、通风和二氧化碳浓度。
紧急操作：保持土壤湿度在 65%-78%，空气湿度在 80%-92%，风机档位控制在 1-3 档。
详细建议：当前空气温度 ${sensor.airTemperature}℃，空气湿度 ${sensor.airHumidity}%，土壤湿度 ${sensor.soilHumidity}%，CO2 ${sensor.co2}ppm。建议每 2 小时复核一次环境数据，发现湿度持续下降时优先检查水泵和喷淋。`;
  }

  private static async postJson(path: string, body: string): Promise<string> {
    for (let i = 0; i < SecureEndpointConfig.API_BASE_URLS.length; i++) {
      const baseUrl = SecureEndpointConfig.API_BASE_URLS[i];
      if (!baseUrl || baseUrl.trim().length === 0) {
        continue;
      }
      const request = http.createHttp();
      try {
        const response = await request.request(`${baseUrl}${path}`, {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json'
          },
          extraData: body,
          expectDataType: http.HttpDataType.STRING,
          connectTimeout: 5000,
          readTimeout: 30000
        });

        if (typeof response.result === 'string') {
          return response.result;
        }
        return JSON.stringify(response.result);
      } catch (err) {
      } finally {
        request.destroy();
      }
    }
    return '{}';
  }

  private static async getJson(path: string): Promise<string> {
    for (let i = 0; i < SecureEndpointConfig.API_BASE_URLS.length; i++) {
      const baseUrl = SecureEndpointConfig.API_BASE_URLS[i];
      if (!baseUrl || baseUrl.trim().length === 0) {
        continue;
      }
      const request = http.createHttp();
      try {
        const response = await request.request(`${baseUrl}${path}`, {
          method: http.RequestMethod.GET,
          header: {
            'Content-Type': 'application/json'
          },
          expectDataType: http.HttpDataType.STRING,
          connectTimeout: 5000,
          readTimeout: 30000
        });

        if (typeof response.result === 'string') {
          return response.result;
        }
        return JSON.stringify(response.result);
      } catch (err) {
      } finally {
        request.destroy();
      }
    }
    return '{}';
  }

  private static normalizeSensor(sensor: SensorData): SensorData {
    return {
      airTemperature: SecureIntegrationService.numberOr(sensor.airTemperature, -1),
      airHumidity: SecureIntegrationService.numberOr(sensor.airHumidity, -1),
      soilTemperature: SecureIntegrationService.numberOr(sensor.soilTemperature, -1),
      soilHumidity: SecureIntegrationService.numberOr(sensor.soilHumidity, -1),
      light: SecureIntegrationService.numberOr(sensor.light, -1),
      co2: SecureIntegrationService.numberOr(sensor.co2, -1),
      o2: SecureIntegrationService.numberOr(sensor.o2, -1),
      ph: SecureIntegrationService.numberOr(sensor.ph, -1),
      distance: SecureIntegrationService.numberOr(sensor.distance, -1),
      fanGear: Math.trunc(SecureIntegrationService.numberOr(sensor.fanGear, 0)),
      lightOn: sensor.lightOn === true,
      boardOn: sensor.boardOn === true,
      waterPumpOn: sensor.waterPumpOn === true,
      medicinePumpOn: sensor.medicinePumpOn === true,
      aiWarning: sensor.aiWarning || '',
      growthStage: Math.trunc(SecureIntegrationService.numberOr(sensor.growthStage, 0)),
      updatedAt: sensor.updatedAt || ''
    };
  }

  private static numberOr(value: number, fallback: number): number {
    const parsed = Number(value);
    return parsed === parsed ? parsed : fallback;
  }

  private static responseText(result: string | Object | ArrayBuffer): string {
    if (typeof result === 'string') {
      return result;
    }
    if (result instanceof ArrayBuffer) {
      const bytes = new Uint8Array(result);
      return util.TextDecoder.create('utf-8').decodeToString(bytes);
    }
    return JSON.stringify(result);
  }

  private static resultTypeName(result: string | Object | ArrayBuffer): string {
    if (typeof result === 'string') {
      return 'string';
    }
    if (result instanceof ArrayBuffer) {
      return 'ArrayBuffer';
    }
    return 'object';
  }

  private static preview(value: string): string {
    return value.length > 240 ? value.substring(0, 240) : value;
  }
}
