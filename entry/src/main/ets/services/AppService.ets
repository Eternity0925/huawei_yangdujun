import {
  AiSuggestionModel,
  AlarmRecord,
  Device,
  EnvironmentPoint,
  Greenhouse,
  SensorData,
  SettingItem,
  ThresholdConfig,
  User
} from '../models/AppModels';
import { AppState } from '../storage/AppState';
import { SecureIntegrationService } from './SecureIntegrationService';

export class AppService {
  static async login(phone: string, password: string): Promise<boolean> {
    return AppState.login(phone, password);
  }

  static async register(phone: string, password: string): Promise<boolean> {
    return AppState.register(phone, password);
  }

  static resetPassword(phone: string, newPassword: string): boolean {
    return AppState.resetPassword(phone, newPassword);
  }

  static logout(): void {
    AppState.logout();
  }

  static updateCurrentUser(nickname: string, avatar: string = ''): boolean {
    return AppState.updateUserInfo(nickname, avatar);
  }

  static getCurrentUser(): User | null {
    return AppState.currentUser;
  }

  static getGreenhouses(): Greenhouse[] {
    return AppState.greenhouses;
  }

  static addGreenhouse(name: string, location: string, area: string): Greenhouse {
    const greenhouse: Greenhouse = {
      id: `greenhouse-${Date.now()}`,
      name,
      location,
      area,
      stage: '出菇管理期'
    };
    AppState.greenhouses.push(greenhouse);
    AppState.updateSensorData(greenhouse.id, AppState.getSensorData('default'));
    AppService.syncDevicesFromSensor(greenhouse.id, AppState.getSensorData(greenhouse.id));
    return greenhouse;
  }

  static removeGreenhouse(greenhouseId: string): void {
    AppState.greenhouses = AppState.greenhouses.filter((item: Greenhouse) => item.id !== greenhouseId);
    AppState.devices = AppState.devices.filter((item: Device) => item.greenhouseId !== greenhouseId);
    AppState.alarms = AppState.alarms.filter((item: AlarmRecord) => item.greenhouseId !== greenhouseId);
  }

  static getSensorData(greenhouseId: string): SensorData {
    return AppState.getSensorData(greenhouseId);
  }

  static updateSensorData(greenhouseId: string, data: SensorData): void {
    AppState.updateSensorData(greenhouseId, data);
    AppService.syncDevicesFromSensor(greenhouseId, data);
  }

  static async refreshSensorFromBackend(greenhouseId: string): Promise<SensorData> {
    const shadow = await SecureIntegrationService.fetchHuaweiIoTShadow(greenhouseId);
    if (shadow.success && shadow.sensor) {
      AppState.updateSensorData(greenhouseId, shadow.sensor);
      AppService.syncDevicesFromSensor(greenhouseId, shadow.sensor);
    }
    return AppState.getSensorData(greenhouseId);
  }

  static setDeviceStatus(greenhouseId: string, key: string, enabled: boolean): SensorData {
    const data = AppState.getSensorData(greenhouseId);
    const next: SensorData = {
      airTemperature: data.airTemperature,
      airHumidity: data.airHumidity,
      soilTemperature: data.soilTemperature,
      soilHumidity: data.soilHumidity,
      light: data.light,
      co2: data.co2,
      o2: data.o2,
      ph: data.ph,
      fanGear: data.fanGear,
      lightOn: key === 'light' ? enabled : data.lightOn,
      boardOn: key === 'board' ? enabled : data.boardOn,
      waterPumpOn: key === 'water' ? enabled : data.waterPumpOn,
      medicinePumpOn: key === 'medicine' ? enabled : data.medicinePumpOn,
      aiWarning: data.aiWarning,
      growthStage: data.growthStage,
      updatedAt: data.updatedAt
    };
    AppState.updateSensorData(greenhouseId, next);
    AppService.syncDevicesFromSensor(greenhouseId, next);
    return next;
  }

  static setFanGear(greenhouseId: string, gear: number): SensorData {
    const data = AppState.getSensorData(greenhouseId);
    const next: SensorData = {
      airTemperature: data.airTemperature,
      airHumidity: data.airHumidity,
      soilTemperature: data.soilTemperature,
      soilHumidity: data.soilHumidity,
      light: data.light,
      co2: data.co2,
      o2: data.o2,
      ph: data.ph,
      fanGear: Math.max(0, Math.min(9, gear)),
      lightOn: data.lightOn,
      boardOn: data.boardOn,
      waterPumpOn: data.waterPumpOn,
      medicinePumpOn: data.medicinePumpOn,
      aiWarning: data.aiWarning,
      growthStage: data.growthStage,
      updatedAt: data.updatedAt
    };
    AppState.updateSensorData(greenhouseId, next);
    AppService.syncDevicesFromSensor(greenhouseId, next);
    return next;
  }

  static getDevices(greenhouseId: string): Device[] {
    return AppState.devices.filter((device: Device) => device.greenhouseId === greenhouseId);
  }

  static getAlarms(greenhouseId?: string): AlarmRecord[] {
    if (!greenhouseId) {
      return AppState.alarms;
    }
    return AppState.alarms.filter((alarm: AlarmRecord) => alarm.greenhouseId === greenhouseId);
  }

  static getAlarmById(alarmId: string): AlarmRecord | null {
    const alarm = AppState.alarms.find((item: AlarmRecord) => item.id === alarmId);
    return alarm || null;
  }

