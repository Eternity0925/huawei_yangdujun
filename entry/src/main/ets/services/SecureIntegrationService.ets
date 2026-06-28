import { http } from '@kit.NetworkKit';
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
  static async requestAiSuggestion(greenhouse: Greenhouse, sensor: SensorData, prompt: string): Promise<string> {
    if (!SecureEndpointConfig.hasBackend()) {
      return SecureIntegrationService.localAiSuggestion(greenhouse, sensor);
    }

    const request: AiSuggestionRequest = {
      greenhouse,
      sensor,
      prompt
    };
    const raw = await SecureIntegrationService.postJson(SecureEndpointConfig.AI_SUGGESTION_PATH, JSON.stringify(request));
    const result = JSON.parse(raw) as AiSuggestionResponse;
    return result.suggestion || SecureIntegrationService.localAiSuggestion(greenhouse, sensor);
  }

  static async requestAiChat(text: string, history: string): Promise<string> {
    if (!SecureEndpointConfig.hasBackend()) {
      return `我已收到你的问题：“${text}”。当前后端代理未配置，正式接入后这里会调用 DeepSeek 返回完整回答。`;
    }

    const request: AiTextRequest = { text, history };
    const raw = await SecureIntegrationService.postJson(SecureEndpointConfig.AI_CHAT_PATH, JSON.stringify(request));
    const result = JSON.parse(raw) as AiTextResponse;
    return result.answer || 'AI 暂未返回有效回答，请稍后重试。';
  }

  static async sendHuaweiIoTCommand(command: DeviceCommand): Promise<boolean> {
    if (!SecureEndpointConfig.hasBackend()) {
      return true;
    }

    const raw = await SecureIntegrationService.postJson(SecureEndpointConfig.HUAWEI_IOT_COMMAND_PATH, JSON.stringify(command));
    const result = JSON.parse(raw) as SuccessResponse;
    return result.success;
  }

  static async fetchHuaweiIoTShadow(greenhouseId: string): Promise<ShadowResponse> {
    if (!SecureEndpointConfig.hasBackend()) {
      return { success: false };
    }

    const raw = await SecureIntegrationService.postJson(
      SecureEndpointConfig.HUAWEI_IOT_SHADOW_PATH,
      JSON.stringify({ greenhouseId })
    );
    return JSON.parse(raw) as ShadowResponse;
  }

  static async recognizeSpeechBase64(audioBase64: string): Promise<string> {
    if (!SecureEndpointConfig.hasBackend()) {
      return '语音识别后端未配置';
    }

    const raw = await SecureIntegrationService.postJson(
      SecureEndpointConfig.HUAWEI_ASR_PATH,
      JSON.stringify({ audioBase64 })
    );
    const result = JSON.parse(raw) as AiTextResponse;
    return result.answer || '';
  }

  static async getBaiduMapToken(): Promise<string> {
    if (!SecureEndpointConfig.hasBackend()) {
      return '';
    }

    const raw = await SecureIntegrationService.postJson(SecureEndpointConfig.BAIDU_MAP_TOKEN_PATH, '{}');
    const result = JSON.parse(raw) as TokenResponse;
    return result.token;
  }

  private static localAiSuggestion(greenhouse: Greenhouse, sensor: SensorData): string {
    const risk = sensor.airHumidity < 80 || sensor.soilHumidity < 65 || sensor.co2 > 900 ? '中' : '低';
    return `风险等级：${risk}
核心问题：${greenhouse.name} 当前处于${greenhouse.stage}，需要重点稳定温湿度、通风和二氧化碳浓度。
紧急操作：保持土壤湿度在 65%-78%，空气湿度在 80%-92%，风机档位控制在 1-3 档。
详细建议：当前空气温度 ${sensor.airTemperature}℃，空气湿度 ${sensor.airHumidity}%，土壤湿度 ${sensor.soilHumidity}%，CO2 ${sensor.co2}ppm。建议每 2 小时复核一次环境数据，发现湿度持续下降时优先检查水泵和喷淋。`;
  }

  private static async postJson(path: string, body: string): Promise<string> {
    const request = http.createHttp();
    try {
      const response = await request.request(`${SecureEndpointConfig.API_BASE_URL}${path}`, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json'
        },
        extraData: body,
        connectTimeout: 30000,
        readTimeout: 60000
      });

      if (typeof response.result === 'string') {
        return response.result;
      }
      return '{}';
    } finally {
      request.destroy();
    }
  }
}
