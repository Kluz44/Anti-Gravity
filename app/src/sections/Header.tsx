import { useState, useEffect } from 'react';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { 
  Droplets,
  Clock, 
  Radio, 
  Bell, 
  LogOut,
  Wind,
  CheckCircle,
  Briefcase,
  Coffee,
  Moon
} from 'lucide-react';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';

type OperatorStatus = 'available' | 'busy' | 'break' | 'offduty';

const statusConfig: Record<OperatorStatus, { label: string; color: string; bg: string; icon: React.ElementType }> = {
  available: { 
    label: 'Verfügbar', 
    color: 'text-emerald-400', 
    bg: 'bg-emerald-500/20',
    icon: CheckCircle 
  },
  busy: { 
    label: 'Im Einsatz', 
    color: 'text-amber-400', 
    bg: 'bg-amber-500/20',
    icon: Briefcase 
  },
  break: { 
    label: 'In Pause', 
    color: 'text-blue-400', 
    bg: 'bg-blue-500/20',
    icon: Coffee 
  },
  offduty: { 
    label: 'Außer Dienst', 
    color: 'text-slate-400', 
    bg: 'bg-slate-500/20',
    icon: Moon 
  },
};

export function Header() {
  const [currentTime, setCurrentTime] = useState(new Date());
  const [notifications, setNotifications] = useState(5);
  const [operatorStatus, setOperatorStatus] = useState<OperatorStatus>('available');

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date());
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const formatTime = (date: Date) => {
    return date.toLocaleTimeString('de-DE', { 
      hour: '2-digit', 
      minute: '2-digit',
      second: '2-digit'
    });
  };

  const formatDate = (date: Date) => {
    return date.toLocaleDateString('de-DE', { 
      day: '2-digit', 
      month: '2-digit', 
      year: 'numeric' 
    });
  };

  const currentStatus = statusConfig[operatorStatus];

  return (
    <header className="h-16 bg-card border-b border-border/50 flex items-center justify-between px-4">
      {/* Logo & Title */}
      <div className="flex items-center gap-3">
        <div className="w-10 h-10 rounded-lg overflow-hidden bg-card border border-border/50">
          <img 
            src="/logo.png" 
            alt="Power & Water Department" 
            className="w-full h-full object-contain"
          />
        </div>
        <div>
          <h1 className="text-lg font-bold text-white">POWER & WATER</h1>
          <p className="text-xs text-muted-foreground">Department of Infrastructure</p>
        </div>
      </div>

      {/* Center - Status */}
      <div className="flex items-center gap-4">
        <Badge variant="secondary" className="bg-emerald-500/20 text-emerald-400 gap-1.5">
          <Radio className="w-3 h-3 animate-pulse" />
          Grid Online
        </Badge>
        <Badge variant="secondary" className="bg-blue-500/20 text-blue-400 gap-1.5">
          <Droplets className="w-3 h-3" />
          Water OK
        </Badge>
        <Badge variant="secondary" className="bg-amber-500/20 text-amber-400 gap-1.5">
          <Wind className="w-3 h-3" />
          Wind 85%
        </Badge>
      </div>

      {/* Right Side */}
      <div className="flex items-center gap-4">
        {/* Clock */}
        <div className="flex items-center gap-2 text-muted-foreground">
          <Clock className="w-4 h-4" />
          <div className="text-right">
            <div className="text-sm font-medium text-white">{formatTime(currentTime)}</div>
            <div className="text-xs">{formatDate(currentTime)}</div>
          </div>
        </div>

        {/* Notifications */}
        <Button 
          variant="ghost" 
          size="icon" 
          className="relative"
          onClick={() => setNotifications(0)}
        >
          <Bell className="w-5 h-5" />
          {notifications > 0 && (
            <span className="absolute -top-1 -right-1 w-5 h-5 bg-red-500 rounded-full text-xs flex items-center justify-center text-white font-medium">
              {notifications}
            </span>
          )}
        </Button>

        {/* User Menu */}
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" className="gap-2">
              <div className={`w-2.5 h-2.5 rounded-full ${currentStatus.bg.replace('/20', '')}`} />
              <span className="hidden sm:inline">Operator-01</span>
              <span className={`text-xs ${currentStatus.color}`}>({currentStatus.label})</span>
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-56">
            {/* Status Section */}
            <div className="px-3 py-2 text-xs font-medium text-muted-foreground">
              Status ändern
            </div>
            
            {(Object.keys(statusConfig) as OperatorStatus[]).map((status) => {
              const config = statusConfig[status];
              const Icon = config.icon;
              const isActive = operatorStatus === status;
              
              return (
                <DropdownMenuItem 
                  key={status}
                  onClick={() => setOperatorStatus(status)}
                  className={`cursor-pointer ${isActive ? 'bg-secondary' : ''}`}
                >
                  <div className={`w-6 h-6 rounded-md ${config.bg} flex items-center justify-center mr-2`}>
                    <Icon className={`w-3.5 h-3.5 ${config.color}`} />
                  </div>
                  <span className={isActive ? 'font-medium' : ''}>{config.label}</span>
                  {isActive && (
                    <CheckCircle className="w-4 h-4 text-emerald-400 ml-auto" />
                  )}
                </DropdownMenuItem>
              );
            })}
            
            <DropdownMenuSeparator />
            
            {/* Logout */}
            <DropdownMenuItem className="text-red-400 cursor-pointer">
              <div className="w-6 h-6 rounded-md bg-red-500/20 flex items-center justify-center mr-2">
                <LogOut className="w-3.5 h-3.5 text-red-400" />
              </div>
              Abmelden
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </header>
  );
}
