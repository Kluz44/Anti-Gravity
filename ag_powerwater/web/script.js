// ===== Global State =====
let isVisible = false;
let currentCalls = [];
let currentEmployees = [];
let selectedCallId = null;
let isDay = true;
let gridStats = { power: 100, water: 100 };
let mapScale = 1;
let mapPan = { x: 0, y: 0 };
let isDragging = false;
let dragStart = { x: 0, y: 0 };

// ===== DOM Elements =====
const ui = document.getElementById('dispatch-ui');
const employeeList = document.getElementById('employee-list');
const employeeCount = document.getElementById('employee-count');
const callsList = document.getElementById('calls-list');
const callsCount = document.getElementById('calls-count');
const mapImage = document.getElementById('map-image');
const mapMarkers = document.getElementById('map-markers');
const mapInner = document.getElementById('map-inner');
const statPower = document.getElementById('stat-power');
const statWater = document.getElementById('stat-water');
const statCritical = document.getElementById('stat-critical');
const statActive = document.getElementById('stat-active');

// ===== NUI Message Listener =====
window.addEventListener('message', (event) => {
    const { action, data } = event.data;
    console.log('[AG-UI] Received NUI message:', action, data);

    switch (action) {
        case 'openDispatch':
            handleOpen(data);
            break;
        case 'updateMissions':
            updateMissions(data);
            break;
        case 'close':
            handleClose();
            break;
    }
});

