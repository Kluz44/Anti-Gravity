import type { Employee, EmployeeStatus, UnitType, JobRole } from '@/types';
import { Wrench, HardHat, UserCog, AlertTriangle, Phone, MapPin, Zap, Droplets, Radio, Crown, GraduationCap } from 'lucide-react';
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from '@/components/ui/tooltip';

interface EmployeeListProps {
  employees: Employee[];
}

const statusConfig: Record<EmployeeStatus, { label: string; color: string; bg: string }> = {
  available: { label: 'Verfügbar', color: 'text-emerald-400', bg: 'bg-emerald-500/20' },
  busy: { label: 'Im Einsatz', color: 'text-amber-400', bg: 'bg-amber-500/20' },
  offduty: { label: 'Außer Dienst', color: 'text-slate-400', bg: 'bg-slate-500/20' },
};

const unitConfig: Record<UnitType, { icon: React.ElementType; color: string; label: string }> = {
  technician: { icon: Wrench, color: 'text-blue-400', label: 'Tech' },
  engineer: { icon: HardHat, color: 'text-amber-400', label: 'Eng' },
  supervisor: { icon: UserCog, color: 'text-purple-400', label: 'Sup' },
  emergency: { icon: AlertTriangle, color: 'text-red-400', label: 'Notf' },
};

// Job icons with tooltips
const jobIcons: Record<JobRole, { icon: React.ElementType; label: string; color: string; bg: string }> = {
  'Elektriker': { icon: Zap, label: 'Elektriker', color: 'text-amber-400', bg: 'bg-amber-500/20' },
  'Gas und Wasser Techniker': { icon: Droplets, label: 'Gas & Wasser Techniker', color: 'text-blue-400', bg: 'bg-blue-500/20' },
  'Dispatcher': { icon: Radio, label: 'Dispatcher', color: 'text-cyan-400', bg: 'bg-cyan-500/20' },
  'Manager': { icon: Crown, label: 'Manager', color: 'text-purple-400', bg: 'bg-purple-500/20' },
  'Praktikant': { icon: GraduationCap, label: 'Praktikant', color: 'text-emerald-400', bg: 'bg-emerald-500/20' },
};

export function EmployeeList({ employees }: EmployeeListProps) {
  const availableCount = employees.filter(e => e.status === 'available').length;
  const busyCount = employees.filter(e => e.status === 'busy').length;

  return (
    <TooltipProvider delayDuration={100}>
      <div className="h-full flex flex-col overflow-hidden">
        {/* Header */}
        <div className="p-3 border-b border-border/50 flex-shrink-0">
          <div className="flex items-center justify-between mb-2">
            <h2 className="text-sm font-semibold text-white flex items-center gap-1.5">
              <div className="flex items-center">
                <Zap className="w-3.5 h-3.5 text-amber-400" />
                <Droplets className="w-3.5 h-3.5 text-blue-400 -ml-1" />
              </div>
              Team
            </h2>
            <span className="text-[10px] bg-primary/20 text-primary px-1.5 py-0.5 rounded">
              {employees.length}
            </span>
          </div>
          <div className="flex gap-2 text-[10px]">
            <div className="flex items-center gap-1">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
              <span className="text-emerald-400">{availableCount}</span>
            </div>
            <div className="flex items-center gap-1">
              <span className="w-1.5 h-1.5 rounded-full bg-amber-500" />
              <span className="text-amber-400">{busyCount}</span>
            </div>
          </div>
        </div>
        
        {/* Scrollable Content */}
        <div className="flex-1 overflow-y-auto custom-scrollbar min-h-0">
          <div className="p-1.5 space-y-1">
            {employees.map((employee) => {
              const UnitIcon = unitConfig[employee.unit].icon;
              const status = statusConfig[employee.status];
              const jobConfig = jobIcons[employee.jobRole];
              const JobIcon = jobConfig.icon;
              
              return (
                <div
                  key={employee.id}
                  className="group p-2 rounded-lg bg-secondary/50 hover:bg-secondary transition-colors cursor-pointer"
                >
                  <div className="flex items-start gap-2">
                    {/* Unit Type Icon */}
                    <div className={`p-1.5 rounded-md ${unitConfig[employee.unit].color} bg-card flex-shrink-0`}>
                      <UnitIcon className="w-3.5 h-3.5" />
                    </div>
                    
                    <div className="flex-1 min-w-0">
                      {/* Name and Job Icon */}
                      <div className="flex items-center gap-1.5">
                        <span className="font-medium text-white text-sm truncate">
                          {employee.name}
                        </span>
                        
                        {/* Job Icon with Tooltip */}
                        <Tooltip>
                          <TooltipTrigger asChild>
                            <div className={`w-5 h-5 rounded flex items-center justify-center cursor-help ${jobConfig.bg} hover:brightness-110 transition-all flex-shrink-0`}>
                              <JobIcon className={`w-3.5 h-3.5 ${jobConfig.color}`} />
                            </div>
                          </TooltipTrigger>
                          <TooltipContent side="top" sideOffset={5} className="text-xs font-medium">
                            {jobConfig.label}
                          </TooltipContent>
                        </Tooltip>
                        
                        <span className="text-[10px] text-muted-foreground flex-shrink-0">
                          {employee.badge}
                        </span>
                      </div>
                      
                      {/* Status */}
                      <div className="flex items-center gap-1 mt-0.5">
                        <span className={`text-[10px] px-1 py-0 rounded ${status.color} ${status.bg}`}>
                          {status.label}
                        </span>
                      </div>
                      
                      {/* Location & Call */}
                      {employee.status !== 'offduty' && (
                        <div className="flex items-center gap-2 mt-1.5 text-[10px] text-muted-foreground">
                          <span className="flex items-center gap-0.5 truncate">
                            <MapPin className="w-3 h-3 flex-shrink-0" />
                            {employee.location}
                          </span>
                          {employee.currentCall && (
                            <span className="flex items-center gap-0.5 text-amber-400 whitespace-nowrap flex-shrink-0">
                              <Phone className="w-3 h-3" />
                              {employee.currentCall}
                            </span>
                          )}
                        </div>
                      )}
                    </div>
                    
                    {/* Status Dot */}
                    <div className={`w-2 h-2 rounded-full flex-shrink-0 mt-1 ${
                      employee.status === 'available' ? 'bg-emerald-500' :
                      employee.status === 'busy' ? 'bg-amber-500' : 'bg-slate-500'
                    }`} />
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </TooltipProvider>
  );
}
