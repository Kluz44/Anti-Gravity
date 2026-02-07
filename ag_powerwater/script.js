const tabletUi = document.getElementById('tablet-ui');
const missionList = document.getElementById('mission-list-container');
const missionCount = document.getElementById('mission-count');
let mySource = 0;

const techList = document.getElementById('tech-list');
const techCount = document.getElementById('tech-count');

const mapContainer = document.getElementById('game-map');

console.log('[AG-UI] Script Loaded');
console.log('[AG-UI] Location:', window.location.href);

// Debug Image Loading
fetch('ag_logo.png')
    .then(response => {
        console.log('[AG-UI] Fetch ag_logo.png status:', response.status);
    })
    .catch(err => console.error('[AG-UI] Fetch error:', err));

window.addEventListener('message', (event) => {
    const data = event.data;
    console.log('[AG-UI] Received Action:', data.action);

    if (data.action === 'openDispatch') {
        mySource = data.data.mySource;
        renderMissions(data.data.missions);
        renderTechs(data.data.techs);
        renderMapPins(data.data.missions);

        // Day/Night Toggle
        const isDay = data.data.isDay;
        const mapUrl = isDay ? 'ag_map_day.jpg' : 'ag_map_night.jpg';
        console.log('[AG-UI] Setting Map URL:', mapUrl);
        if (mapContainer) mapContainer.style.backgroundImage = `url('${mapUrl}')`;

        // Update Stats
        if (data.data.stats) {
            updateStats(data.data.stats.power, data.data.stats.water);
        }

        tabletUi.classList.remove('hidden');
    } else if (data.action === 'updateMissions') {
        renderMissions(data.data);
        renderMapPins(data.data); // Update pins too
    } else if (data.action === 'close') {
        tabletUi.classList.add('hidden');
    }
});

function renderMapPins(missions) {
    if (!mapContainer) return;
    mapContainer.innerHTML = ''; // Clear old pins

    if (!missions) return;

    // Bounds for GTA V Map (Approximate for full map image)
    const mapWidth = 8500;
    const mapHeight = 12000;
    const xOffset = 4000; // X starts at -4000
    const yOffset = 8000; // Y starts at 8000 (Top)

    Object.values(missions).forEach(m => {
        if (m.status === 'completed') return;

        // Calculate Position
        // Left % = (x + 4000) / 8500
        const left = ((m.coords.x + xOffset) / mapWidth) * 100;

        // Top % = (8000 - y) / 12000 (Inverted Y axis)
        const top = ((yOffset - m.coords.y) / mapHeight) * 100;

        // Check bounds (sanity check)
        if (left < 0 || left > 100 || top < 0 || top > 100) return;

        const pin = document.createElement('div');

        // Style class
        let typeClass = m.priority === 'emergency' ? 'emergency' : 'routine';
        const isAssignedToMe = m.assigned && m.assigned.includes(mySource);
        if (isAssignedToMe) typeClass += ' me';
        else if (m.assigned && m.assigned.length > 0) typeClass += ' assigned';

        pin.className = `map-pin ${typeClass}`;
        pin.style.left = `${left}%`;
        pin.style.top = `${top}%`;
        pin.title = m.label || 'Mission'; // Tooltip

        // Click to claim logic re-use?
        pin.onclick = () => {
            claimMission(m.id, m.coords.x, m.coords.y);
        };

        mapContainer.appendChild(pin);
    });
}

function renderTechs(techs) {
    techList.innerHTML = '';
    if (!techs) {
        techCount.textContent = '0';
        return;
    }

    techCount.textContent = techs.length;

    techs.forEach(t => {
        const li = document.createElement('li');
        li.className = 'tech-item';

        li.innerHTML = `
            <span class="dot"></span>
            <div class="tech-info">
                <span class="tech-name">${t.name}</span>
                <span class="tech-rank">${t.job.toUpperCase()} - ${t.grade}</span>
            </div>
        `;
        techList.appendChild(li);
    });
}

function updateStats(power, water) {
    const powerFill = document.getElementById('power-fill');
    const powerValue = document.getElementById('power-value');
    const waterFill = document.getElementById('water-fill');
    const waterValue = document.getElementById('water-value');

    if (powerFill && powerValue) {
        powerFill.style.width = `${power}%`;
        powerValue.textContent = `${power}%`;
        // Color coding
        powerFill.style.backgroundColor = power < 40 ? '#ff4444' : '#ffaa00';
    }

    if (waterFill && waterValue) {
        waterFill.style.width = `${water}%`;
        waterValue.textContent = `${water}%`;
        waterFill.style.backgroundColor = water < 40 ? '#ff4444' : '#00aaff';
    }
}

