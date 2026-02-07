import type { Employee, DispatchCall, DistrictStatus, InfrastructureAsset, MapMarker } from '@/types';

export const employees: Employee[] = [
  { id: '1', name: 'M. Schmidt', badge: 'T-142', unit: 'technician', status: 'available', location: 'Umspannwerk Nord', specialty: 'Hochspannung', jobRole: 'Elektriker' },
  { id: '2', name: 'K. Weber', badge: 'E-089', unit: 'engineer', status: 'busy', location: 'Windpark Paleto', currentCall: 'PWR-4521', specialty: 'Windenergie', jobRole: 'Elektriker' },
  { id: '3', name: 'L. Müller', badge: 'T-056', unit: 'technician', status: 'available', location: 'Wasserwerk Downtown', specialty: 'Wasserversorgung', jobRole: 'Gas und Wasser Techniker' },
  { id: '4', name: 'J. Fischer', badge: 'S-023', unit: 'supervisor', status: 'busy', location: 'Staudamm', currentCall: 'PWR-4523', specialty: 'Kontrolle', jobRole: 'Manager' },
  { id: '5', name: 'A. Becker', badge: 'T-201', unit: 'technician', status: 'offduty', location: '-', specialty: 'Transformatoren', jobRole: 'Elektriker' },
  { id: '6', name: 'D. Hoffmann', badge: 'E-078', unit: 'engineer', status: 'available', location: 'Umspannwerk Ost', specialty: 'Netzplanung', jobRole: 'Gas und Wasser Techniker' },
  { id: '7', name: 'R. Klein', badge: 'T-015', unit: 'technician', status: 'available', location: 'Pumpstation Sandy', specialty: 'Pumpen', jobRole: 'Elektriker' },
  { id: '8', name: 'T. Braun', badge: 'EM-167', unit: 'emergency', status: 'busy', location: 'Los Santos West', currentCall: 'PWR-4522', specialty: 'Notfälle', jobRole: 'Dispatcher' },
  { id: '9', name: 'S. Krüger', badge: 'T-031', unit: 'technician', status: 'available', location: 'Wasserturm Vinewood', specialty: 'Wasserdruck', jobRole: 'Gas und Wasser Techniker' },
  { id: '10', name: 'N. Wolf', badge: 'E-092', unit: 'engineer', status: 'offduty', location: '-', specialty: 'Erneuerbare', jobRole: 'Praktikant' },
  { id: '11', name: 'C. Schäfer', badge: 'T-098', unit: 'technician', status: 'available', location: 'Hydranten-Check', specialty: 'Hydranten', jobRole: 'Elektriker' },
  { id: '12', name: 'P. Neumann', badge: 'EM-008', unit: 'emergency', status: 'busy', location: 'Stromausfall LS-West', currentCall: 'PWR-4524', specialty: 'Notfälle', jobRole: 'Dispatcher' },
];

export const dispatchCalls: DispatchCall[] = [
  {
    id: 'PWR-4521',
    code: 'PW-31',
    title: 'Windturbine Wartung',
    description: 'Routine-Wartung Windturbine WT-04, ungewöhnliche Vibrationen gemeldet',
    location: 'Windpark Paleto, Turm 04',
    coordinates: { x: 48, y: 18 },
    priority: 'medium',
    timestamp: '14:32',
    assignedUnits: ['E-089'],
    status: 'active',
    type: 'power'
  },
  {
    id: 'PWR-4522',
    code: 'PW-50',
    title: 'Stromausfall - Kritisch',
    description: 'Großflächiger Stromausfall im Westen, 4 Transformatoren offline',
    location: 'Los Santos West, Grid 7B',
    coordinates: { x: 35, y: 68 },
    priority: 'high',
    timestamp: '14:28',
    assignedUnits: ['EM-167', 'T-142'],
    status: 'active',
    type: 'power'
  },
  {
    id: 'PWR-4523',
    code: 'PW-75',
    title: 'Staudamm Kontrolle',
    description: 'Routine-Kontrolle Schleusentore, Druckanzeige prüfen',
    location: 'Land Act Dam',
    coordinates: { x: 58, y: 42 },
    priority: 'high',
    timestamp: '14:25',
    assignedUnits: ['S-023'],
    status: 'active',
    type: 'water'
  },
  {
    id: 'PWR-4524',
    code: 'PW-63',
    title: 'Transformator Brand',
    description: 'Überhitzter Transformator, Rauchentwicklung gemeldet',
    location: 'Forum Dr, LS-South',
    coordinates: { x: 48, y: 72 },
    priority: 'high',
    timestamp: '14:20',
    assignedUnits: ['EM-008'],
    status: 'active',
    type: 'power'
  },
  {
    id: 'PWR-4525',
    code: 'PW-32',
    title: 'Wasserdruck niedrig',
    description: 'Wasserdruck in Vinewood unter Mindestwert',
    location: 'Vinewood Hills, WT-12',
    coordinates: { x: 42, y: 55 },
    priority: 'medium',
    timestamp: '14:15',
    assignedUnits: [],
    status: 'pending',
    type: 'water'
  },
  {
    id: 'PWR-4526',
    code: 'PW-52',
    title: 'Hydrant defekt',
    description: 'Hydrant undicht, Wasserverlust gemeldet',
    location: 'Downtown, Power St',
    coordinates: { x: 50, y: 65 },
    priority: 'low',
    timestamp: '14:10',
    assignedUnits: ['T-098'],
    status: 'active',
    type: 'water'
  },
];

