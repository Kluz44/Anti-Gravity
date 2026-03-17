let currentAction = null;
let currentIban = "LS12-ETH-00000000";

window.addEventListener('message', function(event) {
    let data = event.data;

    if(data.action === "openBanking") {
        document.getElementById("app").style.display = "flex";
        document.getElementById("dashboard-view").style.display = "flex";
        document.getElementById("creator-view").style.display = "none";
        
        if (data.iban) {
            currentIban = data.iban;
            document.getElementById("iban-display").innerText = currentIban;
        }
        if (data.balance !== undefined) {
            document.getElementById("total-balance").innerText = "$" + data.balance.toLocaleString();
        }
        
        switchTab(data.tab || "overview");
    }

    if(data.action === "openCreator") {
        document.getElementById("app").style.display = "flex";
        document.getElementById("creator-view").style.display = "flex";
        document.getElementById("dashboard-view").style.display = "none";
    }

    // Handled in client LUA but we expect some data updates optionally
    if(data.action === "updateTransactions") {
        updateTransactionList(data.transactions);
    }

    // Dialogue UI Actions (rep-talkNPC clone)
    if(data.action === "show" || data.action === "changeDialog") {
        document.getElementById("app").style.display = "flex";
        document.getElementById("dashboard-view").style.display = "none";
        document.getElementById("creator-view").style.display = "none";
        document.getElementById("dialog-view").style.display = "flex";
        document.getElementById("modal-overlay").style.display = "none";

        if(data.npcName) document.getElementById("npc-name").innerText = data.npcName;
        if(data.npcTag) document.getElementById("npc-tag").innerText = data.npcTag;
        
        document.getElementById("dialog-message").innerHTML = data.msg.replace(/\n/g, '<br>');
        
        const optionsContainer = document.getElementById("dialog-options");
        optionsContainer.innerHTML = "";
        data.elements.forEach((el, index) => {
            let btn = document.createElement("div");
            btn.className = "dialog-option";
            btn.innerText = el.label;
            btn.onclick = () => {
                fetch(`https://${GetParentResourceName()}/click`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(index)
                });
            };
            optionsContainer.appendChild(btn);
        });
    }

    if(data.action === "updateMessage") {
        document.getElementById("dialog-message").innerHTML = data.msg.replace(/\n/g, '<br>');
    }

    if(data.action === "closeDialog" || data.action === "close") {
        document.getElementById("app").style.display = "none";
        document.getElementById("dialog-view").style.display = "none";
    }
});

// Detect Escape Key
document.onkeyup = function (data) {
    if (data.which == 27) {
        closeUI();
    }
};

function closeUI() {
    document.getElementById("app").style.display = "none";
    document.getElementById("dialog-view").style.display = "none";
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST', body: JSON.stringify({})
    });
    fetch(`https://${GetParentResourceName()}/closeCreator`, {
        method: 'POST', body: JSON.stringify({})
    });
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST', body: JSON.stringify({})
    });
}

function switchTab(tabId) {
    // Update nav classes
    document.querySelectorAll("nav a").forEach(link => {
        if(link.dataset.tab === tabId) link.classList.add("active");
        else link.classList.remove("active");
    });
    // In a real SPA we would hide/show sections, here we just alert or call
    console.log("Switched to tab:", tabId);
    // You'd toggle display of #tab-overview vs others here.
}

function copyIban() {
    navigator.clipboard.writeText(currentIban);
    // Simple visual feedback could be added here
}

function updateTransactionList(txs) {
    const list = document.querySelector(".transaction-list");
    list.innerHTML = "";
    
    if(!txs || txs.length === 0) {
        list.innerHTML = `<div class="empty-state">No recent transactions.</div>`;
        return;
    }

    txs.forEach(tx => {
        const isDep = tx.type === 'deposit';
        const sign = isDep ? "+" : "-";
        const cL = isDep ? "positive" : "negative";
        const icon = isDep ? "fa-arrow-down" : "fa-arrow-up";

        list.innerHTML += `
            <div class="transaction-item">
                <div class="tx-left">
                    <div class="tx-icon ${isDep ? 'deposit' : 'withdraw'}">
                        <i class="fas ${icon}"></i>
                    </div>
                    <div class="tx-details">
                        <h4>${tx.description}</h4>
                        <p>${new Date(tx.created_at).toLocaleString()}</p>
                    </div>
                </div>
                <div class="tx-amount ${cL}">
                    ${sign}$${tx.amount.toLocaleString()}
                </div>
            </div>
        `;
    });
}

// Modal Actions
function openDeposit() {
    currentAction = "deposit";
    document.getElementById("modal-overlay").style.display = "flex";
    document.getElementById("modal-title").innerText = "Deposit Funds";
    document.getElementById("modal-amount").value = "";
    document.getElementById("modal-amount").focus();
}

function openWithdraw() {
    currentAction = "withdraw";
    document.getElementById("modal-overlay").style.display = "flex";
    document.getElementById("modal-title").innerText = "Withdraw Funds";
    document.getElementById("modal-amount").value = "";
    document.getElementById("modal-amount").focus();
}

function closeModal() {
    document.getElementById("modal-overlay").style.display = "none";
    currentAction = null;
}

document.getElementById("modal-confirm").addEventListener("click", () => {
    let amt = parseInt(document.getElementById("modal-amount").value);
    if(isNaN(amt) || amt <= 0) return;

    fetch(`https://${GetParentResourceName()}/bankAction`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            action: currentAction,
            amount: amt
        })
    }).then(resp => resp.json()).then(resp => {
        if(resp === 'ok' || resp.success) {
            closeModal();
            // Could trigger a UI refresh request here
        }
    });
});

// Creator UI Actions
function submitCreator() {
    const name = document.getElementById("creator-name").value;
    const type = document.getElementById("creator-type").value;
    const vault = document.getElementById("creator-vault").value;

    if(!name || name.trim() === "") return;

    fetch(`https://${GetParentResourceName()}/createBank`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            name: name,
            type: type,
            vaultBalance: parseInt(vault) || 0
        })
    }).then(() => {
        closeUI();
    });
}