  static handleAlarm(alarmId: string): boolean {
    const user = AppState.currentUser;
    return AppState.handleAlarm(alarmId, user ? user.nickname : '未知用户');
  }

  static getThreshold(greenhouseId: string): ThresholdConfig {
    return AppState.getThreshold(greenhouseId);
  }

  static updateThreshold(greenhouseId: string, threshold: ThresholdConfig): void {
    AppState.updateThreshold(greenhouseId, threshold);
  }

  static getHistory(greenhouseId: string, limit: number = 24): EnvironmentPoint[] {
    return AppState.getHistory(greenhouseId, limit);
  }

  static getSettings(): SettingItem[] {
    return AppState.settings;
  }

  static updateSetting(id: string, enabled: boolean): void {
    AppState.updateSetting(id, enabled);
  }

  static submitFeedback(content: string): boolean {
    return AppState.addFeedback(content);
  }

  static buildAiPrompt(greenhouse: Greenhouse, data: SensorData): string {
    const history = AppState.getHistory(greenhouse.id, 24);
    const trend = history.length > 0 ? `近 24 次记录共 ${history.length} 条。` : '暂无历史趋势数据。';
    return `请作为羊肚菌智慧大棚种植助手，给出结构化建议。
大棚ID：${greenhouse.id}
大棚名称：${greenhouse.name}
生长阶段：${greenhouse.stage}
空气温度：${data.airTemperature}℃，空气湿度：${data.airHumidity}%
土壤温度：${data.soilTemperature}℃，土壤湿度：${data.soilHumidity}%
光照：${data.light}lux
CO2：${data.co2}ppm
pH：${data.ph}
风机档位：${data.fanGear}
灯：${data.lightOn ? 'ON' : 'OFF'}
挡光板：${data.boardOn ? 'ON' : 'OFF'}
水泵：${data.waterPumpOn ? 'ON' : 'OFF'}
药泵：${data.medicinePumpOn ? 'ON' : 'OFF'}
趋势：${trend}
请按“风险等级、核心问题、紧急操作、详细建议”四段返回。`;
  }

  static buildAiSuggestion(greenhouse: Greenhouse, data: SensorData): string {
    const risk = data.airHumidity < 80 || data.soilHumidity < 65 || data.co2 > 900 ? '中' : '低';
    return `风险等级：${risk}
核心问题：${greenhouse.name} 当前处于${greenhouse.stage}，需要重点稳定温湿度、通风和二氧化碳浓度。
紧急操作：保持土壤湿度在 65%-78%，空气湿度在 80%-92%，风机档位控制在 1-3 档。
详细建议：当前空气温度 ${data.airTemperature}℃，空气湿度 ${data.airHumidity}%，土壤湿度 ${data.soilHumidity}%，CO2 ${data.co2}ppm。建议每 2 小时复核一次环境数据，发现湿度持续下降时优先检查水泵和喷淋。`;
  }

  static async requestAiSuggestion(greenhouse: Greenhouse, data: SensorData): Promise<string> {
    return SecureIntegrationService.requestAiSuggestion(greenhouse, data, AppService.buildAiPrompt(greenhouse, data));
  }

  static parseAiSuggestion(text: string): AiSuggestionModel {
    return AppState.parseAiSuggestion(text);
  }

  static async requestAiChat(text: string): Promise<string> {
    const answer = await SecureIntegrationService.requestAiChat(text, AppState.chatHistory);
    AppState.chatHistory = `${AppState.chatHistory}\n我：${text}\nAI：${answer}`.trim();
    if (AppState.chatHistory.length > 5000) {
      AppState.chatHistory = AppState.chatHistory.substring(AppState.chatHistory.length - 5000);
    }
    return answer;
  }

  static getChatHistory(): string {
    return AppState.chatHistory;
  }

  static async sendDeviceCommand(greenhouseId: string, commandName: string, value: string | number | boolean): Promise<boolean> {
    return SecureIntegrationService.sendHuaweiIoTCommand({ greenhouseId, commandName, value });
  }

  private static syncDevicesFromSensor(greenhouseId: string, data: SensorData): void {
    AppService.upsertDevice(greenhouseId, 'light_1', '灯泡', 'light', data.lightOn ? 'ON' : 'OFF', data.lightOn);
    AppService.upsertDevice(greenhouseId, 'board_1', '挡光板', 'board', data.boardOn ? 'ON' : 'OFF', data.boardOn);
    AppService.upsertDevice(greenhouseId, 'fan_1', '风机', 'fan', `${data.fanGear}档`, data.fanGear > 0);
    AppService.upsertDevice(greenhouseId, 'water_pump_1', '水泵', 'water', data.waterPumpOn ? 'ON' : 'OFF', data.waterPumpOn);
    AppService.upsertDevice(greenhouseId, 'medicine_pump_1', '药泵', 'medicine', data.medicinePumpOn ? 'ON' : 'OFF', data.medicinePumpOn);
  }

  private static upsertDevice(greenhouseId: string, id: string, name: string, type: string, status: string, enabled: boolean): void {
    const key = `${greenhouseId}-${id}`;
    const device = AppState.devices.find((item: Device) => item.id === key);
    if (device) {
      device.status = status;
      device.enabled = enabled;
      return;
    }
    AppState.devices.push({ id: key, name, type, status, enabled, greenhouseId });
  }
}