export const districtStatus: DistrictStatus[] = [
  { id: '1', name: 'Los Santos - Downtown', power: 'good', powerValue: 98, water: 'good', waterValue: 95, outages: 0 },
  { id: '2', name: 'Los Santos - Vinewood', power: 'good', powerValue: 94, water: 'warning', waterValue: 78, outages: 1 },
  { id: '3', name: 'Los Santos - South', power: 'warning', powerValue: 72, water: 'good', waterValue: 88, outages: 2 },
  { id: '4', name: 'Los Santos - East', power: 'good', powerValue: 91, water: 'good', waterValue: 92, outages: 0 },
  { id: '5', name: 'Los Santos - West', power: 'critical', powerValue: 45, water: 'warning', waterValue: 65, outages: 4 },
  { id: '6', name: 'Sandy Shores', power: 'good', powerValue: 87, water: 'good', waterValue: 82, outages: 1 },
  { id: '7', name: 'Grapeseed', power: 'good', powerValue: 93, water: 'good', waterValue: 90, outages: 0 },
  { id: '8', name: 'Paleto Bay', power: 'good', powerValue: 96, water: 'good', waterValue: 94, outages: 0 },
  { id: '9', name: 'Mount Chiliad', power: 'good', powerValue: 89, water: 'good', waterValue: 85, outages: 0 },
  { id: '10', name: 'Fort Zancudo', power: 'good', powerValue: 99, water: 'good', waterValue: 97, outages: 0 },
];

export const infrastructureAssets: InfrastructureAsset[] = [
  { id: 'WT-01', name: 'Windturbine 01', type: 'windturbine', coordinates: { x: 45, y: 15 }, status: 'good', capacity: 2000, currentLoad: 1850, lastMaintenance: '2024-01-15', nextMaintenance: '2024-04-15' },
  { id: 'WT-02', name: 'Windturbine 02', type: 'windturbine', coordinates: { x: 48, y: 16 }, status: 'good', capacity: 2000, currentLoad: 1920, lastMaintenance: '2024-01-20', nextMaintenance: '2024-04-20' },
  { id: 'WT-03', name: 'Windturbine 03', type: 'windturbine', coordinates: { x: 46, y: 18 }, status: 'warning', capacity: 2000, currentLoad: 1200, lastMaintenance: '2024-02-01', nextMaintenance: '2024-03-01' },
  { id: 'WT-04', name: 'Windturbine 04', type: 'windturbine', coordinates: { x: 48, y: 18 }, status: 'warning', capacity: 2000, currentLoad: 800, lastMaintenance: '2023-11-10', nextMaintenance: '2024-02-28' },
  { id: 'UW-N', name: 'Umspannwerk Nord', type: 'substation', coordinates: { x: 52, y: 22 }, status: 'good', capacity: 50000, currentLoad: 42000, lastMaintenance: '2024-01-05', nextMaintenance: '2024-07-05' },
  { id: 'UW-O', name: 'Umspannwerk Ost', type: 'substation', coordinates: { x: 68, y: 45 }, status: 'good', capacity: 45000, currentLoad: 38000, lastMaintenance: '2024-01-10', nextMaintenance: '2024-07-10' },
  { id: 'UW-S', name: 'Umspannwerk Süd', type: 'substation', coordinates: { x: 48, y: 78 }, status: 'critical', capacity: 40000, currentLoad: 15000, lastMaintenance: '2023-10-15', nextMaintenance: '2024-02-15' },
  { id: 'UW-W', name: 'Umspannwerk West', type: 'substation', coordinates: { x: 32, y: 65 }, status: 'critical', capacity: 35000, currentLoad: 8000, lastMaintenance: '2023-09-20', nextMaintenance: '2024-02-20' },
  { id: 'TR-01', name: 'Transformator 01', type: 'transformer', coordinates: { x: 42, y: 55 }, status: 'good', lastMaintenance: '2024-01-08', nextMaintenance: '2024-07-08' },
  { id: 'TR-02', name: 'Transformator 02', type: 'transformer', coordinates: { x: 48, y: 62 }, status: 'good', lastMaintenance: '2024-01-12', nextMaintenance: '2024-07-12' },
  { id: 'TR-03', name: 'Transformator 03', type: 'transformer', coordinates: { x: 52, y: 68 }, status: 'warning', lastMaintenance: '2023-12-01', nextMaintenance: '2024-03-01' },
  { id: 'TR-04', name: 'Transformator 04', type: 'transformer', coordinates: { x: 35, y: 68 }, status: 'critical', lastMaintenance: '2023-08-15', nextMaintenance: '2024-02-15' },
  { id: 'DAM', name: 'Land Act Dam', type: 'dam', coordinates: { x: 58, y: 42 }, status: 'good', capacity: 1000000, currentLoad: 750000, lastMaintenance: '2024-01-01', nextMaintenance: '2024-04-01' },
  { id: 'PS-01', name: 'Pumpstation Sandy', type: 'pumpstation', coordinates: { x: 62, y: 38 }, status: 'good', capacity: 50000, currentLoad: 42000, lastMaintenance: '2024-01-18', nextMaintenance: '2024-07-18' },
  { id: 'PS-02', name: 'Pumpstation LS', type: 'pumpstation', coordinates: { x: 50, y: 70 }, status: 'warning', capacity: 80000, currentLoad: 55000, lastMaintenance: '2023-11-20', nextMaintenance: '2024-02-28' },
  { id: 'WT-LS', name: 'Wasserturm LS', type: 'watertower', coordinates: { x: 52, y: 62 }, status: 'good', capacity: 20000, currentLoad: 16500, lastMaintenance: '2024-01-25', nextMaintenance: '2024-07-25' },
  { id: 'WT-VW', name: 'Wasserturm Vinewood', type: 'watertower', coordinates: { x: 42, y: 55 }, status: 'warning', capacity: 15000, currentLoad: 8000, lastMaintenance: '2023-12-10', nextMaintenance: '2024-03-10' },
  { id: 'HY-01', name: 'Hydrant Downtown', type: 'hydrant', coordinates: { x: 50, y: 65 }, status: 'warning', lastMaintenance: '2023-10-01', nextMaintenance: '2024-02-01' },
  { id: 'HY-02', name: 'Hydrant Vinewood', type: 'hydrant', coordinates: { x: 45, y: 58 }, status: 'good', lastMaintenance: '2024-01-15', nextMaintenance: '2024-07-15' },
  { id: 'HY-03', name: 'Hydrant South', type: 'hydrant', coordinates: { x: 48, y: 72 }, status: 'good', lastMaintenance: '2024-01-20', nextMaintenance: '2024-07-20' },
];

