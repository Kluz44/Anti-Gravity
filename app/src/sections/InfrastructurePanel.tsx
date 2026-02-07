import type { DistrictStatus, InfrastructureStatus } from '@/types';
import { Zap, Droplets, AlertTriangle, Activity, TrendingUp } from 'lucide-react';
import { infrastructureAssets } from '@/data/mockData';

interface InfrastructurePanelProps {
  districts: DistrictStatus[];
}

const statusConfig: Record<InfrastructureStatus, { label: string; color: string }> = {
  good: { 
    label: 'OK', 
    color: 'text-emerald-400', 
  },
  warning: { 
    label: 'WARN', 
    color: 'text-amber-400', 
  },
  critical: { 
    label: 'KRIT', 
    color: 'text-red-400', 
  },
};

export function InfrastructurePanel({ districts }: InfrastructurePanelProps) {
  const criticalAssets = infrastructureAssets.filter(a => a.status === 'critical');
  const warningAssets = infrastructureAssets.filter(a => a.status === 'warning');

  const avgPower = Math.round(districts.reduce((sum, d) => sum + d.powerValue, 0) / districts.length);
  const avgWater = Math.round(districts.reduce((sum, d) => sum + d.waterValue, 0) / districts.length);

  return (
    <div className="h-full flex flex-col overflow-hidden">
      {/* Quick Stats */}
      <div className="p-3 border-b border-border/50 grid grid-cols-2 gap-2 flex-shrink-0">
        <div className="p-2 rounded-lg bg-amber-500/10 border border-amber-500/30">
          <div className="flex items-center gap-1.5 mb-1">
            <Zap className="w-3 h-3 text-amber-400" />
            <span className="text-[10px] text-muted-foreground">Strom Ø</span>
          </div>
          <div className={`text-xl font-bold ${avgPower >= 80 ? 'text-emerald-400' : avgPower >= 60 ? 'text-amber-400' : 'text-red-400'}`}>
            {avgPower}%
          </div>
        </div>
        <div className="p-2 rounded-lg bg-blue-500/10 border border-blue-500/30">
          <div className="flex items-center gap-1.5 mb-1">
            <Droplets className="w-3 h-3 text-blue-400" />
            <span className="text-[10px] text-muted-foreground">Wasser Ø</span>
          </div>
          <div className={`text-xl font-bold ${avgWater >= 80 ? 'text-blue-400' : avgWater >= 60 ? 'text-amber-400' : 'text-red-400'}`}>
            {avgWater}%
          </div>
        </div>
      </div>
      
      {/* Scrollable Content */}
      <div className="flex-1 overflow-y-auto custom-scrollbar min-h-0">
        <div className="p-2 space-y-2">
          {/* Kritische Assets */}
          {criticalAssets.length > 0 && (
            <div className="space-y-1.5">
              <div className="flex items-center gap-1.5 text-red-400 font-medium text-xs px-1">
                <Activity className="w-3.5 h-3.5" />
                <span>Kritisch ({criticalAssets.length})</span>
              </div>
              {criticalAssets.map((asset) => (
                <div
                  key={asset.id}
                  className="p-2.5 rounded-lg bg-red-500/10 border border-red-500/40"
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <span className="w-2 h-2 rounded-full bg-red-500 animate-pulse" />
                      <span className="text-sm text-white font-medium">{asset.name}</span>
                    </div>
                    <span className="text-[10px] bg-red-500/30 text-red-300 px-1.5 py-0.5 rounded">KRIT</span>
                  </div>
                </div>
              ))}
            </div>
          )}
          
          {/* Warnung Assets */}
          {warningAssets.length > 0 && (
            <div className="space-y-1.5">
              <div className="flex items-center gap-1.5 text-amber-400 font-medium text-xs px-1">
                <AlertTriangle className="w-3.5 h-3.5" />
                <span>Warnungen ({warningAssets.length})</span>
              </div>
              {warningAssets.map((asset) => (
                <div
                  key={asset.id}
                  className="p-2.5 rounded-lg bg-amber-500/10 border border-amber-500/40"
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <span className="w-2 h-2 rounded-full bg-amber-500" />
                      <span className="text-sm text-white font-medium">{asset.name}</span>
                    </div>
                    <span className="text-[10px] bg-amber-500/30 text-amber-300 px-1.5 py-0.5 rounded">WARN</span>
                  </div>
                </div>
              ))}
            </div>
          )}
          
          {/* Stadtteile */}
          <div className="space-y-1.5">
            <div className="flex items-center gap-1.5 text-muted-foreground font-medium text-xs px-1">
              <TrendingUp className="w-3.5 h-3.5" />
              <span>Stadtteile</span>
            </div>
            
            {districts.map((district) => {
              const powerStatus = statusConfig[district.power];
              const waterStatus = statusConfig[district.water];
              
              return (
                <div
                  key={district.id}
                  className={`p-2.5 rounded-lg border ${
                    district.power === 'critical' || district.water === 'critical'
                      ? 'bg-red-500/5 border-red-500/30'
                      : district.power === 'warning' || district.water === 'warning'
                      ? 'bg-amber-500/5 border-amber-500/30'
                      : 'bg-card/50 border-border/50'
                  }`}
                >
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-sm text-white font-medium truncate pr-2">{district.name}</span>
                    {district.outages > 0 && (
                      <span className="text-[10px] bg-red-500/20 text-red-400 px-1.5 py-0.5 rounded whitespace-nowrap">
                        {district.outages} Ausfälle
                      </span>
                    )}
                  </div>
                  
                  <div className="grid grid-cols-2 gap-2">
                    {/* Strom */}
                    <div className="space-y-1">
                      <div className="flex items-center justify-between">
                        <Zap className="w-3 h-3 text-amber-400" />
                        <span className={`text-[10px] font-bold ${powerStatus.color}`}>
                          {district.powerValue}%
                        </span>
                      </div>
                      <div className="h-1.5 bg-secondary rounded-full overflow-hidden">
                        <div 
                          className={`h-full rounded-full ${
                            district.powerValue >= 80 ? 'bg-emerald-500' :
                            district.powerValue >= 60 ? 'bg-amber-500' : 'bg-red-500'
                          }`}
                          style={{ width: `${district.powerValue}%` }}
                        />
                      </div>
                    </div>
                    
                    {/* Wasser */}
                    <div className="space-y-1">
                      <div className="flex items-center justify-between">
                        <Droplets className="w-3 h-3 text-blue-400" />
                        <span className={`text-[10px] font-bold ${waterStatus.color}`}>
                          {district.waterValue}%
                        </span>
                      </div>
                      <div className="h-1.5 bg-secondary rounded-full overflow-hidden">
                        <div 
                          className={`h-full rounded-full ${
                            district.waterValue >= 80 ? 'bg-blue-500' :
                            district.waterValue >= 60 ? 'bg-amber-500' : 'bg-red-500'
                          }`}
                          style={{ width: `${district.waterValue}%` }}
                        />
                      </div>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}
