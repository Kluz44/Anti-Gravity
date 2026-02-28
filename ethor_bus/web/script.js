// ==========================================
// Boss Dispatch NUI Logic
// ==========================================

let mapZoom = 1.0;
let panX = 0;
let panY = 0;
let isDragging = false;
let startX, startY;
let stopsData = [];
let linesData = [];

window.addEventListener('message', function (event) {
    const data = event.data;

    if (data.action === "openDispatch") {
        try {
            $("#dispatch-ui").fadeIn(300);
            // Reset view on open
            mapZoom = 1.0;
            panX = 0;
            panY = 0;
            applyZoom();

            // Populate initially
            if (data.stops) {
                stopsData = Object.values(data.stops || {});
                renderStops();
                renderMapMarkers();
            }
            if (data.routes || data.lines) {
                linesData = Object.values(data.routes || data.lines || {});
                renderLines();
            }
        } catch (e) {
            console.error(e);
            fetch(`https://${GetParentResourceName()}/nuiError`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ error: String(e), stack: e.stack })
            }).catch(err => console.log("Fetch Error Failed", err));
        }
    }
});

// Tab Switching
$('.tab-btn').on('click', function () {
    $('.tab-btn').removeClass('active');
    $(this).addClass('active');

    const tabId = $(this).data('tab');
    $('.tab-pane').removeClass('active');
    $('#tab-' + tabId).addClass('active');
});

// Close UI
$('#close-dispatch').on('click', function () {
    $("#dispatch-ui").fadeOut(300, function () {
        $.post('https://ethor_bus/closeUI', JSON.stringify({}));
    });
});

// Esc Key
document.addEventListener('keydown', function (event) {
    if (event.key === "Escape") {
        $('#close-dispatch').click();
    }
});

// Map Zooming
$('#zoom-in').on('click', function () {
    if (mapZoom < 3.0) {
        mapZoom += 0.2;
        applyZoom();
    }
});

$('#zoom-out').on('click', function () {
    if (mapZoom > 1.0) {
        mapZoom -= 0.2;
        // Clamp to exactly 1.0 to avoid floating point issues (e.g. 1.0000000000000002)
        if (mapZoom < 1.0) mapZoom = 1.0;
        applyZoom();
    }
});

// Map Panning (Dragging)
$('#gta-map').on('mousedown', function (e) {
    // Prevent dragging if clicking a button inside map-section
    if ($(e.target).closest('.map-controls').length > 0) return;

    isDragging = true;
    startX = e.clientX - panX;
    startY = e.clientY - panY;
    $(this).css({ 'cursor': 'grabbing', 'transition': 'none' });
});

$(document).on('mousemove', function (e) {
    if (!isDragging) return;
    e.preventDefault(); // prevent text selection
    panX = e.clientX - startX;
    panY = e.clientY - startY;
    applyZoom();
});

$(document).on('mouseup mouseleave', function () {
    if (isDragging) {
        isDragging = false;
        $('#gta-map').css({ 'cursor': 'grab', 'transition': 'transform 0.2s cubic-bezier(0.2, 0, 0, 1)' });
    }
});

function applyZoom() {
    $('#gta-map').css('transform', `translate(${panX}px, ${panY}px) scale(${mapZoom})`);
}

// Render Data Utilities
function renderStops() {
    const container = $('#stop-list-container');
    container.empty();

    if (stopsData.length === 0) {
        container.append('<p style="color:var(--text-muted); font-size:14px;">Keine Haltestellen gefunden.</p>');
        return;
    }

    stopsData.forEach(stop => {
        container.append(`
            <li class="list-item">
                <div class="item-info">
                    <h4>${stop.name}</h4>
                    <p>Base Demand: ${stop.base_demand} | Profile: ${stop.rush_profile}</p>
                </div>
                <button class="btn-primary" style="background:var(--bg-main); border:1px solid var(--border);">Edit</button>
            </li>
        `);
    });
}

function renderLines() {
    const container = $('#line-list-container');
    container.empty();

    if (linesData.length === 0) {
        container.append('<p style="color:var(--text-muted); font-size:14px;">Aktuell gibt es keine Linien für dieses Unternehmen.</p>');
        return;
    }

    linesData.forEach(line => {
        container.append(`
            <li class="list-item" style="border-left: 4px solid ${line.color};">
                <div class="item-info">
                    <h4>${line.name}</h4>
                    <p>Haltestellen: ${line.stops ? line.stops.length : 0}</p>
                </div>
                <button class="btn-primary" style="background:var(--bg-main); border:1px solid var(--border);">Route zeigen</button>
            </li>
        `);
    });
}