export const mapMarkers: MapMarker[] = [
  // Techniker
  { id: '1', x: 52, y: 22, type: 'technician', label: 'T-142' },
  { id: '2', x: 48, y: 18, type: 'engineer', label: 'E-089' },
  { id: '3', x: 50, y: 65, type: 'technician', label: 'T-056' },
  { id: '4', x: 58, y: 42, type: 'supervisor', label: 'S-023' },
  { id: '5', x: 68, y: 45, type: 'engineer', label: 'E-078' },
  { id: '6', x: 62, y: 38, type: 'technician', label: 'T-015' },
  { id: '7', x: 35, y: 68, type: 'emergency', label: 'EM-167' },
  { id: '8', x: 42, y: 55, type: 'technician', label: 'T-031' },
  { id: '9', x: 48, y: 72, type: 'technician', label: 'T-098' },
  { id: '10', x: 35, y: 68, type: 'emergency', label: 'EM-008' },
  
  // Einsätze
  { id: '11', x: 48, y: 18, type: 'call', label: 'PWR-4521', priority: 'medium' },
  { id: '12', x: 35, y: 68, type: 'call', label: 'PWR-4522', priority: 'high' },
  { id: '13', x: 58, y: 42, type: 'call', label: 'PWR-4523', priority: 'high' },
  { id: '14', x: 48, y: 72, type: 'call', label: 'PWR-4524', priority: 'high' },
  { id: '15', x: 42, y: 55, type: 'call', label: 'PWR-4525', priority: 'medium' },
  
  // Infrastruktur
  { id: '16', x: 45, y: 15, type: 'windturbine', label: 'WT-01', status: 'good' },
  { id: '17', x: 48, y: 16, type: 'windturbine', label: 'WT-02', status: 'good' },
  { id: '18', x: 46, y: 18, type: 'windturbine', label: 'WT-03', status: 'warning' },
  { id: '19', x: 48, y: 18, type: 'windturbine', label: 'WT-04', status: 'warning' },
  { id: '20', x: 52, y: 22, type: 'substation', label: 'UW-N', status: 'good' },
  { id: '21', x: 68, y: 45, type: 'substation', label: 'UW-O', status: 'good' },
  { id: '22', x: 48, y: 78, type: 'substation', label: 'UW-S', status: 'critical' },
  { id: '23', x: 32, y: 65, type: 'substation', label: 'UW-W', status: 'critical' },
  { id: '24', x: 58, y: 42, type: 'dam', label: 'DAM', status: 'good' },
  { id: '25', x: 62, y: 38, type: 'pumpstation', label: 'PS-01', status: 'good' },
  { id: '26', x: 50, y: 70, type: 'pumpstation', label: 'PS-02', status: 'warning' },
  { id: '27', x: 52, y: 62, type: 'watertower', label: 'WT-LS', status: 'good' },
  { id: '28', x: 42, y: 55, type: 'watertower', label: 'WT-VW', status: 'warning' },
];