// ===== NUI Callback Helper =====
function sendNUICallback(action, data = {}) {
    const resourceName = GetParentResourceName();
    fetch(`https://${resourceName}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    }).catch(err => console.error('[AG-UI] NUI Callback Error:', err));
}

function GetParentResourceName() {
    // FiveM provides resource name via location
    const matches = window.location.pathname.match(/\/([^/]+)\/web\//);
    if (matches && matches[1]) {
        return matches[1];
    }
    return 'ag_powerwater'; // Fallback
}

// ===== Open/Close Handlers =====
function handleOpen(data) {
    isVisible = true;
    ui.classList.remove('hidden');

    if (data.missions) updateMissions(data.missions);
    if (data.techs) updateEmployees(data.techs);
    if (data.stats) updateStats(data.stats);
    if (data.isDay !== undefined) {
        isDay = data.isDay;
        mapImage.src = isDay ? 'ag_map_day.jpg' : 'ag_map_night.jpg';
    }
}

function handleClose() {
    isVisible = false;
    ui.classList.add('hidden');
}

// ===== Data Update Functions =====
function updateMissions(missions) {
    // Convert Lua table to array
    const missionsArray = Object.values(missions || {});
    currentCalls = missionsArray.map(m => ({
        id: m.id.toString(),
        code: `CODE-${m.id}`,
        title: m.label || 'Unknown Mission',
        description: `Type: ${m.subType}. Priority: ${m.priority}`,
        location: `X: ${Math.round(m.coords.x)}, Y: ${Math.round(m.coords.y)}`,
        coordinates: m.coords,
        priority: m.priority === 'emergency' ? 'high' : 'medium',
        timestamp: 'Now',
        assignedUnits: m.assigned || [],
        status: (m.assigned && m.assigned.length > 0) ? 'active' : 'pending',
        type: (m.subType === 'pipe_burst' || m.subType === 'hydrant') ? 'water' : 'power'
    }));

    renderCalls();
    renderMapMarkers();
    updateStatsBar();
}

function updateEmployees(techs) {
    currentEmployees = (techs || []).map(t => ({
        id: t.source ? t.source.toString() : '0',
        name: t.name,
        badge: '00' + t.source,
        unit: 'technician',
        status: t.job === 'unemployed' ? 'offduty' : 'available',
        location: 'Roaming',
        jobRole: 'Elektriker'
    }));

    renderEmployees();
}

function updateStats(stats) {
    gridStats = stats;
    statPower.textContent = `${stats.power}%`;
    statWater.textContent = `${stats.water}%`;
}

function updateStatsBar() {
    const activeCalls = currentCalls.filter(c => c.status === 'active').length;
    const criticalCalls = currentCalls.filter(c => c.priority === 'high').length;

    statActive.textContent = activeCalls.toString();
    statCritical.textContent = `${criticalCalls} Aufträge`;
}

// ===== Render Functions =====
function renderEmployees() {
    employeeCount.textContent = currentEmployees.length.toString();

    if (currentEmployees.length === 0) {
        employeeList.innerHTML = '<div style="padding: 1rem; text-align: center; color: var(--text-muted); font-size: 0.875rem;">No active units</div>';
        return;
    }

    employeeList.innerHTML = currentEmployees.map(emp => `
        <div class="employee-item">
            <div class="employee-avatar">${emp.name.charAt(0).toUpperCase()}</div>
            <div class="employee-info">
                <div class="employee-name">${emp.name}</div>
                <div class="employee-role">${emp.jobRole} • ${emp.badge}</div>
            </div>
            <div class="employee-status"></div>
        </div>
    `).join('');
}

function renderCalls() {
    callsCount.textContent = currentCalls.length.toString();

    if (currentCalls.length === 0) {
        callsList.innerHTML = '<div style="padding: 1rem; text-align: center; color: var(--text-muted); font-size: 0.875rem;">No active calls</div>';
        return;
    }

    callsList.innerHTML = currentCalls.map(call => `
        <div class="call-card priority-${call.priority} status-${call.status}" data-call-id="${call.id}">
            <div class="call-header">
                <div>
                    <div class="call-title">${call.title}</div>
                    <div class="call-code">${call.code}</div>
                </div>
                <div class="priority-badge ${call.priority}">${call.priority.toUpperCase()}</div>
            </div>
            <div class="call-description">${call.description}</div>
            <div class="call-location">📍 ${call.location}</div>
            <div class="call-actions">
                <button class="btn-claim" onclick="claimMission('${call.id}', ${call.coordinates.x}, ${call.coordinates.y})" ${call.status === 'active' ? 'disabled' : ''}>
                    ${call.status === 'active' ? 'ASSIGNED' : 'CLAIM'}
                </button>
            </div>
        </div>
    `).join('');

    // Add click handlers for selection
    document.querySelectorAll('.call-card').forEach(card => {
        card.addEventListener('click', (e) => {
            if (!e.target.classList.contains('btn-claim')) {
                selectedCallId = card.dataset.callId;
                renderMapMarkers();
            }
        });
    });
}

function renderMapMarkers() {
    mapMarkers.innerHTML = currentCalls.map(call => {
        const pos = gtaCoordsToMapPercent(call.coordinates.x, call.coordinates.y);
        const isSelected = call.id === selectedCallId;

        return `
            <div class="map-marker" style="left: ${pos.x}%; top: ${pos.y}%;">
                <div class="marker-pin ${isSelected ? 'selected' : ''}" style="background: ${call.priority === 'high' ? 'var(--color-error)' : 'var(--color-warning)'}"></div>
                ${isSelected ? `<div class="marker-label">${call.title}</div>` : ''}
            </div>
        `;
    }).join('');
}

// ===== GTA Coordinate Conversion =====
function gtaCoordsToMapPercent(x, y) {
    // GTA V map bounds (approximate)
    const minX = -4000;
    const maxX = 4200;
    const minY = -4500;
    const maxY = 8000;

    // Convert to 0-100%
    const percentX = ((x - minX) / (maxX - minX)) * 100;
    const percentY = ((y - minY) / (maxY - minY)) * 100;

    // Flip Y axis (GTA Y increases north, but CSS top increases down)
    return {
        x: Math.max(0, Math.min(100, percentX)),
        y: Math.max(0, Math.min(100, 100 - percentY))
    };
}

// ===== Mission Claim Handler =====
function claimMission(id, x, y) {
    sendNUICallback('claimMission', { id: parseInt(id), x, y });

    // Optimistic update
    currentCalls = currentCalls.map(call =>
        call.id === id
            ? { ...call, status: 'active', assignedUnits: ['Me'] }
            : call
    );
    renderCalls();
    updateStatsBar();
}

// ===== Map Interaction =====
mapInner.addEventListener('mousedown', (e) => {
    isDragging = true;
    dragStart = { x: e.clientX - mapPan.x, y: e.clientY - mapPan.y };
});

document.addEventListener('mousemove', (e) => {
    if (!isDragging) return;

    mapPan.x = e.clientX - dragStart.x;
    mapPan.y = e.clientY - dragStart.y;
    updateMapTransform();
});

document.addEventListener('mouseup', () => {
    isDragging = false;
});

mapInner.addEventListener('wheel', (e) => {
    e.preventDefault();

    const delta = e.deltaY > 0 ? -0.1 : 0.1;
    mapScale = Math.max(0.5, Math.min(3, mapScale + delta));
    updateMapTransform();
});

function updateMapTransform() {
    mapInner.style.transform = `translate(${mapPan.x}px, ${mapPan.y}px) scale(${mapScale})`;
}

// Toolbar buttons
document.getElementById('btn-zoom-in').addEventListener('click', () => {
    mapScale = Math.min(3, mapScale + 0.2);
    updateMapTransform();
});

document.getElementById('btn-zoom-out').addEventListener('click', () => {
    mapScale = Math.max(0.5, mapScale - 0.2);
    updateMapTransform();
});

document.getElementById('btn-reset').addEventListener('click', () => {
    mapScale = 1;
    mapPan = { x: 0, y: 0 };
    updateMapTransform();
});

// ===== Tab Switching =====
document.querySelectorAll('.tab-header').forEach(tab => {
    tab.addEventListener('click', () => {
        const tabName = tab.dataset.tab;

        // Update headers
        document.querySelectorAll('.tab-header').forEach(t => t.classList.remove('active'));
        tab.classList.add('active');

        // Update content
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
        document.getElementById(`tab-${tabName}`).classList.add('active');
    });
});

// ===== ESC Key to Close =====
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && isVisible) {
        handleClose();
        sendNUICallback('close');
    }
});

// ===== Initialization =====
console.log('[AG-Dispatch] Script loaded');
console.log('[AG-Dispatch] UI Element:', ui);
console.log('[AG-Dispatch] Resource Name:', GetParentResourceName());

// Ensure DOM is ready before accessing elements
if (!ui) {
    console.error('[AG-Dispatch] CRITICAL: dispatch-ui element not found!');
}
