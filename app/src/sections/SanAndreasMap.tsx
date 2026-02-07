import { useState, useRef, useCallback } from 'react';
import type { MapMarker, InfrastructureType, InfrastructureStatus } from '@/types';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { ZoomIn, ZoomOut, Maximize, Navigation, Layers, Wind, Zap, Droplets, Triangle, TowerControl, Crosshair } from 'lucide-react';

interface SanAndreasMapProps {
  markers: MapMarker[];
  selectedCallId: string | null;
  isDay: boolean; // Added isDay prop
}

// GTA V Map Bounds
const MAP_WIDTH = 8500;
const MAP_HEIGHT = 12000;
const OFF_X = 4000;
const OFF_Y = 8000;

export function SanAndreasMap({ markers, selectedCallId, isDay }: SanAndreasMapProps) {
  const [scale, setScale] = useState(1);
  const [position, setPosition] = useState({ x: 0, y: 0 });
  // ... existing state ...
  const [isDragging, setIsDragging] = useState(false);
  const [dragStart, setDragStart] = useState({ x: 0, y: 0 });
  const [showGrid, setShowGrid] = useState(true);
  const [filter, setFilter] = useState<string | null>(null);
  const mapRef = useRef<HTMLDivElement>(null);

  // ... (Zoom/Pan Handlers are fine) ...
  const handleZoomIn = () => setScale(prev => Math.min(prev * 1.2, 4));
  const handleZoomOut = () => setScale(prev => Math.max(prev / 1.2, 0.5));
  const handleReset = () => {
    setScale(1);
    setPosition({ x: 0, y: 0 });
  };

  const handleMouseDown = useCallback((e: React.MouseEvent) => {
    setIsDragging(true);
    setDragStart({ x: e.clientX - position.x, y: e.clientY - position.y });
  }, [position]);

  const handleMouseMove = useCallback((e: React.MouseEvent) => {
    if (!isDragging) return;
    setPosition({
      x: e.clientX - dragStart.x,
      y: e.clientY - dragStart.y,
    });
  }, [isDragging, dragStart]);

  const handleMouseUp = useCallback(() => {
    setIsDragging(false);
  }, []);

  const handleWheel = useCallback((e: React.WheelEvent) => {
    e.preventDefault();
    const delta = e.deltaY > 0 ? 0.9 : 1.1;
    setScale(prev => Math.max(0.5, Math.min(4, prev * delta)));
  }, []);

  const filteredMarkers = filter
    ? markers.filter(m => m.type === filter || (filter === 'infrastructure' &&
      ['windturbine', 'transformer', 'substation', 'dam', 'hydrant', 'watertower', 'pumpstation'].includes(m.type)))
    : markers;

  // Convert Coords Helper
  const getMarkerPos = (m: any) => {
    if (m.rawCoords) {
      // Calculate from GTA Coords
      const left = ((m.rawCoords.x + OFF_X) / MAP_WIDTH) * 100;
      const top = ((OFF_Y - m.rawCoords.y) / MAP_HEIGHT) * 100; // Inverted Y in CSS usually top-down
      return { left: `${left}%`, top: `${top}%` };
    }
    return { left: `${m.x}%`, top: `${m.y}%` }; // Fallback
  };

  const isSelectedCall = (marker: MapMarker) => {
    return selectedCallId && (marker.id === selectedCallId || marker.label === selectedCallId);
  };

  // Use Props for Image
  const mapImage = isDay ? 'ag_map_day.jpg' : 'ag_map_night.jpg';

  return (
    <div className="h-full flex flex-col">
      {/* ... Toolbar ... */}
      <div className="p-2 border-b border-border/50 flex items-center justify-between bg-card/50">
        <div className="flex items-center gap-2">
          <h2 className="text-sm font-semibold text-white flex items-center gap-1.5">
            <Navigation className="w-4 h-4 text-primary" />
            Karte
          </h2>
          {/* ... */}
        </div>
        <div className="flex items-center gap-1">
          {/* ... Buttons ... */}
          <Button variant="ghost" size="icon" onClick={() => setShowGrid(!showGrid)} className={`h-7 w-7 ${showGrid ? 'bg-primary/20 text-primary' : ''}`}>
            <Layers className="w-3.5 h-3.5" />
          </Button>
          <Button variant="ghost" size="icon" onClick={handleReset} className="h-7 w-7"><Maximize className="w-3.5 h-3.5" /></Button>
          <Button variant="ghost" size="icon" onClick={handleZoomOut} className="h-7 w-7"><ZoomOut className="w-3.5 h-3.5" /></Button>
          <Button variant="ghost" size="icon" onClick={handleZoomIn} className="h-7 w-7"><ZoomIn className="w-3.5 h-3.5" /></Button>
        </div>
      </div>

      <div
        ref={mapRef}
        className="flex-1 relative overflow-hidden bg-[#0a1628] cursor-grab active:cursor-grabbing"
        onMouseDown={handleMouseDown}
        onMouseMove={handleMouseMove}
        onMouseUp={handleMouseUp}
        onMouseLeave={handleMouseUp}
        onWheel={handleWheel}
      >
        {showGrid && <div className="absolute inset-0 map-grid opacity-20" />}

        <div
          className="absolute inset-0 flex items-center justify-center transform-gpu"
          style={{
            transform: `translate(${position.x}px, ${position.y}px) scale(${scale})`,
            transition: isDragging ? 'none' : 'transform 0.1s ease-out',
          }}
        >
          {/* Karte */}
          <div
            className="relative"
            style={{
              width: '100%',
              height: '100%',
              aspectRatio: '1 / 1', // Force Square
              maxWidth: '80vh',
              maxHeight: '100%'
            }}
          >
            <img
              src={mapImage}
              alt="San Andreas Map"
              className="w-full h-full object-contain"
              style={{
                filter: 'brightness(0.9) contrast(1.1)',
                boxShadow: '0 0 50px rgba(0,0,0,0.5)'
              }}
              draggable={false}
              onError={(e) => {
                (e.target as HTMLImageElement).src = '/map.jpg';
              }}
            />

            {/* Marker Overlay */}
            <div className="absolute inset-0">
              {filteredMarkers.map((marker) => {
                const color = marker.status ? statusColors[marker.status] : typeColors[marker.type] || '#64748b';
                const isInfrastructure = ['windturbine', 'transformer', 'substation', 'dam', 'hydrant', 'watertower', 'pumpstation'].includes(marker.type);
                const Icon = isInfrastructure ? infrastructureIcons[marker.type as InfrastructureType] : null;
                const isSelected = isSelectedCall(marker);

                const pos = getMarkerPos(marker);

                return (
                  <div
                    key={marker.id}
                    className="absolute transform -translate-x-1/2 -translate-y-1/2"
                    style={{
                      left: pos.left,
                      top: pos.top,
                    }}
                  >
                    {/* Selected Call Highlight Ring */}
                    {isSelected && (
                      <div
                        className="absolute inset-0 rounded-full animate-ping"
                        style={{
                          backgroundColor: '#f59e0b',
                          opacity: 0.5,
                          width: '40px',
                          height: '40px',
                          margin: '-11px',
                        }}
                      />
                    )}

                    {/* Selected Call Outer Ring */}
                    {isSelected && (
                      <div
                        className="absolute inset-0 rounded-full border-4 border-primary"
                        style={{
                          width: '32px',
                          height: '32px',
                          margin: '-7px',
                          boxShadow: '0 0 20px #f59e0b, 0 0 40px #f59e0b',
                        }}
                      />
                    )}

                    {/* Pulsierender Ring für kritische Infrastruktur */}
                    {marker.status === 'critical' && !isSelected && (
                      <div
                        className="absolute inset-0 rounded-full animate-ping"
                        style={{
                          backgroundColor: color,
                          opacity: 0.3,
                          width: '24px',
                          height: '24px',
                          margin: '-4px',
                        }}
                      />
                    )}

                    {/* Pulsierender Ring für Calls */}
                    {marker.type === 'call' && !isSelected && (
                      <div
                        className="absolute inset-0 rounded-full"
                        style={{
                          border: `2px solid ${color}`,
                          width: '28px',
                          height: '28px',
                          margin: '-6px',
                          animation: 'pulse 2s infinite'
                        }}
                      />
                    )}

                    {/* Marker */}
                    <div
                      className={`relative flex items-center justify-center rounded-full border-2 shadow-lg transition-all ${isSelected ? 'border-white scale-125' : 'border-white'
                        }`}
                      style={{
                        backgroundColor: isSelected ? '#f59e0b' : color,
                        width: isInfrastructure ? '18px' : '14px',
                        height: isInfrastructure ? '18px' : '14px',
                        boxShadow: isSelected ? '0 0 15px #f59e0b' : undefined,
                      }}
                    >
                      {Icon && <Icon className="w-3 h-3 text-white" />}
                    </div>

                    {/* Label */}
                    <div
                      className="absolute top-full left-1/2 transform -translate-x-1/2 mt-1 whitespace-nowrap"
                      style={{
                        textShadow: '0 1px 3px rgba(0,0,0,0.9), 0 0 10px rgba(0,0,0,0.8)',
                      }}
                    >
                      <span className={`text-[10px] font-bold ${isSelected ? 'text-primary' : 'text-white'}`}>
                        {marker.label}
                      </span>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>

        {/* Legende */}
        <div className="absolute bottom-3 left-3 glass-panel rounded-lg p-2">
          <div className="text-[10px] font-medium text-white mb-1.5">Legende</div>
          <div className="space-y-1 text-[10px]">
            <div className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-cyan-500 flex items-center justify-center">
                <Wind className="w-1.5 h-1.5 text-white" />
              </span>
              <span className="text-muted-foreground">Wind</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-violet-500 flex items-center justify-center">
                <TowerControl className="w-1.5 h-1.5 text-white" />
              </span>
              <span className="text-muted-foreground">UW</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-amber-500 flex items-center justify-center">
                <Zap className="w-1.5 h-1.5 text-white" />
              </span>
              <span className="text-muted-foreground">Trafo</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-blue-500 flex items-center justify-center">
                <Triangle className="w-1.5 h-1.5 text-white" />
              </span>
              <span className="text-muted-foreground">Wasser</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-primary border-2 border-white shadow-lg" />
              <span className="text-muted-foreground">Ausgewählt</span>
            </div>
          </div>
        </div>

        {/* Zoom Level */}
        <div className="absolute bottom-3 right-3 glass-panel rounded-lg px-2 py-1">
          <span className="text-[10px] text-muted-foreground">
            {Math.round(scale * 100)}%
          </span>
        </div>
      </div>
    </div>
  );
}