// Coordinate mapping (Match ag_powerwater scale precisely)
function mapGtaToPixels(x, y) {
    const minX = -4000;
    const maxX = 4200;
    const minY = -4500;
    const maxY = 8000;

    const percentX = ((x - minX) / (maxX - minX)) * 100;
    const percentY = ((y - minY) / (maxY - minY)) * 100;

    return {
        px: Math.max(0, Math.min(100, percentX)),
        py: Math.max(0, Math.min(100, 100 - percentY))
    };
}

function renderMapMarkers() {
    const map = $('#gta-map');
    map.find('.map-marker').remove(); // Clear existing

    stopsData.forEach(stop => {
        if (!stop.coords) return;
        let coords;
        try {
            coords = typeof stop.coords === 'string' ? JSON.parse(stop.coords) : stop.coords;
        } catch (e) { return; }

        if (coords && coords.x && coords.y) {
            const pos = mapGtaToPixels(coords.x, coords.y);
            const marker = $(`
                <div class="map-marker" style="left: ${pos.px}%; top: ${pos.py}%;">
                    <div class="tooltip">${stop.name}</div>
                </div>
            `);
            map.append(marker);
        }
    });
}

function renderLiveBuses(buses) {
    const map = $('#gta-map');
    map.find('.bus-blip').remove(); // Clear old live blips

    buses.forEach(bus => {
        if (!bus.coords) return;

        let color = bus.isMaterialized ? '#ef4444' : '#f59e0b'; // Red if real human/materialized, Orange if virtual
        let icon = bus.isMaterialized ? 'fa-bus' : 'fa-ghost';

        const pos = mapGtaToPixels(bus.coords.x, bus.coords.y);
        const blip = $(`
            <div class="map-marker bus-blip" style="left: ${pos.px}%; top: ${pos.py}%; background: ${color}; width:20px; height:20px;">
                <i class="fa-solid ${icon}" style="font-size: 10px; color: white;"></i>
                <div class="tooltip" style="bottom: 25px;">${bus.id}<br>${bus.state}</div>
            </div>
        `);
        map.append(blip);
    });
}

// ==========================================
// Heatmap Logic
// ==========================================
let isHeatmapActive = false;

$('#toggle-heatmap').click(function () {
    isHeatmapActive = !isHeatmapActive;
    if (isHeatmapActive) {
        $(this).addClass('active');
        $(this).css('background', '#ef4444'); // Red active state
        $.post(`https://${GetParentResourceName()}/requestHeatmap`);
    } else {
        $(this).removeClass('active');
        $(this).css('background', '');
        $('#gta-map').find('.heatmap-blip').remove();
    }
});

function renderHeatmap(data) {
    if (!isHeatmapActive) return;

    const map = $('#gta-map');
    map.find('.heatmap-blip').remove(); // Clear old

    data.forEach(point => {
        const pos = mapGtaToPixels(point.x, point.y);
        // Weight determines opacity and size (roughly)
        let size = 30 + (point.weight * 50);
        let opacity = 0.4 + (point.weight * 0.4);
        let color = point.weight > 0.6 ? '#ef4444' : '#f59e0b'; // Red for hot, yellow for medium

        const blip = $(`
            <div class="heatmap-blip" style="
                position: absolute;
                left: ${pos.px}%; 
                top: ${pos.py}%;
                width: ${size}px;
                height: ${size}px;
                background: radial-gradient(circle, ${color} 0%, transparent 70%);
                opacity: ${opacity};
                border-radius: 50%;
                transform: translate(-50%, -50%);
                pointer-events: none;
                z-index: 1;">
            </div>
        `);
        map.append(blip);
    });
}

// ==========================================
// Driver UI Logic
// ==========================================

window.addEventListener('message', function (event) {
    const data = event.data;

    if (data.action === "toggleDriverUI") {
        if (data.show) {
            $('#driver-ui').fadeIn(200);
            updateDriverInfo(data.info);
        } else {
            $('#driver-ui').fadeOut(200);
        }
    } else if (data.action === "updateDriverUI") {
        updateDriverInfo(data.info);
    } else if (data.action === "enableUIDragMode") {
        // Visually highlight that it's draggable
        $('#driver-ui').css({
            'box-shadow': '0 0 15px rgba(255, 255, 255, 0.4)',
            'border': '1px solid rgba(255, 255, 255, 0.8)'
        });
    } else if (data.action === "resetUIPosition") {
        localStorage.removeItem('ag_driver_ui_pos');
        $('#driver-ui').css({
            top: 'auto',
            left: 'auto',
            bottom: '20px',
            right: '20px'
        });
    }
});

