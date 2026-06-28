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

interface StoredUser extends User {
  password: string;
}

interface SensorEntry {
  greenhouseId: string;
  data: SensorData;
}

interface ThresholdEntry {
  greenhouseId: string;
  data: ThresholdConfig;
}

export class AppState {
  static currentUser: User | null = null;

  static users: StoredUser[] = [
    {
      id: 'user-demo',
      phone: '13800138000',
      password: 'abc12345',
      token: 'local_demo_token',
      nickname: '管理员',
      avatar: ''
    }
  ];

  static greenhouses: Greenhouse[] = [
    { id: 'default', name: '默认大棚', location: '示范基地 A 区', area: '100', stage: '出菇管理期' },
    { id: 'greenhouse-2', name: '羊肚菌一号棚', location: '示范基地 A 区', area: '180', stage: '原基形成期' }
  ];

  static sensors: SensorEntry[] = [
    {
      greenhouseId: 'default',
      data: {
        airTemperature: 18.6,
        airHumidity: 86,
        soilTemperature: 15.2,
        soilHumidity: 72,
        light: 1200,
        co2: 640,
        o2: 20.8,
        ph: 6.8,
        fanGear: 2,
        lightOn: false,
        boardOn: true,
        waterPumpOn: false,
        medicinePumpOn: false,
        aiWarning: '正常',
        growthStage: 4,
        updatedAt: '2026-06-24 09:30'
      }
    },
    {
      greenhouseId: 'greenhouse-2',
      data: {
        airTemperature: 17.4,
        airHumidity: 82,
        soilTemperature: 14.7,
        soilHumidity: 69,
        light: 980,
        co2: 710,
        o2: 20.6,
        ph: 6.5,
        fanGear: 1,
        lightOn: false,
        boardOn: false,
        waterPumpOn: true,
        medicinePumpOn: false,
        aiWarning: '正常',
        growthStage: 3,
        updatedAt: '2026-06-24 09:30'
      }
    }
  ];

  static devices: Device[] = [
    { id: 'default-light_1', name: '灯', type: 'light', status: 'OFF', greenhouseId: 'default', enabled: false },
    { id: 'default-board_1', name: '挡光板', type: 'board', status: 'ON', greenhouseId: 'default', enabled: true },
    { id: 'default-fan_1', name: '风机', type: 'fan', status: '2档', greenhouseId: 'default', enabled: true },
    { id: 'default-water_pump_1', name: '水泵', type: 'water', status: 'OFF', greenhouseId: 'default', enabled: false },
    { id: 'default-medicine_pump_1', name: '药泵', type: 'medicine', status: 'OFF', greenhouseId: 'default', enabled: false }
  ];

  static alarms: AlarmRecord[] = [
    {
      id: 'alarm-1',
      greenhouseId: 'default',
      greenhouseName: '默认大棚',
      device: '湿度传感器',
      title: '空气湿度过低告警',
      content: '空气湿度低于阈值，请及时检查喷淋和通风状态。',
      level: '中',
      status: '待处理',
      createdAt: '2026-06-24 09:30'
    }
  ];

  static thresholds: ThresholdEntry[] = [
    {
      greenhouseId: 'default',
      data: {
        tempMin: 12,
        tempMax: 22,
        airHumMin: 80,
        airHumMax: 92,
        soilTempMin: 10,
        soilTempMax: 20,
        humMin: 65,
        humMax: 78,
        co2Min: 400,
        co2Max: 900,
        o2Min: 19,
        o2Max: 22,
        phMin: 6,
        phMax: 7,
        lightMin: 500,
        lightMax: 1800
      }
    }
  ];

  static history: EnvironmentPoint[] = [];

  static settings: SettingItem[] = [
    { id: 'alarmPush', title: '告警提醒', description: '环境异常时提醒管理人员', enabled: true },
    { id: 'autoSync', title: '自动同步', description: '进入页面时刷新云端数据', enabled: true },
    { id: 'ai', title: 'AI 种植建议', description: '根据环境数据生成操作建议', enabled: true },
    { id: 'voice', title: '语音识别', description: '按住说话后识别并询问 AI', enabled: true }
  ];

  static chatHistory: string = '';

  static isLoggedIn(): boolean {
    return AppState.currentUser !== null;
  }

  static login(phone: string, password: string): boolean {
    const user = AppState.findUserByPhone(phone);
    if (!user || user.password !== password) {
      return false;
    }
    user.token = AppState.generateToken();
    AppState.currentUser = AppState.toPublicUser(user);
    return true;
  }

  static register(phone: string, password: string): boolean {
    if (!AppState.isValidPhone(phone) || !AppState.isStrongPassword(password)) {
      return false;
    }
    if (AppState.findUserByPhone(phone)) {
      return false;
    }
    const user: StoredUser = {
      id: AppState.generateId('user'),
      phone,
      password,
      token: AppState.generateToken(),
      nickname: `用户${phone.substring(phone.length - 4)}`,
      avatar: ''
    };
    AppState.users.push(user);
    AppState.currentUser = AppState.toPublicUser(user);
    return true;
  }

