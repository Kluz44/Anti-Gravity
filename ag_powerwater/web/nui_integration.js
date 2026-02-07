// ===== FiveM NUI Integration for AG PowerWater =====
console.log('[AG-PowerWater] NUI Integration loaded');

// ===== Global State =====
let isNuiVisible = false;
let myServerId = null;

// Static Infrastructure Markers (Empty as per user request)
const staticMapMarkers = [];

window.mapMarkers = [...staticMapMarkers];
window.activeFilter = null;
window.grid = null; // Store full grid data

const zoneLabels = {
    'LS_Downtown': 'Downtown LS',
    'LS_Vinewood': 'Vinewood & Hills',
    'LS_SouthCentral': 'South Central',
    'LS_WestSide': 'Rockford & Richman',
    'LS_Vespucci': 'Vespucci & Del Perro',
    'LS_Industrial': 'East LS Industrial',
    'LS_Airport': 'LS International Airport',
    'SandyShores': 'Sandy Shores & Grand Senora',
    'PaletoBay': 'Paleto Bay Area',
    'CountrySide': 'Blaine County (Wilderness)'
};

// Approximate Zone Polygons (0-100% coordinates)
// Origin Top-Left (0,0)
const zonePolygons = {
    'LS_Downtown': { x: 46, y: 62, w: 8, h: 8 },
    'LS_Vinewood': { x: 40, y: 50, w: 20, h: 12 },
    'LS_SouthCentral': { x: 46, y: 72, w: 12, h: 10 },
    'LS_WestSide': { x: 32, y: 62, w: 14, h: 10 },
    'LS_Vespucci': { x: 25, y: 74, w: 14, h: 10 }, // Extended for Little Seoul coverage
    'LS_Industrial': { x: 50, y: 78, w: 15, h: 14 }, // Port / Industrial
    'LS_Airport': { x: 28, y: 84, w: 12, h: 12 }, // Shifted left to cover runway, away from port
    'SandyShores': { x: 48, y: 35, w: 22, h: 12 },
    'PaletoBay': { x: 42, y: 5, w: 16, h: 10 },
    'CountrySide': { x: 10, y: 15, w: 80, h: 40 }, // Generic fallback area
};

// Inject Styles for Map Overlay
const overlayStyle = document.createElement('style');
overlayStyle.textContent = `
    .map-overlay-svg {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        z-index: 1; /* Below markers (z-index 2 usually) */
        pointer-events: none;
    }
    .zone-polygon {
        fill: rgba(255, 165, 0, 0.15);
        stroke: var(--amber);
        stroke-width: 2px;
        vector-effect: non-scaling-stroke;
        transition: all 0.2s ease;
        opacity: 0;
        filter: drop-shadow(0 0 5px var(--amber));
    }
    .zone-polygon.active {
        opacity: 1;
    }
    .map-markers {
        z-index: 2 !important; 
    }
`;
document.head.appendChild(overlayStyle);


// ===== Helper Functions =====
function GetParentResourceName() {
    const matches = window.location.pathname.match(/\/([^/]+)\/web\//);
    return matches && matches[1] ? matches[1] : 'ag_powerwater';
}

function sendNUICallback(action, data = {}) {
    fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    }).catch(err => console.error('[AG-UI] NUI Callback Error:', err));
}

// ===== NUI Message Listener =====
window.addEventListener('message', (event) => {
    const { action, data } = event.data;

    switch (action) {
        case 'openDispatch':
            showDispatchUI(data);
            break;
        case 'updateMissions':
            updateMissionsFromServer(data);
            break;
        case 'close':
            hideDispatchUI();
            break;
    }
});

// ===== Show/Hide UI =====
function showDispatchUI(data) {
    if (data.mySource) {
        myServerId = data.mySource;
    }

    // Store Grid Data
    if (data.grid) {
        window.grid = data.grid;
    }

    if (data.missions) updateMissionsFromServer(data.missions);
    if (data.techs) updateEmployeesFromServer(data.techs);
    if (data.stats) updateStatsFromServer(data.stats);
    if (data.isDay !== undefined) switchMapImage(data.isDay);

    // Initial Render of Status Panel
    renderStatusPanel();

    if (!isNuiVisible) {
        isNuiVisible = true;
        document.body.style.display = 'block';
    }
}