// Initialize Draggable Driver UI
$(document).ready(function () {
    const driverUI = $('#driver-ui');

    // Make it draggable
    driverUI.draggable({
        handle: ".driver-panel", // Drag by the main panel
        containment: "window",    // Keep within screen bounds
        start: function (event, ui) {
            // Un-anchor the bottom/right coordinates so it doesn't stretch when setting top/left
            $(this).css({
                bottom: 'auto',
                right: 'auto'
            });
        },
        stop: function (event, ui) {
            // Save position to localStorage when dragging stops
            localStorage.setItem('ag_driver_ui_pos', JSON.stringify({
                top: ui.position.top,
                left: ui.position.left
            }));
        }
    });

    // Restore position on load
    const savedPos = localStorage.getItem('ag_driver_ui_pos');
    if (savedPos) {
        try {
            const pos = JSON.parse(savedPos);
            driverUI.css({
                top: pos.top + 'px',
                left: pos.left + 'px',
                bottom: 'auto', // Override CSS bottom/right bounds
                right: 'auto'
            });
        } catch (e) { }
    }

    // Add visual cue for dragging
    $('.driver-panel').css('cursor', 'move');

    // Handle Escape Key to exit drag mode
    $(document).on('keydown', function (e) {
        if (e.key === "Escape") {
            // Remove highlight
            $('#driver-ui').css({
                'box-shadow': 'none',
                'border': '1px solid rgba(255, 255, 255, 0.1)'
            });
            // Tell Lua we're done
            $.post(`https://${GetParentResourceName()}/exitDragMode`, JSON.stringify({}));
        }
    });
});

function updateDriverInfo(info) {
    if (!info) return;

    if (info.line) $('#drv-line').text(info.line);
    if (info.nextStop) $('#drv-next-stop').text(info.nextStop);
    if (info.eta) $('#drv-eta').text(info.eta);
    if (info.pax) $('#drv-pax').text(info.pax);
    if (info.mood) $('#drv-mood').text(info.mood + '%');

    // Doors
    if (info.doorFront !== undefined) {
        if (info.doorFront) {
            $('#door-front').addClass('open').html('<div style="display:flex; flex-direction:column; align-items:center; line-height:1.2;"><span><i class="fa-solid fa-door-open"></i> Tür 1</span><span style="font-size:10px; opacity:0.8;">(Offen)</span></div>');
        } else {
            $('#door-front').removeClass('open').html('<div style="display:flex; flex-direction:column; align-items:center; line-height:1.2;"><span><i class="fa-solid fa-door-closed"></i> Tür 1</span><span style="font-size:10px; opacity:0.8;">(Geschlossen)</span></div>');
        }
    }

    if (info.doorRear !== undefined) {
        if (info.doorRear) {
            $('#door-rear').addClass('open').html('<div style="display:flex; flex-direction:column; align-items:center; line-height:1.2;"><span><i class="fa-solid fa-door-open"></i> Tür 2</span><span style="font-size:10px; opacity:0.8;">(Offen)</span></div>');
        } else {
            $('#door-rear').removeClass('open').html('<div style="display:flex; flex-direction:column; align-items:center; line-height:1.2;"><span><i class="fa-solid fa-door-closed"></i> Tür 2</span><span style="font-size:10px; opacity:0.8;">(Geschlossen)</span></div>');
        }
    }

    // Stop Request Alert
    if (info.stopRequest) {
        $('#stop-request-alert').fadeIn(200);
    } else {
        $('#stop-request-alert').fadeOut(200);
    }
}

// Driver Interaction Buttons
$('#btn-skip-stop').on('click', function () {
    $.post('https://ethor_bus/driverAction', JSON.stringify({ action: 'skip_stop' }));
});

$('#btn-service').on('click', function () {
    $.post('https://ethor_bus/driverAction', JSON.stringify({ action: 'toggle_service' }));
});

// ==========================================
// Passenger Stop UI Logic
// ==========================================

