export type EmployeeStatus = 'available' | 'busy' | 'offduty';
export type Priority = 'high' | 'medium' | 'low';
export type UnitType = 'technician' | 'engineer' | 'supervisor' | 'emergency';
export type InfrastructureStatus = 'good' | 'warning' | 'critical';
export type InfrastructureType = 'windturbine' | 'transformer' | 'substation' | 'dam' | 'hydrant' | 'watertower' | 'powerline' | 'pumpstation';
export type JobRole = 'Elektriker' | 'Gas und Wasser Techniker' | 'Dispatcher' | 'Manager' | 'Praktikant';

export interface Employee {
  id: string;
  name: string;
  badge: string;
  unit: UnitType;
  status: EmployeeStatus;
  location: string;
  currentCall?: string;
  specialty?: string;
  jobRole: JobRole;
}

export interface DispatchCall {
  id: string;
  code: string;
  title: string;
  description: string;
  location: string;
  coordinates: { x: number; y: number };
  priority: Priority;
  timestamp: string;
  assignedUnits: string[];
  status: 'pending' | 'active' | 'resolved';
  type: 'power' | 'water' | 'emergency';
}

export interface DistrictStatus {
  id: string;
  name: string;
  power: InfrastructureStatus;
  powerValue: number;
  water: InfrastructureStatus;
  waterValue: number;
  outages: number;
}

export interface InfrastructureAsset {
  id: string;
  name: string;
  type: InfrastructureType;
  coordinates: { x: number; y: number };
  status: InfrastructureStatus;
  capacity?: number;
  currentLoad?: number;
  lastMaintenance: string;
  nextMaintenance: string;
}

export interface MapMarker {
  id: string;
  x: number;
  y: number;
  type: UnitType | 'call' | InfrastructureType;
  label: string;
  priority?: Priority;
  status?: InfrastructureStatus;
}