function hideDispatchUI() {
    isNuiVisible = false;
    document.body.style.display = 'none';
}

// ===== Data Update Functions =====
function updateMissionsFromServer(missionsData) {
    const missionsArray = Object.values(missionsData || {});

    // 1. Update List
    window.calls = missionsArray.map(m => {
        const coords = gtaCoordsToMapPercent(m.coords.x, m.coords.y);
        let subType = m.subType || 'power';
        let type = 'power';
        if (subType === 'pipe_burst' || subType === 'hydrant') type = 'water';
        else if (subType === 'emergency') type = 'emergency';

        return {
            id: m.id.toString(),
            code: `PW-${m.id}`,
            title: m.label || 'Unbekannter Auftrag',
            description: `Typ: ${subType}. Priorität: ${m.priority}`,
            location: `X: ${Math.round(m.coords.x)}, Y: ${Math.round(m.coords.y)}`,
            timestamp: 'Jetzt',
            priority: m.priority === 'emergency' ? 'high' : 'medium',
            status: (m.assigned && m.assigned.length > 0) ? 'active' : 'pending',
            type: type,
            assignedUnits: m.assigned || [],
            x: coords.x,
            y: coords.y,
            coords: m.coords
        };
    });

    // 2. Update Map Markers
    const callMarkers = window.calls.map(c => ({
        id: c.code,
        type: 'call',
        x: c.x,
        y: c.y,
        label: c.code,
        status: c.status
    }));

    window.mapMarkers = [...staticMapMarkers, ...callMarkers];

    renderCalls();
    renderMapMarkers();
}

function updateEmployeesFromServer(techsData) {
    window.employees = (techsData || []).map(t => {
        let jobRole = 'Elektriker';
        let unit = 'electrician';

        const gradeName = (t.grade_name || t.grade || '').toLowerCase();
        const job = (t.job || '').toLowerCase();

        if (gradeName.includes('elect') || gradeName.includes('techni') || job === 'power') {
            jobRole = 'Elektriker'; unit = 'electrician';
        }
        if (gradeName.includes('water') || gradeName.includes('wasser') || gradeName.includes('gas') || job === 'water') {
            jobRole = 'Gas & Wasser Techniker'; unit = 'water';
        }
        if (gradeName.includes('trainee') || gradeName.includes('azubi') || gradeName.includes('recruit') || gradeName.includes('praktikant') || job === 'unemployed') {
            jobRole = 'Auszubildender'; unit = 'trainee';
        }
        if (gradeName.includes('dispatch') || gradeName.includes('leitstelle')) {
            jobRole = 'Dispatcher'; unit = 'dispatcher';
        }
        if (gradeName.includes('boss') || gradeName.includes('manager') || gradeName.includes('chef') || gradeName.includes('leitung')) {
            jobRole = 'Manager'; unit = 'manager';
        }

        return {
            id: t.source ? t.source.toString() : '0',
            name: t.name || 'Unbekannt',
            jobRole: jobRole,
            unit: unit,
            status: t.status || 'available', // Use status from server!
            badge: `#${t.source}`,
            location: 'Im Dienst',
            currentCall: null
        };
    });

    renderEmployees();
    updateHeaderName();
}

function updateStatsFromServer(stats) {
    const powerEl = document.getElementById('avgPower');
    const waterEl = document.getElementById('avgWater');
    const statusPowerEl = document.getElementById('statusAvgPower');
    const statusWaterEl = document.getElementById('statusAvgWater');

    if (powerEl) powerEl.textContent = `${stats.power}%`;
    if (waterEl) waterEl.textContent = `${stats.water}%`;
    if (statusPowerEl) statusPowerEl.textContent = `${stats.power}%`;
    if (statusWaterEl) statusWaterEl.textContent = `${stats.water}%`;
}

