import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import util from '@ohos.util';
import { Greenhouse, SensorData } from '../models/AppModels';
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

interface TokenResponse {
  token: string;
}

export class SecureIntegrationService {
  private static readonly LOG_DOMAIN: number = 0x0001;
  private static readonly LOG_TAG: string = 'GreenhouseCloud';
  private static readonly HUAWEI_IAM_URL: string = 'https://iam.cn-north-4.myhuaweicloud.com/v3/auth/tokens';
  private static readonly HUAWEI_IOT_ENDPOINT: string = 'https://b349431dee.st1.iotda-app.cn-north-4.myhuaweicloud.com:443';
  private static readonly HUAWEI_IOT_PROJECT_ID: string = '0e7c5e04a662439c813433f94d7ad4e7';
  private static readonly HUAWEI_IOT_DEVICE_ID: string = '6a3a6da1cbb0cf6bb96829a4_WHYwhy';
  private static readonly HUAWEI_IOT_USERNAME: string = 'why';
  private static readonly HUAWEI_IOT_PASSWORD: string = 'why123456';
  private static readonly HUAWEI_IOT_DOMAIN: string = 'why66665';
  private static readonly HUAWEI_IOT_PROJECT_NAME: string = 'cn-north-4';
  private static huaweiIoTToken: string = '';
  private static huaweiIoTTokenExpireAtMs: number = 0;

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
      return true;
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
    return SecureIntegrationService.fetchHuaweiIoTShadowDirect();
  }

  static async recognizeSpeechBase64(audioBase64: string): Promise<string> {
    if (!SecureEndpointConfig.hasBackend()) {
      return '语音识别后端未配置';
    }

    try {
      const raw = await SecureIntegrationService.postJson(
        SecureEndpointConfig.HUAWEI_ASR_PATH,
        JSON.stringify({ audioBase64 })
      );
      const result = JSON.parse(raw) as AiTextResponse;
      return result.answer || '';
    } catch (err) {
      return '';
    }
  }

  static async getBaiduMapToken(): Promise<string> {
    if (!SecureEndpointConfig.hasBackend()) {
      return '';
    }

    try {
      const raw = await SecureIntegrationService.postJson(SecureEndpointConfig.BAIDU_MAP_TOKEN_PATH, '{}');
      const result = JSON.parse(raw) as TokenResponse;
      return result.token || '';
    } catch (err) {
      return '';
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

  private static async fetchHuaweiIoTShadowDirect(): Promise<ShadowResponse> {
    try {
      const token = await SecureIntegrationService.getHuaweiIoTTokenDirect();
      const url = `${SecureIntegrationService.HUAWEI_IOT_ENDPOINT}/v5/iot/${SecureIntegrationService.HUAWEI_IOT_PROJECT_ID}/devices/${SecureIntegrationService.HUAWEI_IOT_DEVICE_ID}/shadow`;
      const raw = await SecureIntegrationService.requestText(url, http.RequestMethod.GET, '', token);
      hilog.info(SecureIntegrationService.LOG_DOMAIN, SecureIntegrationService.LOG_TAG,
        'shadow raw len=%{public}d body=%{public}s', raw.length, SecureIntegrationService.preview(raw));
      const sensor = SecureIntegrationService.sensorFromHuaweiShadow(raw);
      hilog.info(SecureIntegrationService.LOG_DOMAIN, SecureIntegrationService.LOG_TAG,
        'parsed Temp=%{public}f Humi=%{public}f Lumi=%{public}f SoilHumi=%{public}f CO2=%{public}f',
        sensor.airTemperature, sensor.airHumidity, sensor.light, sensor.soilHumidity, sensor.co2);
      return {
        success: true,
        sensor
      };
    } catch (err) {
      hilog.error(SecureIntegrationService.LOG_DOMAIN, SecureIntegrationService.LOG_TAG,
        'direct shadow failed: %{public}s', JSON.stringify(err));
      return { success: false };
    }
  }

  private static async getHuaweiIoTTokenDirect(): Promise<string> {
    const now = Date.now();
    if (SecureIntegrationService.huaweiIoTToken.length > 0 &&
      now < SecureIntegrationService.huaweiIoTTokenExpireAtMs - 60000) {
      return SecureIntegrationService.huaweiIoTToken;
    }

    const body = SecureIntegrationService.huaweiAuthBody();
    const request = http.createHttp();
    try {
      const response = await request.request(SecureIntegrationService.HUAWEI_IAM_URL, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json; charset=utf-8'
        },
        extraData: body,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 15000,
        readTimeout: 30000
      });
      if (Number(response.responseCode) < 200 || Number(response.responseCode) >= 300) {
        throw new Error('Huawei IAM unavailable');
      }
      const token = SecureIntegrationService.headerValue(response.header, 'X-Subject-Token');
      hilog.info(SecureIntegrationService.LOG_DOMAIN, SecureIntegrationService.LOG_TAG,
        'IAM response=%{public}d tokenLen=%{public}d header=%{public}s',
        Number(response.responseCode), token.length, SecureIntegrationService.preview(JSON.stringify(response.header)));
      if (token.length === 0) {
        throw new Error('Huawei IAM token missing');
      }
      SecureIntegrationService.huaweiIoTToken = token;
      SecureIntegrationService.huaweiIoTTokenExpireAtMs = now + 60 * 60 * 1000;
      return token;
    } finally {
      request.destroy();
    }
  }

  private static huaweiAuthBody(): string {
    return '{'
      + '"auth":{'
      + '"identity":{'
      + '"methods":["password"],'
      + '"password":{"user":{'
      + '"name":"' + SecureIntegrationService.HUAWEI_IOT_USERNAME + '",'
      + '"password":"' + SecureIntegrationService.HUAWEI_IOT_PASSWORD + '",'
      + '"domain":{"name":"' + SecureIntegrationService.HUAWEI_IOT_DOMAIN + '"}'
      + '}}'
      + '},'
      + '"scope":{"project":{"name":"' + SecureIntegrationService.HUAWEI_IOT_PROJECT_NAME + '"}}'
      + '}'
      + '}';
  }

  private static async requestText(url: string, method: http.RequestMethod, body: string, token: string): Promise<string> {
    const request = http.createHttp();
    try {
      const options: http.HttpRequestOptions = {
        method,
        header: {
          'Content-Type': 'application/json',
          'X-Auth-Token': token
        },
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 15000,
        readTimeout: 30000
      };
      if (body.length > 0) {
        options.extraData = body;
      }
      const response = await request.request(url, options);
      if (Number(response.responseCode) < 200 || Number(response.responseCode) >= 300) {
        throw new Error('Huawei IoT unavailable');
      }
      const text = SecureIntegrationService.responseText(response.result);
      hilog.info(SecureIntegrationService.LOG_DOMAIN, SecureIntegrationService.LOG_TAG,
        'requestText response=%{public}d resultType=%{public}s textLen=%{public}d',
        Number(response.responseCode), SecureIntegrationService.resultTypeName(response.result), text.length);
      return text;
    } finally {
      request.destroy();
    }
  }

  private static sensorFromHuaweiShadow(raw: string): SensorData {
    try {
      const parsed = JSON.parse(raw) as Record<string, Object>;
      const shadowList = parsed['shadow'] as Array<Record<string, Object>>;
      if (Array.isArray(shadowList) && shadowList.length > 0) {
        const reported = shadowList[0]['reported'] as Record<string, Object>;
        const properties = reported['properties'] as Record<string, Object>;
        if (properties) {
          const eventTime = reported['event_time'] as string || '';
          return SecureIntegrationService.sensorFromProperties(properties, eventTime);
        }
      }
    } catch (err) {
    }

    return {
      airTemperature: SecureIntegrationService.firstNumber(raw, -1, ['Temp', 'temperature', 'airTemperature']),
      airHumidity: SecureIntegrationService.firstNumber(raw, -1, ['Humi', 'humidity', 'airHumidity']),
      soilTemperature: SecureIntegrationService.firstNumber(raw, -1, ['Soil_Temp', 'SoilTemp', 'soilTemperature']),
      soilHumidity: SecureIntegrationService.firstNumber(raw, -1, ['Soil_Humi', 'SoilHumi', 'soilHumidity']),
      light: SecureIntegrationService.firstNumber(raw, -1, ['Lumi', 'light', 'lightIntensity']),
      co2: SecureIntegrationService.firstNumber(raw, -1, ['CO2', 'co2', 'Co2']),
      o2: SecureIntegrationService.firstNumber(raw, -1, ['O2', 'o2']),
      ph: SecureIntegrationService.firstNumber(raw, -1, ['pH', 'PH', 'ph']),
      distance: SecureIntegrationService.firstNumber(raw, -1, ['Dist', 'distance', 'Distance']),
      fanGear: SecureIntegrationService.firstInteger(raw, 0, ['Fengd', 'fengdegree', 'fanGear']),
      lightOn: SecureIntegrationService.firstBool(raw, ['LightSt', 'LampST', 'light']),
      boardOn: SecureIntegrationService.firstBool(raw, ['DangGuangBan', 'board', 'windBoardStatus']),
      waterPumpOn: SecureIntegrationService.firstBool(raw, ['Bump', 'BUMP', 'bump', 'pump']),
      medicinePumpOn: SecureIntegrationService.firstBool(raw, ['MedicinePump', 'MedicineBump', 'DrugPump', 'YaoPump', 'YaoBump']),
      aiWarning: SecureIntegrationService.firstText(raw, '', ['AIWarning', 'aiWarning']),
      growthStage: SecureIntegrationService.firstInteger(raw, 0, ['GrowthStage', 'State', 'growthStage']),
      updatedAt: SecureIntegrationService.firstText(raw, '', ['event_time', 'last_update_time'])
    };
  }

  private static sensorFromProperties(properties: Record<string, Object>, eventTime: string): SensorData {
    return {
      airTemperature: SecureIntegrationService.propertyNumber(properties, -1, ['Temp', 'temperature', 'airTemperature']),
      airHumidity: SecureIntegrationService.propertyNumber(properties, -1, ['Humi', 'humidity', 'airHumidity']),
      soilTemperature: SecureIntegrationService.propertyNumber(properties, -1, ['Soil_Temp', 'SoilTemp', 'soilTemperature']),
      soilHumidity: SecureIntegrationService.propertyNumber(properties, -1, ['Soil_Humi', 'SoilHumi', 'soilHumidity']),
      light: SecureIntegrationService.propertyNumber(properties, -1, ['Lumi', 'light', 'lightIntensity']),
      co2: SecureIntegrationService.propertyNumber(properties, -1, ['CO2', 'co2', 'Co2']),
      o2: SecureIntegrationService.propertyNumber(properties, -1, ['O2', 'o2']),
      ph: SecureIntegrationService.propertyNumber(properties, -1, ['pH', 'PH', 'ph']),
      distance: SecureIntegrationService.propertyNumber(properties, -1, ['Dist', 'distance', 'Distance']),
      fanGear: Math.trunc(SecureIntegrationService.propertyNumber(properties, 0, ['Fengd', 'fengdegree', 'fanGear'])),
      lightOn: SecureIntegrationService.propertyBool(properties, ['LightSt', 'LampST', 'light']),
      boardOn: SecureIntegrationService.propertyBool(properties, ['DangGuangBan', 'board', 'windBoardStatus']),
      waterPumpOn: SecureIntegrationService.propertyBool(properties, ['Bump', 'BUMP', 'bump', 'pump']),
      medicinePumpOn: SecureIntegrationService.propertyBool(properties, ['MedicinePump', 'MedicineBump', 'DrugPump', 'YaoPump', 'YaoBump']),
      aiWarning: SecureIntegrationService.propertyText(properties, '', ['AIWarning', 'aiWarning']),
      growthStage: Math.trunc(SecureIntegrationService.propertyNumber(properties, 0, ['GrowthStage', 'State', 'growthStage'])),
      updatedAt: eventTime
    };
  }

  private static propertyNumber(properties: Record<string, Object>, fallback: number, keys: string[]): number {
    const text = SecureIntegrationService.propertyText(properties, '', keys);
    if (text.length === 0) {
      return fallback;
    }
    const parsed = Number(SecureIntegrationService.extractNumber(text));
    return parsed === parsed ? parsed : fallback;
  }

  private static propertyBool(properties: Record<string, Object>, keys: string[]): boolean {
    const value = SecureIntegrationService.propertyText(properties, '', keys);
    return value === '1' ||
      value === 'true' ||
      value === 'ON' ||
      value === 'on' ||
      value === '寮€';
  }

  private static propertyText(properties: Record<string, Object>, fallback: string, keys: string[]): string {
    for (let i = 0; i < keys.length; i++) {
      const value = properties[keys[i]];
      if (value !== undefined && value !== null) {
        return SecureIntegrationService.cleanCloudText(`${value}`);
      }
    }
    return fallback;
  }

  private static firstNumber(raw: string, fallback: number, keys: string[]): number {
    for (let i = 0; i < keys.length; i++) {
      const value = SecureIntegrationService.extract(raw, keys[i]);
      if (value.length > 0) {
        const parsed = Number(SecureIntegrationService.extractNumber(value));
        if (parsed === parsed) {
          return parsed;
        }
      }
    }
    return fallback;
  }

  private static firstInteger(raw: string, fallback: number, keys: string[]): number {
    return Math.trunc(SecureIntegrationService.firstNumber(raw, fallback, keys));
  }

  private static firstBool(raw: string, keys: string[]): boolean {
    const value = SecureIntegrationService.firstText(raw, '', keys);
    return value === '1' ||
      value === 'true' ||
      value === 'ON' ||
      value === 'on' ||
      value === '开';
  }

  private static firstText(raw: string, fallback: string, keys: string[]): string {
    for (let i = 0; i < keys.length; i++) {
      const value = SecureIntegrationService.extract(raw, keys[i]);
      if (value.length > 0) {
        return SecureIntegrationService.cleanCloudText(value);
      }
    }
    return fallback;
  }

  private static extractNumber(rawValue: string): string {
    const cleaned = SecureIntegrationService.cleanCloudText(rawValue);
    let result = '';
    for (let i = 0; i < cleaned.length; i++) {
      const ch = cleaned.charAt(i);
      if ((ch >= '0' && ch <= '9') || ch === '.' || ch === '-') {
        result += ch;
      }
    }
    return result.length > 0 ? result : '0';
  }

  private static cleanCloudText(value: string): string {
    let cleaned = value.trim();
    cleaned = cleaned.replace(/\\/g, '');
    while (cleaned.startsWith('"') && cleaned.length > 1) {
      cleaned = cleaned.substring(1);
    }
    while (cleaned.endsWith('"') && cleaned.length > 1) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    return cleaned.trim();
  }

  private static extract(raw: string, key: string): string {
    const pattern = new RegExp(`"${key}"\\s*:\\s*("((?:\\\\.|[^"])*)"|-?\\d+(?:\\.\\d+)?|true|false|null)`);
    const match = pattern.exec(raw || '');
    if (!match) {
      return '';
    }
    if (match[2] !== undefined) {
      return match[2];
    }
    if (match[1] === 'null') {
      return '';
    }
    return match[1] || '';
  }

  private static headerValue(header: Object, name: string): string {
    const map = header as Record<string, Object>;
    const lowerName = name.toLowerCase();
    const keys = Object.keys(map);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      if (key.toLowerCase() === lowerName) {
        const value = map[key];
        if (typeof value === 'string') {
          return value;
        }
        if (Array.isArray(value) && value.length > 0) {
          return `${value[0]}`;
        }
        return `${value}`;
      }
    }
    return '';
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
