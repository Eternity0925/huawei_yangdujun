export interface User {
  id: string;
  phone: string;
  nickname: string;
  token: string;
  avatar?: string;
}

export interface Greenhouse {
  id: string;
  name: string;
  location: string;
  area: string;
  stage: string;
}

export interface SensorData {
  airTemperature: number;
  airHumidity: number;
  soilTemperature: number;
  soilHumidity: number;
  light: number;
  co2: number;
  o2: number;
  ph: number;
  distance: number;
  fanGear: number;
  lightOn: boolean;
  boardOn: boolean;
  waterPumpOn: boolean;
  medicinePumpOn: boolean;
  aiWarning: string;
  growthStage: number;
  updatedAt: string;
}

export interface Device {
  id: string;
  name: string;
  type: string;
  status: string;
  greenhouseId: string;
  enabled: boolean;
}

export interface AlarmRecord {
  id: string;
  greenhouseId: string;
  greenhouseName: string;
  device: string;
  title: string;
  content: string;
  level: string;
  status: string;
  createdAt: string;
  handledAt?: string;
  handlerName?: string;
}

export interface SettingItem {
  id: string;
  title: string;
  description: string;
  enabled: boolean;
}

export interface FeedbackRecord {
  id: string;
  content: string;
  createdAt: string;
  userPhone: string;
}

export interface ThresholdConfig {
  tempMin: number;
  tempMax: number;
  airHumMin: number;
  airHumMax: number;
  soilTempMin: number;
  soilTempMax: number;
  humMin: number;
  humMax: number;
  co2Min: number;
  co2Max: number;
  o2Min: number;
  o2Max: number;
  phMin: number;
  phMax: number;
  lightMin: number;
  lightMax: number;
}

export interface EnvironmentPoint {
  greenhouseId: string;
  time: string;
  temperature: number;
  humidity: number;
  soilTemperature: number;
  soilHumidity: number;
  light: number;
  co2: number;
  o2: number;
  ph: number;
}

export interface AiSuggestionModel {
  riskLevel: string;
  coreProblem: string;
  urgentAction: string;
  detailAdvice: string;
}