function renderMissions(missions) {
    missionList.innerHTML = ''; // Clear old content
    if (!missions) return;

    // Convert object to array for sorting
    const missionArray = Object.values(missions).sort((a, b) => {
        // Priority: Emergency > Routine
        if (a.priority === 'emergency' && b.priority !== 'emergency') return -1;
        if (b.priority === 'emergency' && a.priority !== 'emergency') return 1;
        return a.id - b.id; // Oldest first
    });

    missionCount.textContent = missionArray.length;

    missionArray.forEach(m => {
        if (m.status === 'completed') return; // Don't show completed

        const card = document.createElement('div');

        // Determine State
        const isAssignedToMe = m.assigned && m.assigned.includes(mySource);
        const isAssignedToSomeone = m.assigned && m.assigned.length > 0;

        let typeClass = m.priority === 'emergency' ? 'emergency' : 'routine';
        if (isAssignedToSomeone && !isAssignedToMe) typeClass += ' assigned';

        card.className = `mission-card ${typeClass}`;

        // Icons
        let iconClass = 'fas fa-exclamation-circle';
        if (m.subType === 'turbine_fire') iconClass = 'fas fa-fire';
        if (m.subType === 'pipe_burst') iconClass = 'fas fa-water';
        if (m.subType === 'hydrant') iconClass = 'fas fa-wrench';
        if (m.subType === 'house_call') iconClass = 'fas fa-home';

        // Button State
        let btnText = 'CLAIM';
        let btnClass = 'action-btn';
        if (isAssignedToMe) {
            btnText = 'GPS SET';
            btnClass += ' active';
        } else if (isAssignedToSomeone) {
            btnText = 'JOIN'; // Allow multi-assign
        }

        // HTML Content
        card.innerHTML = `
            <div class="icon"><i class="${iconClass}"></i></div>
            <div class="details">
                <h4>${m.label || 'Unknown Mission'}</h4>
                <p>${m.subType ? m.subType.replace('_', ' ').toUpperCase() : 'General Task'} - ID: ${m.id}</p>
            </div>
            <button class="${btnClass}" onclick="claimMission(${m.id}, ${m.coords.x}, ${m.coords.y})">${btnText}</button>
        `;

        missionList.appendChild(card);
    });
}

function claimMission(id, x, y) {
    // Optimistic UI update? No, wait for server sync usually.
    // Send to Client
    fetch(`https://${GetParentResourceName()}/claimMission`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({
            id: id,
            x: x,
            y: y
        })
    });
}

// Map Interaction State
let mapState = {
    scale: 1,
    panning: false,
    pointX: 0,
    pointY: 0,
    startX: 0,
    startY: 0
};

function setupMapInteractions() {
    if (!mapContainer) return;

    // Force Square Aspect Ratio logic is handled by CSS (width: 100%, height: 100%, object-fit)
    // But for background-image, we should ensure the div itself is treated as the map canvas.
    // If we use 'contain', the image is smaller than the div.
    // Let's use 'cover' style for the background, but we need to ensure the coordinate system matches.
    // GTA Map is Square. If we stretch 100% 100% on a rectangular div, it distorts.
    // Better: Make mapContainer a flexible window, but the content inside (a new div) the actual map.
    // For now, let's just make the existing mapContainer draggable/zoomable.

    // Zoom (Wheel)
    mapContainer.onwheel = function (e) {
        e.preventDefault();
        const xs = (e.clientX - mapState.pointX) / mapState.scale;
        const ys = (e.clientY - mapState.pointY) / mapState.scale;

        const delta = (e.wheelDelta ? e.wheelDelta : -e.deltaY);
        (delta > 0) ? (mapState.scale *= 1.2) : (mapState.scale /= 1.2);

        // Limits
        if (mapState.scale < 1) mapState.scale = 1;
        if (mapState.scale > 5) mapState.scale = 5;

        mapState.pointX = e.clientX - xs * mapState.scale;
        mapState.pointY = e.clientY - ys * mapState.scale;

        updateMapTransform();
    };

    // Pan (Mouse)
    mapContainer.onmousedown = function (e) {
        e.preventDefault();
        mapState.startX = e.clientX - mapState.pointX;
        mapState.startY = e.clientY - mapState.pointY;
        mapState.panning = true;
        mapContainer.style.cursor = 'grabbing';
    };

    mapContainer.onmouseup = function (e) {
        mapState.panning = false;
        mapContainer.style.cursor = 'grab';
    };

    mapContainer.onmousemove = function (e) {
        e.preventDefault();
        if (!mapState.panning) return;
        mapState.pointX = e.clientX - mapState.startX;
        mapState.pointY = e.clientY - mapState.startY;
        updateMapTransform();
    };
}

function updateMapTransform() {
    // Apply transform
    mapContainer.style.transform = `translate(${mapState.pointX}px, ${mapState.pointY}px) scale(${mapState.scale})`;
}

// Call setup on load
setupMapInteractions();

// Escape key to close
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).then(() => {
            tabletUi.classList.add('hidden');
        });
    }
});