  static logout(): void {
    AppState.currentUser = null;
  }

  static resetPassword(phone: string, newPassword: string): boolean {
    const user = AppState.findUserByPhone(phone);
    if (!user || !AppState.isStrongPassword(newPassword)) {
      return false;
    }
    user.password = newPassword;
    return true;
  }

  static updateUserInfo(nickname: string, avatar: string = ''): boolean {
    if (!AppState.currentUser) {
      return false;
    }
    const user = AppState.findUserByPhone(AppState.currentUser.phone);
    if (!user) {
      return false;
    }
    user.nickname = nickname;
    user.avatar = avatar;
    AppState.currentUser = AppState.toPublicUser(user);
    return true;
  }

  static isValidPhone(phone: string): boolean {
    return /^1\d{10}$/.test(phone);
  }

  static isStrongPassword(password: string): boolean {
    return /[A-Za-z]/.test(password) && /\d/.test(password) && password.length >= 8;
  }

  static getSensorData(greenhouseId: string): SensorData {
    const entry = AppState.findSensorByGreenhouseId(greenhouseId);
    if (entry) {
      return AppState.cloneSensor(entry.data);
    }
    const fallback = AppState.findSensorByGreenhouseId('default');
    return AppState.cloneSensor(fallback!.data);
  }

  static updateSensorData(greenhouseId: string, data: SensorData): void {
    const next = AppState.cloneSensor(data);
    next.updatedAt = AppState.nowText();
    const entry = AppState.findSensorByGreenhouseId(greenhouseId);
    if (entry) {
      entry.data = next;
    } else {
      AppState.sensors.push({ greenhouseId, data: next });
    }
    AppState.saveEnvironmentPoint(greenhouseId, next);
    AppState.checkAlarmThresholds(greenhouseId, next);
  }

  static getThreshold(greenhouseId: string): ThresholdConfig {
    const entry = AppState.thresholds.find((item: ThresholdEntry) => item.greenhouseId === greenhouseId);
    if (entry) {
      return AppState.cloneThreshold(entry.data);
    }
    return AppState.cloneThreshold(AppState.thresholds[0].data);
  }

  static updateThreshold(greenhouseId: string, data: ThresholdConfig): void {
    const next = AppState.cloneThreshold(data);
    const entry = AppState.thresholds.find((item: ThresholdEntry) => item.greenhouseId === greenhouseId);
    if (entry) {
      entry.data = next;
    } else {
      AppState.thresholds.push({ greenhouseId, data: next });
    }
  }

  static saveEnvironmentPoint(greenhouseId: string, data: SensorData): void {
    AppState.history.push({
      greenhouseId,
      time: AppState.nowText(),
      temperature: data.airTemperature,
      humidity: data.airHumidity,
      soilTemperature: data.soilTemperature,
      soilHumidity: data.soilHumidity,
      light: data.light,
      co2: data.co2,
      o2: data.o2,
      ph: data.ph
    });
    if (AppState.history.length > 240) {
      AppState.history.splice(0, AppState.history.length - 240);
    }
  }

  static getHistory(greenhouseId: string, limit: number = 24): EnvironmentPoint[] {
    const list = AppState.history.filter((item: EnvironmentPoint) => item.greenhouseId === greenhouseId);
    return list.slice(Math.max(0, list.length - limit));
  }

  static handleAlarm(alarmId: string, handlerName: string): boolean {
    const alarm = AppState.alarms.find((item: AlarmRecord) => item.id === alarmId);
    if (!alarm) {
      return false;
    }
    alarm.status = '已处理';
    alarm.handlerName = handlerName;
    alarm.handledAt = AppState.nowText();
    return true;
  }

  static parseAiSuggestion(text: string): AiSuggestionModel {
    const normalized = text || '';
    return {
      riskLevel: AppState.pickSection(normalized, '风险等级', '中'),
      coreProblem: AppState.pickSection(normalized, '核心问题', '当前环境数据整体稳定，建议继续观察关键指标。'),
      urgentAction: AppState.pickSection(normalized, '紧急操作', '保持通风、湿度和光照处于当前设定范围。'),
      detailAdvice: AppState.pickSection(normalized, '详细建议', normalized || '暂无详细建议。')
    };
  }