function updateHeaderName() {
    if (!myServerId) return;
    const myIdStr = myServerId.toString();
    const myEmp = window.employees.find(e => e.id.toString() === myIdStr);
    const nameEl = document.getElementById('operatorName');
    if (myEmp && nameEl) nameEl.textContent = myEmp.name;
}

function gtaCoordsToMapPercent(x, y) {
    const minX = -4000, maxX = 4200;
    const minY = -4500, maxY = 8000;
    const percentX = ((x - minX) / (maxX - minX)) * 100;
    const percentY = ((y - minY) / (maxY - minY)) * 100;
    return { x: Math.max(0, Math.min(100, percentX)), y: Math.max(0, Math.min(100, 100 - percentY)) };
}

function switchMapImage(isDay) {
    const mapImg = document.querySelector('.map-image');
    if (mapImg) mapImg.src = isDay ? 'ag_map_day.jpg' : 'ag_map_night.jpg';
}

// ===== ZONE VISUALIZATION =====
window.highlightZone = function (zoneKey) {
    const overlay = document.getElementById('mapOverlay');
    if (!overlay) return;

    // Clear previous
    overlay.innerHTML = '';

    const def = zonePolygons[zoneKey];
    if (def) {
        // Create rect
        const rect = document.createElementNS("http://www.w3.org/2000/svg", "rect");
        rect.setAttribute("x", `${def.x}%`);
        rect.setAttribute("y", `${def.y}%`);
        rect.setAttribute("width", `${def.w}%`);
        rect.setAttribute("height", `${def.h}%`);
        rect.setAttribute("class", "zone-polygon active");
        rect.setAttribute("rx", "5"); // Rounded corners

        overlay.appendChild(rect);
    }
};

window.clearHighlight = function () {
    const overlay = document.getElementById('mapOverlay');
    if (overlay) overlay.innerHTML = '';
};


// ===== DOM OVERRIDES =====

// 1. Render Calls Override
window.renderCalls = function () {
    const list = document.getElementById('callsList');
    if (!list) return;

    const callsList = window.calls || [];

    const activeCount = callsList.filter(c => c.status === 'active').length;
    const pendingCount = callsList.filter(c => c.status === 'pending').length;
    const highPriorityCount = callsList.filter(c => c.priority === 'high').length;

    const els = {
        count: document.getElementById('callsCount'),
        active: document.getElementById('activeCallsBadge'),
        pending: document.getElementById('pendingCallsBadge'),
        high: document.getElementById('highPriorityCount'),
        pendingBadge: document.getElementById('pendingBadge'),
        highBadge: document.getElementById('highPriorityBadge')
    };

    if (els.count) els.count.textContent = callsList.length;
    if (els.active) els.active.textContent = `${activeCount} Aktiv`;
    if (els.pending) els.pending.textContent = `${pendingCount} Ausstehend`;
    if (els.high) els.high.textContent = `${highPriorityCount} Hoch`;

    if (els.pendingBadge) els.pendingBadge.style.display = pendingCount > 0 ? 'inline-flex' : 'none';
    if (els.highBadge) els.highBadge.style.display = highPriorityCount > 0 ? 'inline-flex' : 'none';

    const priorityConfig = {
        high: { label: 'Hoch', color: 'red' },
        medium: { label: 'Mittel', color: 'amber' },
        low: { label: 'Niedrig', color: 'blue' },
    };

    const typeConfig = {
        power: { icon: 'amber', svg: '<path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/>' },
        water: { icon: 'blue', svg: '<path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/>' },
        emergency: { icon: 'red', svg: '<path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>' },
    };

    list.innerHTML = callsList.map(call => {
        const priority = priorityConfig[call.priority] || priorityConfig.medium;
        const type = typeConfig[call.type] || typeConfig.power;
        const isSelected = window.selectedCallId === call.id;
        const isPending = call.status === 'pending';
        const isActive = call.status === 'active';

        return `
            <div class="call-item ${isSelected ? 'selected' : ''} ${isPending ? 'pending' : ''} ${isActive ? 'active' : ''} ${call.priority === 'high' ? 'high' : ''}" 
                 onclick="selectCall('${call.id}')">
                <div class="call-header">
                    <div class="call-header-left">
                        <span class="call-id">${call.code || call.id}</span>
                        <span class="call-priority ${priority.color}">${priority.label}</span>
                    </div>
                </div>
                ${isPending ? `<button class="btn-accept" onclick="acceptCall(event, '${call.id}')">Annehmen</button>` : ''}
                ${isActive ? `<span class="call-status-badge">Angenommen</span>` : ''}
            </div>
        `;
    }).join('');
};

