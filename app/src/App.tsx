import { useState, useEffect } from 'react';
import { Header } from '@/sections/Header';
import { EmployeeList } from '@/sections/EmployeeList';
import { DispatchCalls } from '@/sections/DispatchCalls';
import { SanAndreasMap } from '@/sections/SanAndreasMap';
import { InfrastructurePanel } from '@/sections/InfrastructurePanel';
import { employees as mockEmployees, dispatchCalls as mockCalls, districtStatus, mapMarkers as mockMarkers } from '@/data/mockData';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Wrench, Activity, Zap, Droplets } from 'lucide-react';
import type { DispatchCall, Employee, MapMarker } from '@/types';
import { useNuiEvent } from './hooks/useNuiEvent';
import { fetchNui } from './utils/fetchNui';

function App() {
  const [visible, setVisible] = useState(false); // Visibility State
  const [selectedCallId, setSelectedCallId] = useState<string | null>(null);
  const [calls, setCalls] = useState<DispatchCall[]>([]);
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [gridStats, setGridStats] = useState({ power: 100, water: 100 });
  const [isDay, setIsDay] = useState(true);

  // Handle NUI Events
  useNuiEvent('openDispatch', (data: any) => {
    setVisible(true);
    if (data.missions) updateMissions(data.missions);
    if (data.techs) updateEmployees(data.techs);
    if (data.stats) setGridStats(data.stats);
    if (data.isDay !== undefined) setIsDay(data.isDay);
  });

  useNuiEvent('updateMissions', (missions: any) => {
    updateMissions(missions);
  });


  useNuiEvent('close', () => {
    setVisible(false);
  });


  // Esc Key to Close
  useEffect(() => {
    const handleEsc = (e: KeyboardEvent) => {
      if (visible && e.key === 'Escape') {
        setVisible(false);
        fetchNui('close');
      }
    };
    window.addEventListener('keydown', handleEsc);
    return () => window.removeEventListener('keydown', handleEsc);
  }, [visible]);

  // Data Mapping Helpers
  const updateMissions = (luaMissions: any) => {
    const mapped: DispatchCall[] = Object.values(luaMissions).map((m: any) => ({
      id: m.id.toString(),
      code: `CODE-${m.id}`,
      title: m.label || 'Unknown Mission',
      description: `Type: ${m.subType}. Priority: ${m.priority}`,
      location: `X: ${Math.round(m.coords.x)}, Y: ${Math.round(m.coords.y)}`,
      coordinates: m.coords,
      priority: m.priority === 'emergency' ? 'high' : 'medium', // Simple mapping
      timestamp: 'Now',
      assignedUnits: m.assigned ? m.assigned.map(String) : [],
      status: m.assigned && m.assigned.length > 0 ? 'active' : 'pending',
      type: m.subType === 'pipe_burst' || m.subType === 'hydrant' ? 'water' : 'power'
    }));
    setCalls(mapped);
  };

  const updateEmployees = (luaTechs: any[]) => {
    const mapped: Employee[] = luaTechs.map((t: any) => ({
      id: t.source ? t.source.toString() : '0',
      name: t.name,
      badge: '00' + t.source,
      unit: 'technician',
      status: t.job === 'unemployed' ? 'offduty' : 'available', // Simple logic
      location: 'Roaming',
      jobRole: 'Elektriker' // Default
    }));
    setEmployees(mapped);
  };

  const handleAcceptCall = (callId: string) => {
    const call = calls.find(c => c.id === callId);
    if (call) {
      fetchNui('claimMission', { id: parseInt(call.id), x: call.coordinates.x, y: call.coordinates.y });
      // Optimistic Update
      setCalls(prev => prev.map(c =>
        c.id === callId
          ? { ...c, status: 'active', assignedUnits: [...c.assignedUnits, 'Me'] }
          : c
      ));
    }
  };

  // Markers for Map
  const mapMarkers: MapMarker[] = calls.map(c => ({
    id: c.id,
    x: 0, // Calculated in Map Component or here? Let's pass raw coords
    y: 0,
    rawCoords: c.coordinates, // Add raw coords to type if needed
    type: c.type === 'water' ? 'hydrant' : 'transformer', // Simplified mapping for icons
    label: c.title,
    priority: c.priority,
    status: 'warning'
  } as any)); // Type assertion until we fix types

  const activeCalls = calls.filter(c => c.status === 'active').length;
  const criticalCount = calls.filter(c => c.priority === 'high').length;

  if (!visible) return null; // Hidden when not open

  return (
    <div className="h-screen flex flex-col bg-background overflow-hidden select-none">
      <Header />

      <main className="flex-1 overflow-hidden">
        <div className="h-full flex">
          {/* Left Sidebar - Employees */}
          <div className="w-72 flex-shrink-0 border-r border-border/50">
            <EmployeeList employees={employees.length > 0 ? employees : mockEmployees} />
          </div>

          {/* Center - Map */}
          <div className="flex-1 min-w-0 flex flex-col">
            <SanAndreasMap
              markers={mapMarkers}
              selectedCallId={selectedCallId}
              isDay={isDay}
            />

            {/* Bottom Panel - Quick Stats */}
            <div className="h-14 bg-card border-t border-border/50 flex items-center px-4 gap-6">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-lg bg-emerald-500/20 flex items-center justify-center">
                  <Zap className="w-4 h-4 text-emerald-400" />
                </div>
                <div>
                  <div className="text-xs text-muted-foreground">Strom Ø</div>
                  <div className="text-sm font-bold text-emerald-400">{gridStats.power}%</div>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-lg bg-blue-500/20 flex items-center justify-center">
                  <Droplets className="w-4 h-4 text-blue-400" />
                </div>
                <div>
                  <div className="text-xs text-muted-foreground">Wasser Ø</div>
                  <div className="text-sm font-bold text-blue-400">{gridStats.water}%</div>
                </div>
              </div>
              <div className="h-8 w-px bg-border/50 mx-2" />
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-lg bg-red-500/20 flex items-center justify-center">
                  <Activity className="w-4 h-4 text-red-400" />
                </div>
                <div>
                  <div className="text-xs text-muted-foreground">Kritisch</div>
                  <div className="text-sm font-bold text-red-400">{criticalCount} Aufträge</div>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-lg bg-amber-500/20 flex items-center justify-center">
                  <Wrench className="w-4 h-4 text-amber-400" />
                </div>
                <div>
                  <div className="text-xs text-muted-foreground">Aktive Aufträge</div>
                  <div className="text-sm font-bold text-amber-400">{activeCalls}</div>
                </div>
              </div>
            </div>
          </div>

          {/* Right Sidebar - Tabs for Calls & Infrastructure */}
          <div className="w-80 flex-shrink-0 border-l border-border/50 bg-card">
            <Tabs defaultValue="calls" className="h-full flex flex-col">
              <TabsList className="w-full rounded-none border-b border-border/50 bg-secondary/50 p-0 h-12">
                <TabsTrigger
                  value="calls"
                  className="flex-1 rounded-none data-[state=active]:bg-card data-[state=active]:border-b-2 data-[state=active]:border-primary gap-2"
                >
                  <Wrench className="w-4 h-4" />
                  Aufträge
                  <span className="ml-1 px-1.5 py-0.5 text-xs bg-primary/20 text-primary rounded">{calls.length}</span>
                </TabsTrigger>
                <TabsTrigger
                  value="infrastructure"
                  className="flex-1 rounded-none data-[state=active]:bg-card data-[state=active]:border-b-2 data-[state=active]:border-primary gap-2"
                >
                  <Activity className="w-4 h-4" />
                  Status
                  <span className="ml-1 px-1.5 py-0.5 text-xs bg-red-500/20 text-red-400 rounded">2</span>
                </TabsTrigger>
              </TabsList>

              <TabsContent value="calls" className="flex-1 m-0 p-0 overflow-hidden">
                <DispatchCalls
                  calls={calls.length > 0 ? calls : mockCalls}
                  onSelectCall={setSelectedCallId}
                  selectedCallId={selectedCallId}
                  onAcceptCall={handleAcceptCall}
                />
              </TabsContent>

              <TabsContent value="infrastructure" className="flex-1 m-0 p-0 overflow-hidden">
                <InfrastructurePanel districts={districtStatus} />
              </TabsContent>
            </Tabs>
          </div>
        </div>
      </main>
    </div>
  );
}

export default App;
