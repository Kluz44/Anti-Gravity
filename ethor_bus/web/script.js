// ==========================================
// Boss Dispatch NUI Logic
// ==========================================

let mapZoom = 1.0;
let stopsData = [];
let linesData = [];

window.addEventListener('message', function (event) {
    const data = event.data;

    if (data.action === "openDispatch") {
        document.body.style.display = "block";
        $("#dispatch-ui").fadeIn(300);

        // Populate initially
        if (data.stops) {
            stopsData = data.stops;
            renderStops();
            renderMapMarkers();
        }
        if (data.lines) {
            linesData = data.lines;
            renderLines();
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
        document.body.style.display = "none";
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
    if (mapZoom > 0.5) {
        mapZoom -= 0.2;
        applyZoom();
    }
});

function applyZoom() {
    $('#gta-map').css('transform', `scale(${mapZoom})`);
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
                    <p>Haltestellen: ${line.stops.length}</p>
                </div>
                <button class="btn-primary" style="background:var(--bg-main); border:1px solid var(--border);">Route zeigen</button>
            </li>
        `);
    });
}

// Coordinate mapping (GTA coords to map div percentage mapping)
// This is an extremely rough estimation for typical map backgrounds
function mapGtaToPixels(x, y) {
    // Assuming Map bounds: X: -4000 to 4000, Y: -4000 to 8000
    // And percentage mapping 0-100%
    const percentX = ((x + 4000) / 8000) * 100;
    const percentY = 100 - (((y + 4000) / 12000) * 100);
    return { px: percentX, py: percentY };
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
    }
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
            $('#door-front').addClass('open').html('<i class="fa-solid fa-door-open"></i> Tür 1 (Offen)');
        } else {
            $('#door-front').removeClass('open').html('<i class="fa-solid fa-door-closed"></i> Tür 1 (Geschlossen)');
        }
    }

    if (info.doorRear !== undefined) {
        if (info.doorRear) {
            $('#door-rear').addClass('open').html('<i class="fa-solid fa-door-open"></i> Tür 2 (Offen)');
        } else {
            $('#door-rear').removeClass('open').html('<i class="fa-solid fa-door-closed"></i> Tür 2 (Geschlossen)');
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