// 2. Accept Call Override
window.acceptCall = function (event, id) {
    if (event) event.stopPropagation();
    const call = (window.calls || []).find(c => c.id === id);
    if (call) {
        call.status = 'active'; // Optimistic update
        renderCalls();
        sendNUICallback('claimMission', { id: parseInt(id) });
    }
};

// 3. Render Map Markers Override
window.renderMapMarkers = function () {
    const container = document.getElementById('mapMarkers');
    if (!container) return;

    const markers = window.mapMarkers || [];
    const filter = window.activeFilter;

    const filtered = filter
        ? markers.filter(m => m.type === filter || (filter === 'dam' && ['dam', 'hydrant'].includes(m.type)))
        : markers;

    container.innerHTML = filtered.map(marker => {
        const isSelected = window.selectedCallId && marker.type === 'call' && (marker.label === window.selectedCallId || marker.id === window.selectedCallId);

        let color = 'var(--cyan)';
        if (marker.type === 'transformer') color = 'var(--amber)';
        if (marker.type === 'substation') color = 'var(--violet)';
        if (marker.type === 'call') color = 'var(--amber)';

        return `
            <div class="map-marker" style="left: ${marker.x}%; top: ${marker.y}%;">
                 <div class="marker-dot" style="background: ${color}; width: 14px; height: 14px;"></div>
            </div>
        `;
    }).join('');
};

// 4. Update Stats Override
window.updateStats = function () { };

// 5. Render Status Panel Override
window.renderStatusPanel = function () {
    const list = document.getElementById('statusList');
    if (!list) return;

    // Convert keys to array
    const districts = [];
    if (window.grid) {
        Object.keys(window.grid).forEach(key => {
            const data = window.grid[key];
            const name = zoneLabels[key] || key;
            districts.push({
                key: key,
                name: name,
                power: data.Power || 100,
                water: data.Water || 100,
                powerStatus: (data.Power < 20) ? 'critical' : (data.Power < 60) ? 'warning' : 'good',
                waterStatus: (data.Water < 20) ? 'critical' : (data.Water < 60) ? 'warning' : 'good'
            });
        });
    }

    let html = `
        <div class="status-section">
            <div class="status-section-header muted">
                <svg class="icon-sm" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <polyline points="23 6 13.5 15.5 8.5 10.5 1 18"/>
                    <polyline points="17 6 23 6 23 12"/>
                </svg>
                <span>Stadtteile (Live)</span>
            </div>
            ${districts.map(district => {
        const cardClass = (district.powerStatus === 'critical' || district.waterStatus === 'critical') ? 'critical' :
            (district.powerStatus === 'warning' || district.waterStatus === 'warning') ? 'warning' : 'normal';

        return `
                    <div class="district-card ${cardClass}" 
                         onmouseenter="highlightZone('${district.key}')" 
                         onmouseleave="clearHighlight()">
                        <div class="district-header">
                            <span class="district-name">${district.name}</span>
                        </div>
                        <div class="district-bars">
                            <div class="bar-item">
                                <div class="bar-header amber">
                                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/>
                                    </svg>
                                    <span class="bar-value ${district.power >= 80 ? 'emerald' : district.power >= 60 ? 'amber' : 'red'}">${district.power}%</span>
                                </div>
                                <div class="progress-bar">
                                    <div class="progress-fill ${district.power >= 80 ? 'emerald' : district.power >= 60 ? 'amber' : 'red'}" style="width: ${district.power}%"></div>
                                </div>
                            </div>
                            <div class="bar-item">
                                <div class="bar-header blue">
                                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/>
                                    </svg>
                                    <span class="bar-value ${district.water >= 80 ? 'blue' : district.water >= 60 ? 'amber' : 'red'}">${district.water}%</span>
                                </div>
                                <div class="progress-bar">
                                    <div class="progress-fill ${district.water >= 80 ? 'blue' : district.water >= 60 ? 'amber' : 'red'}" style="width: ${district.water}%"></div>
                                </div>
                            </div>
                        </div>
                    </div>
                `;
    }).join('')}
        </div>
    `;

    list.innerHTML = html;
};

