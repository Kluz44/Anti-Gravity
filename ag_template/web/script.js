const app = document.getElementById('app');
const titleEl = document.getElementById('title');
const messageEl = document.getElementById('message');

window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.action === 'open') {
        app.style.display = 'flex';
        if (data.data) {
            titleEl.textContent = data.data.title || 'Default Title';
            messageEl.textContent = data.data.message || 'Default Message';
        }
    } else if (data.action === 'close') {
        app.style.display = 'none';
    }
});

document.getElementById('close-btn').addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    }).then(() => {
        app.style.display = 'none';
    });
});

document.getElementById('action-btn').addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/action`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({ type: 'basic_action' })
    });
});

// Escape key to close
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST',
            header: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).then(() => {
            app.style.display = 'none';
        }); 
    }
});