  private static checkAlarmThresholds(greenhouseId: string, data: SensorData): void {
    const greenhouse = AppState.greenhouses.find((item: Greenhouse) => item.id === greenhouseId);
    const greenhouseName = greenhouse ? greenhouse.name : '默认大棚';
    const threshold = AppState.getThreshold(greenhouseId);
    AppState.tryGenerateAlarm(greenhouseId, greenhouseName, '温度传感器', data.airTemperature < threshold.tempMin, '空气温度过低告警');
    AppState.tryGenerateAlarm(greenhouseId, greenhouseName, '温度传感器', data.airTemperature > threshold.tempMax, '空气温度过高告警');
    AppState.tryGenerateAlarm(greenhouseId, greenhouseName, '湿度传感器', data.airHumidity < threshold.airHumMin, '空气湿度过低告警');
    AppState.tryGenerateAlarm(greenhouseId, greenhouseName, '湿度传感器', data.airHumidity > threshold.airHumMax, '空气湿度过高告警');
    AppState.tryGenerateAlarm(greenhouseId, greenhouseName, '土壤温度传感器', data.soilTemperature < threshold.soilTempMin, '土壤温度过低告警');
    AppState.tryGenerateAlarm(greenhouseId, greenhouseName, '土壤温度传感器', data.soilTemperature > threshold.soilTempMax, '土壤温度过高告警');
    AppState.tryGenerateAlarm(greenhouseId, greenhouseName, '土壤湿度传感器', data.soilHumidity < threshold.humMin, '土壤湿度过低告警');
    AppState.tryGenerateAlarm(greenhouseId, greenhouseName, '土壤湿度传感器', data.soilHumidity > threshold.humMax, '土壤湿度过高告警');
    AppState.tryGenerateAlarm(greenhouseId, greenhouseName, '二氧化碳传感器', data.co2 < threshold.co2Min, '二氧化碳浓度过低告警');
    AppState.tryGenerateAlarm(greenhouseId, greenhouseName, '二氧化碳传感器', data.co2 > threshold.co2Max, '二氧化碳浓度过高告警');
    AppState.tryGenerateAlarm(greenhouseId, greenhouseName, '光照传感器', data.light < threshold.lightMin, '光照强度过低告警');
    AppState.tryGenerateAlarm(greenhouseId, greenhouseName, '光照传感器', data.light > threshold.lightMax, '光照强度过高告警');
  }

  private static tryGenerateAlarm(greenhouseId: string, greenhouseName: string, device: string, condition: boolean, content: string): void {
    if (!condition) {
      return;
    }
    const exists = AppState.alarms.some((item: AlarmRecord) =>
      item.greenhouseId === greenhouseId && item.device === device && item.content === content && item.status !== '已处理');
    if (exists) {
      return;
    }
    AppState.alarms.unshift({
      id: AppState.generateId('alarm'),
      greenhouseId,
      greenhouseName,
      device,
      title: content,
      content,
      level: '中',
      status: '待处理',
      createdAt: AppState.nowText()
    });
  }

  private static findUserByPhone(phone: string): StoredUser | null {
    for (let i = 0; i < AppState.users.length; i++) {
      if (AppState.users[i].phone === phone) {
        return AppState.users[i];
      }
    }
    return null;
  }

  private static findSensorByGreenhouseId(greenhouseId: string): SensorEntry | null {
    for (let i = 0; i < AppState.sensors.length; i++) {
      if (AppState.sensors[i].greenhouseId === greenhouseId) {
        return AppState.sensors[i];
      }
    }
    return null;
  }

  private static toPublicUser(user: StoredUser): User {
    return {
      id: user.id,
      phone: user.phone,
      nickname: user.nickname,
      token: user.token,
      avatar: user.avatar
    };
  }

  private static cloneSensor(data: SensorData): SensorData {
    return {
      airTemperature: data.airTemperature,
      airHumidity: data.airHumidity,
      soilTemperature: data.soilTemperature,
      soilHumidity: data.soilHumidity,
      light: data.light,
      co2: data.co2,
      o2: data.o2,
      ph: data.ph,
      fanGear: data.fanGear,
      lightOn: data.lightOn,
      boardOn: data.boardOn,
      waterPumpOn: data.waterPumpOn,
      medicinePumpOn: data.medicinePumpOn,
      aiWarning: data.aiWarning,
      growthStage: data.growthStage,
      updatedAt: data.updatedAt
    };
  }

  private static cloneThreshold(data: ThresholdConfig): ThresholdConfig {
    return {
      tempMin: data.tempMin,
      tempMax: data.tempMax,
      airHumMin: data.airHumMin,
      airHumMax: data.airHumMax,
      soilTempMin: data.soilTempMin,
      soilTempMax: data.soilTempMax,
      humMin: data.humMin,
      humMax: data.humMax,
      co2Min: data.co2Min,
      co2Max: data.co2Max,
      o2Min: data.o2Min,
      o2Max: data.o2Max,
      phMin: data.phMin,
      phMax: data.phMax,
      lightMin: data.lightMin,
      lightMax: data.lightMax
    };
  }

  private static pickSection(text: string, name: string, fallback: string): string {
    const lines = text.split('\n');
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].replace('：', ':');
      if (line.indexOf(name) >= 0) {
        const index = line.indexOf(':');
        if (index >= 0 && index + 1 < line.length) {
          return line.substring(index + 1).trim();
        }
      }
    }
    return fallback;
  }

  private static generateId(prefix: string): string {
    return `${prefix}-${Date.now()}-${Math.floor(Math.random() * 100000)}`;
  }

  private static generateToken(): string {
    return `local_${Date.now()}_${Math.floor(Math.random() * 100000)}`;
  }

  private static nowText(): string {
    return new Date().toLocaleString();
  }
}