// 6. Render Employees Override
window.renderEmployees = function () {
    const list = document.getElementById('employeeList');
    if (!list) return;

    const emps = window.employees || [];
    const availableCount = emps.filter(e => e.status === 'available').length;
    const busyCount = emps.filter(e => e.status === 'busy').length;

    const elCount = document.getElementById('employeeCount');
    const elAvail = document.getElementById('availableCount');
    const elBusy = document.getElementById('busyCount');

    if (elCount) elCount.textContent = emps.length;
    if (elAvail) elAvail.textContent = availableCount;
    if (elBusy) elBusy.textContent = busyCount;

    const unitIcons = {
        electrician: { color: 'amber', svg: '<path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/>' },
        water: { color: 'blue', svg: '<path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/>' },
        trainee: { color: 'emerald', svg: '<path d="M22 10v6M2 10l10-5 10 5-10 5z"/><path d="M6 12v5c3 3 9 3 12 0v-5"/>' },
        dispatcher: { color: 'cyan', svg: '<path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/>' },
        manager: { color: 'purple', svg: '<path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/>' },
        technician: { color: 'blue', svg: '<path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/>' },
    };

    const statusConfig = {
        available: { label: 'Verfügbar', color: 'emerald' },
        busy: { label: 'Im Einsatz', color: 'amber' },
        offduty: { label: 'Außer Dienst', color: 'slate' },
        break: { label: 'In Pause', color: 'blue' }
    };

    list.innerHTML = emps.map(emp => {
        const unit = unitIcons[emp.unit] || unitIcons.technician;
        const status = statusConfig[emp.status] || statusConfig.available;

        return `
            <div class="employee-item">
                <div class="employee-row">
                    <div class="unit-icon ${unit.color}">
                        <svg class="icon-sm" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            ${unit.svg}
                        </svg>
                    </div>
                    <div class="employee-info">
                        <div class="employee-name-row">
                            <span class="employee-name">${emp.name}</span>
                        </div>
                        <div class="employee-badge" style="color:var(--muted); font-size:11px;">
                            ${emp.jobRole} 
                        </div>
                        <div class="employee-status-row">
                             <div class="status-dot-small ${status.color}"></div>
                             <span style="font-size:10px; color:var(--muted)">${status.label}</span>
                        </div>
                    </div>
                </div>
            </div>
        `;
    }).join('');
};

window.setStatus = function (status, element) {
    const dot = document.getElementById('operatorStatusDot');
    const text = document.getElementById('operatorStatusText');
    const statusConfig = {
        available: { dot: 'emerald', text: 'Verfügbar', color: 'var(--emerald)' },
        busy: { dot: 'amber', text: 'Im Einsatz', color: 'var(--amber)' },
        break: { dot: 'blue', text: 'In Pause', color: 'var(--blue)' },
        offduty: { dot: 'slate', text: 'Außer Dienst', color: 'var(--muted)' },
    };

    if (dot && text && statusConfig[status]) {
        const config = statusConfig[status];
        dot.className = 'status-dot ' + config.dot;
        text.textContent = `(${config.text})`;
        text.style.color = config.color;
    }
    document.querySelectorAll('.dropdown-item').forEach(el => el.classList.remove('active'));
    if (element) element.classList.add('active');

    sendNUICallback('setStatus', { status: status });
};

window.logout = function () {
    hideDispatchUI();
    sendNUICallback('close');
};

// ===== Set Initial Empty State =====
window.calls = [];
window.employees = [];

window.addEventListener('DOMContentLoaded', () => {
    // Force empty
    window.calls = [];
    window.employees = [];
    renderCalls();
    renderEmployees();
});

console.log('[AG-PowerWater] NUI Integration Ready (Refined Map Zones)');
