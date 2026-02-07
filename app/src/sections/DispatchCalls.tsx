import type { DispatchCall, Priority } from '@/types';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { MapPin, Clock, Users, AlertTriangle, Zap, Droplets, Phone, CheckCircle, Crosshair } from 'lucide-react';

interface DispatchCallsProps {
  calls: DispatchCall[];
  onSelectCall: (callId: string) => void;
  selectedCallId: string | null;
  onAcceptCall: (callId: string) => void;
}

const priorityConfig: Record<Priority, { label: string; color: string; bg: string; border: string; icon: React.ElementType }> = {
  high: { 
    label: 'Hoch', 
    color: 'text-red-400', 
    bg: 'bg-red-500/20',
    border: 'border-red-500/50',
    icon: AlertTriangle 
  },
  medium: { 
    label: 'Mittel', 
    color: 'text-amber-400', 
    bg: 'bg-amber-500/20',
    border: 'border-amber-500/50',
    icon: AlertTriangle 
  },
  low: { 
    label: 'Niedrig', 
    color: 'text-blue-400', 
    bg: 'bg-blue-500/20',
    border: 'border-blue-500/50',
    icon: Phone 
  },
};

const typeConfig = {
  power: { icon: Zap, color: 'text-amber-400', label: 'Strom', bg: 'bg-amber-500/10' },
  water: { icon: Droplets, color: 'text-blue-400', label: 'Wasser', bg: 'bg-blue-500/10' },
  emergency: { icon: AlertTriangle, color: 'text-red-400', label: 'Notfall', bg: 'bg-red-500/10' },
};

export function DispatchCalls({ calls, onSelectCall, selectedCallId, onAcceptCall }: DispatchCallsProps) {
  const pendingCount = calls.filter(c => c.status === 'pending').length;
  const activeCount = calls.filter(c => c.status === 'active').length;
  const highPriorityCount = calls.filter(c => c.priority === 'high').length;

  return (
    <div className="h-full flex flex-col overflow-hidden">
      {/* Filter/Stats Bar */}
      <div className="p-3 border-b border-border/50 flex items-center justify-between flex-shrink-0">
        <div className="flex gap-2 flex-wrap">
          <Badge variant="secondary" className="bg-emerald-500/20 text-emerald-400 text-xs gap-1">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
            {activeCount} Aktiv
          </Badge>
          {pendingCount > 0 && (
            <Badge variant="secondary" className="bg-amber-500/20 text-amber-400 text-xs gap-1">
              <span className="w-1.5 h-1.5 rounded-full bg-amber-500" />
              {pendingCount} Ausstehend
            </Badge>
          )}
          {highPriorityCount > 0 && (
            <Badge variant="secondary" className="bg-red-500/20 text-red-400 text-xs gap-1">
              <span className="w-1.5 h-1.5 rounded-full bg-red-500" />
              {highPriorityCount} Hoch
            </Badge>
          )}
        </div>
      </div>
      
      {/* Scrollable Content */}
      <div className="flex-1 overflow-y-auto custom-scrollbar min-h-0">
        <div className="p-2 space-y-2">
          {calls.map((call) => {
            const priority = priorityConfig[call.priority];
            const TypeIcon = typeConfig[call.type].icon;
            const isSelected = selectedCallId === call.id;
            const isPending = call.status === 'pending';
            const isActive = call.status === 'active';
            
            return (
              <div
                key={call.id}
                onClick={() => onSelectCall(call.id)}
                className={`p-3 rounded-lg border transition-all cursor-pointer ${
                  isSelected
                    ? 'ring-2 ring-primary ring-offset-2 ring-offset-card'
                    : ''
                } ${
                  isPending 
                    ? 'bg-amber-500/10 border-amber-500/30 hover:bg-amber-500/20' 
                    : isActive
                    ? 'bg-emerald-500/5 border-emerald-500/30 hover:bg-emerald-500/10'
                    : call.priority === 'high'
                    ? 'bg-red-500/5 border-red-500/30 hover:bg-red-500/10'
                    : 'bg-card/50 border-border/50 hover:bg-card'
                }`}
              >
                {/* Header */}
                <div className="flex items-start justify-between gap-2 mb-2">
                  <div className="flex items-center gap-1.5">
                    <span className="text-[10px] font-mono text-muted-foreground bg-secondary px-1 rounded">
                      {call.id}
                    </span>
                    <Badge 
                      variant="secondary" 
                      className={`text-[10px] ${priority.color} ${priority.bg} border-0 py-0 h-5`}
                    >
                      {priority.label}
                    </Badge>
                  </div>
                  <div className="flex items-center gap-1">
                    {isSelected && (
                      <Crosshair className="w-4 h-4 text-primary animate-pulse" />
                    )}
                    <TypeIcon className={`w-4 h-4 ${typeConfig[call.type].color}`} />
                  </div>
                </div>
                
                {/* Title */}
                <div className="mb-2">
                  <div className="flex items-center gap-1.5 mb-1">
                    <span className="text-[10px] font-mono text-primary bg-primary/10 px-1 rounded">{call.code}</span>
                    <span className="font-medium text-white text-sm">{call.title}</span>
                  </div>
                  <p className="text-xs text-muted-foreground line-clamp-2">
                    {call.description}
                  </p>
                </div>
                
                {/* Location & Time */}
                <div className="flex items-center gap-3 text-[11px] text-muted-foreground mb-2">
                  <span className="flex items-center gap-1">
                    <MapPin className="w-3 h-3" />
                    {call.location}
                  </span>
                  <span className="flex items-center gap-1">
                    <Clock className="w-3 h-3" />
                    {call.timestamp}
                  </span>
                </div>
                
                {/* Assigned Units */}
                {call.assignedUnits.length > 0 && (
                  <div className="flex items-center gap-1.5 pt-2 border-t border-border/30 mb-2">
                    <Users className="w-3 h-3 text-muted-foreground" />
                    <div className="flex gap-1 flex-wrap">
                      {call.assignedUnits.map((unit) => (
                        <span 
                          key={unit} 
                          className="text-[10px] bg-primary/20 text-primary px-1.5 py-0.5 rounded"
                        >
                          {unit}
                        </span>
                      ))}
                    </div>
                  </div>
                )}
                
                {/* Action Buttons */}
                <div className="flex items-center gap-2 pt-2">
                  {isPending && (
                    <Button
                      size="sm"
                      onClick={(e) => {
                        e.stopPropagation();
                        onAcceptCall(call.id);
                      }}
                      className="h-7 px-3 text-xs bg-emerald-500/20 text-emerald-400 hover:bg-emerald-500/30 border border-emerald-500/50"
                    >
                      <CheckCircle className="w-3.5 h-3.5 mr-1" />
                      Annehmen
                    </Button>
                  )}
                  
                  {isActive && (
                    <Badge variant="secondary" className="bg-emerald-500/20 text-emerald-400 text-xs gap-1">
                      <CheckCircle className="w-3 h-3" />
                      Angenommen
                    </Badge>
                  )}
                  
                  {/* Pending Indicator */}
                  {isPending && (
                    <div className="flex-1 flex items-center gap-2">
                      <div className="flex-1 h-1 bg-amber-500/20 rounded-full overflow-hidden">
                        <div className="h-full w-2/3 bg-amber-500 animate-pulse" />
                      </div>
                      <span className="text-[10px] text-amber-400">Wartet</span>
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