window.addEventListener('message', function (event) {
    const data = event.data;

    if (data.action === "openPassengerUI") {
        $('#passenger-ui').fadeIn(200);

        $('#board-stop-name').text(data.stopName);
        $('#board-time').text(data.time);

        const list = $('#board-list');
        list.empty();

        if (data.buses && data.buses.length > 0) {
            data.buses.forEach(bus => {
                const fullBadge = bus.isFull ? '<span class="badge-full">VOLL</span>' : '';
                const delayText = bus.delay > 0 ? `<span class="delayed">(+${bus.delay})</span>` : '';

                list.append(`
                    <li>
                        <span class="l-badge" style="background: ${bus.color || '#3b82f6'};">${bus.line}</span>
                        <span class="l-dest">${bus.destination} ${fullBadge}</span>
                        <span class="l-time">${bus.eta} Min ${delayText}</span>
                    </li> 
                `);
            });
        } else {
            list.append('<li style="color:#9ca3af; justify-content:center;">Keine Abfahrten in Kürze.</li>');
        }
    } else if (data.action === "closePassengerUI") {
        $('#passenger-ui').fadeOut(200);
    }
});

// ==========================================
// In-Bus Passenger UI Logic
// ==========================================

window.addEventListener('message', function (event) {
    const data = event.data;

    if (data.action === "togglePassengerInBusUI") {
        if (data.show) {
            $('#inbus-passenger-ui').fadeIn(200);
            if (data.info) {
                if (data.info.line) $('#pax-line').text(data.info.line);
                if (data.info.nextStop) $('#pax-next-stop').text(data.info.nextStop);
                if (data.info.eta) $('#pax-eta').text(data.info.eta);
            }
        } else {
            $('#inbus-passenger-ui').fadeOut(200);
        }
    } else if (data.action === "updatePassengerInBusUI") {
        if (data.info) {
            if (data.info.line) $('#pax-line').text(data.info.line);
            if (data.info.nextStop) $('#pax-next-stop').text(data.info.nextStop);
            if (data.info.eta) $('#pax-eta').text(data.info.eta);
        }
    }
});

// ==========================================
// Ads Rotation Logic
// ==========================================

let activeAds = [];
const fallbackAds = [
    { image_url: 'placeholder1.jpg' },
    { image_url: 'placeholder2.jpg' }
];
let currentAdIndex = 0;
let adRotationInterval = null;

window.addEventListener('message', function (event) {
    const data = event.data;
    if (data.action === "updateAds") {
        activeAds = data.ads || [];
        startAdRotation(data.interval);
    } else if (data.action === "updateLiveTracking") {
        if (data.buses && $('#dispatch-ui').is(':visible')) {
            renderLiveBuses(data.buses);
        }
    } else if (data.action === "updateHeatmap") {
        if (data.heatmapData && $('#dispatch-ui').is(':visible')) {
            renderHeatmap(data.heatmapData);
        }
    } else if (data.action === "playSound") {
        let audio = document.getElementById("bus-audio");
        if (!audio) return;

        let files = Array.isArray(data.file) ? data.file : [data.file];
        let currentIdx = 0;

        function playNext() {
            if (currentIdx >= files.length) return;
            audio.src = `sounds/${files[currentIdx]}.mp3`;
            audio.volume = data.volume || 1.0;
            audio.play().catch(e => console.error("Audio Play Error:", e));

            audio.onended = function () {
                currentIdx++;
                playNext();
            };
        }

        playNext();
    }
});

function startAdRotation(intervalMs) {
    if (adRotationInterval) clearInterval(adRotationInterval);

    let passAdImg = $('#passenger-ad-image');
    let inbusAdImg = $('#inbus-ad-image'); // New In-Bus Monitor

    let adsToDisplay = activeAds.length > 0 ? activeAds : fallbackAds;

    displayAd(adsToDisplay[0]);

    adRotationInterval = setInterval(() => {
        currentAdIndex++;
        if (currentAdIndex >= adsToDisplay.length) currentAdIndex = 0;
        displayAd(adsToDisplay[currentAdIndex]);
    }, intervalMs || 30000);
}

// Start fallback rotation immediately on load
startAdRotation(30000);

function displayAd(adData) {
    let passAdImg = $('#passenger-ad-image');
    let inbusAdImg = $('#inbus-ad-image');

    // Fade out
    passAdImg.addClass('hidden');
    inbusAdImg.addClass('hidden');

    setTimeout(() => {
        passAdImg.attr('src', adData.image_url);
        inbusAdImg.attr('src', adData.image_url);

        passAdImg.on('load', function () { $(this).removeClass('hidden'); });
        inbusAdImg.on('load', function () { $(this).removeClass('hidden'); });
    }, 500);
}
