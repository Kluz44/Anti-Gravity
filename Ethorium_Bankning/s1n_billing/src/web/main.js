/**
 * When true, callbacks will not be triggered. Should be used when
 * viewing in browser.
 */
const testMode = false;

/**
 * When true, will print debug messages to the console.
 */
const debugMode = true;

/**
 * uses console.log to print to the console, but only if debugMode is true.
 * @see debugMode
 * @see console.log
 * @param  {*} data the data to log
 */
function debug(...data) {
    // make sure debug mode is active
    if (!debugMode) return;

    console.log(`[WEB-DEBUG] `, ...data);
}

/**
 * Wait a given time in milliseconds.
 * @param {number} milliseconds
 * @returns
 */
const sleep = (milliseconds) => {
    return new Promise(resolve => setTimeout(resolve, milliseconds))
}

/**
 * Trigger a NUI callback on the client.
 * @param {string} type the type of this callback e.g. 'closeUI'.
 * @param {{id: *}} data the data of this callback as json object.
 * @param {function} cb the callback function, triggered, when the response got received.
 */
function triggerCallback(type, data, cb) {
    // debug
    debug(`FETCH ${type}(${JSON.stringify(data)})`);

    // make sure testMode is not active
    if (testMode) {
        cb([-1, {}]);

        return;
    }

    // fetch
    fetch(`https://${GetParentResourceName()}/${type}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(data)
    }).then(response => response.json()).then(response => cb(response));
}

/*

elements:
.categoryPage
.General
    .viewSide
.createInvoicesPage
.createContractPage
.contractPage
*/

let lang = {
    ['contract-type-vehicle']           : "CAR PURCHASE AND SALE AGREEMENT",
    ['contract-type-object']            : "ITEM PURCHASE AND SALE AGREEMENT",
    ['contract-page-subtitle']          : "BRENDEN RANDALL",
    ['contract-page-account-bank']      : "bank transfer",
    ['contract-page-account-cash']      : "cash",
    ['vehicle']                         : "car",
    ['object']                          : "object"
}

// Used to show the invoice dates in the correct format
const dateFormatOptions = {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false
}

let invoices = []

let filteredInvoices = []
let pages = 0
let currentSort = 'createdAt-desc'

let vat = 0.23
let vatMode = 1

let defaultItems = []
let jobsItems = []

let currentInvoiceID = null

// Review invoices
let reviewInvoices = false

// Contract variables
let inventoryItems = []
let nearestVehicle = null
let closestPlayer = null
let pendingContractID = null
let myPlayerName = null
let amIContractBuyer = false
let sign = false
let signStatus = 0.0

/**
 * Format a number (adds points all 3 digits).
 * @param {number} number
 * @returns {string} formatted
 */
function formatNumber(number) {
    return number.toString().replace(/(\d)(?=(\d{3})+(?!\d))/g, '$1,');
}

/**
 * Updates the pay button status based on whether the invoice is paid.
 * @param {boolean} isPaid
 * @param {number?} totalWithVat
 */
function updatePayButtonStatus(isPaid, totalWithVat) {
    const payButton = document.querySelector('.viewBoxPayButton')
    const hoverPayButtonClass = "viewBoxPayButton-hover"

    if (isPaid) {
        payButton.textContent = lang["UI_ALREADY_PAID"]

        if (payButton.classList.contains(hoverPayButtonClass)) {
            payButton.classList.remove(hoverPayButtonClass)
        }
    } else {
        payButton.textContent = `${lang["UI_PAY"]} $${totalWithVat}`

        payButton.classList.add(hoverPayButtonClass)
    }
}

/**
 * Closes the UI and tells the client to lose focus.
 */
function closeUI(keepFocus = false) {
    if (reviewInvoices) {
        reviewInvoices = false
    }

    document.querySelector('.categoryPage').style.display = "none"
    document.querySelector('.General').style.display = "none"
    document.querySelector('.createInvoicesPage').style.display = "none"
    document.querySelector(`.createContractPage`).style.display = "none"
    document.querySelector(`.contractPage`).style.display = "none"
    document.querySelector(`.inspectPage`).style.display = "none"

    triggerCallback('closeUI', { keepFocus: keepFocus }, () => {})
}

/**
 * Creates a new HTML string for an invoice.
 * @param {number} index
 * @param {table} invoice
 * @returns
 */
function createInvoiceHTML(index, invoice) {
    return `
    <div class="listBox" data-id="${invoice.id}">
        <div class="referenceId">${invoice.id}</div>
        <div class="statusBox">
            <div class="status ${invoice.payed ? 'yesstatus' : 'nostatus'}">
                ${invoice.payed ? '<i class="fa-solid fa-check"></i>' : '<i class="fa-solid fa-xmark"></i>'}
            </div>
        </div>
        <h2 class="listInText typeText">${invoice.sent ? lang["UI_SENT"] : lang["UI_RECEIVED"]}</h2>
        <h2 class="listInText authorText">${invoice.companyName ? invoice.companyName : invoice.sender}</h2>
        <h2 class="listInText creationDateText">${new Date(invoice.createdAt).toLocaleDateString(lang["JS_LOCALE_STRING"], dateFormatOptions)}</h2>
        <h2 class="listInText amountText">$${calculateTotal(invoice.amount, calculateVATAmount(invoice.amount))}</h2>
        <div class="viewButton" onclick="viewInvoice(${index}, '${invoice.id}')"><i class="fa-solid fa-eye"></i>${lang['UI_VIEW']}</div>
    </div>
    `;
}

/**
 * Calculates the VAT amount for the current VAT-Mode.
 * @param {number} amount
 * @returns {number} vat
 */
function calculateVATAmount(amount) {
    return Math.round(amount * vat);
}

/**
 * Calculates the total amount of an invoice with VAT added.
 * @param amount
 * @param vatAdded
 * @returns {number} total
 */
function calculateTotal(amount, vatAdded) {
    return amount + vatAdded;

}

/**
 * Opens an invoice by its index in the invoice array.
 * @param {number} index
 * @param {string} invoiceID
 */
function viewInvoice(index, invoiceID) {
    let invoice = invoices.find(invoice => invoice.id === invoiceID);

    if (!invoice) {
        console.error(`Invoice with ID ${invoiceID} not found`);
        return;
    }

    debug(JSON.stringify(invoice))

    currentInvoiceID = invoiceID

    document.querySelector(`.invoice-index`).textContent = `#${index + 1}`;
    document.querySelector(`.pay-invoice-reference-id`).textContent = invoice.id;
    document.querySelector(`.pay-invoice-sent-date`).textContent = new Date(invoice.createdAt).toLocaleDateString(lang["JS_LOCALE_STRING"], dateFormatOptions);
    document.querySelector(`.pay-invoice-due-date`).textContent = new Date(invoice.dueAt).toLocaleDateString(lang["JS_LOCALE_STRING"], dateFormatOptions);
    document.querySelector(`.pay-invoice-receiver-name`).textContent = invoice.receiver;
    if (invoice.companyName) {
        document.querySelector(`.pay-invoice-sender-name`).textContent = invoice.companyName;
    } else {
        document.querySelector(`.pay-invoice-sender-name`).textContent = invoice.sender;
    }
    document.querySelector(`.pay-invoice-item`).textContent = invoice.item;

    if (invoice.note) {
        document.querySelector(`.pay-invoice-note`).textContent = invoice.note;
    } else {
        document.querySelector(`.pay-invoice-note`).textContent = "";
    }

    document.querySelector(`.pay-invoice-item-amount`).textContent = `${invoice.amount}$`;
    document.querySelector(`.pay-invoice-sub-total`).textContent = `${invoice.amount}$`;

    const vatAdded = calculateVATAmount(invoice.amount)
    const totalWithVat = calculateTotal(invoice.amount, vatAdded)

    document.querySelector(`.pay-invoice-vat`).textContent = `${vatAdded}$`
    document.querySelector(`.pay-invoice-total`).textContent = `${totalWithVat}$`

    if (!vatMode) {
        document.querySelector(`.viewTotalPrices`).style.display = "none"
    }

    if (!reviewInvoices) {
        if (!invoice.sent) {
            updatePayButtonStatus(invoice.payed, totalWithVat);
        }

        document.querySelector(`.viewBoxPayButton`).style.display = invoice.sent ? "none" : "flex";
    }

    document.querySelector(`.viewSide`).style.display = "flex";
}

/**
 * Sends the 'payInvoice' command to the client, for the current open Invoice.
 */
function payInvoice() {
    if (!currentInvoiceID) {
        console.error(`No current invoice ID found`);
        return;
    }

    debug(`PAYING INVOICE: ${currentInvoiceID}`)

    triggerCallback(`payInvoice`, { id: currentInvoiceID }, (success) => {
        // Set the invoice as payed if the payment was successful
        if (!success) {
            return
        }

        const invoice = invoices.find(invoice => invoice.id === currentInvoiceID);
        if (!invoice) {
            return
        }

        invoice.payed = true;

        // Update the invoice status in the UI
        updatePayButtonStatus(true)

        const invoiceElement = document.querySelector(`.listBox[data-id="${currentInvoiceID}"]`);
        if (!invoiceElement) {
            return
        }

        const statusElement = invoiceElement.querySelector('.status');
        if (statusElement) {
            statusElement.classList.remove('nostatus');
            statusElement.classList.add('yesstatus');

            statusElement.innerHTML = '<i class="fa-solid fa-check"></i>';
        }

        // If the invoice was the last one to pay, hide the pay all button
        const invoicesToPay = invoices.filter(invoice => !invoice.payed && !invoice.sent);

        if (invoicesToPay.length === 0) {
            document.querySelector(`.payAllButton`).style.display = "none"
        }
    });
}

/**
 * This changes the numbers / arrows at the bottom of the invoice list.
 * @param {number} currentPage
 */
function setPageBoxes(currentPage) {
    let html = ``;
    let start = 0;
    let end = pages;
    let arrowLeft = false;
    let arrowRight = false;

    if (pages > 7) {
        if (currentPage > 4) {
            arrowLeft = true;
        }
        if (currentPage < pages - 3) {
            arrowRight = true;
        }

        if (currentPage < 4) {
            start = 0;
            end = 7;
        } else if (currentPage > pages - 4) {
            start = pages - 7;
            end = pages;
        } else {
            start = currentPage - 4;
            end = currentPage + 3;
        }
    }


    for (let i = start; i < end; i++) {
        html += `
        <div 
            class="pageBox${(i + 1) == currentPage ? ' selectPage' : ''}"
            page-route="${i + 1}"
            onclick="setInvoicePage(this.getAttribute('page-route'))"
        >
            ${
                (i == start) ? (
                    arrowLeft ? '<i class="fa-solid fa-chevron-left"></i>' : (i + 1)
                ) : (
                    (i == end - 1) ? (
                        arrowRight ? '<i class="fa-solid fa-chevron-right"></i>' : (i + 1)
                    ) : (i + 1)
                )
            }
        </div>`;
    }
    document.querySelector(`.pageList`).innerHTML = html
}

/**
 * click listener for the pay-all button
 */
document.querySelector(`.payAllButton`).addEventListener('click', (e) => {
    triggerCallback(`payAllInvoices`, {}, (success)=>{
        if (!success) {
            return
        }

        const invoicesToPay = invoices.filter(invoice => !invoice.payed && !invoice.sent)

        invoicesToPay.forEach(invoice => {
            invoice.payed = true

            // TODO: DRY : Repeated code with payInvoice
            const invoiceElement = document.querySelector(`.listBox[data-id="${invoice.id}"]`);
            if (!invoiceElement) {
                return
            }

            const statusElement = invoiceElement.querySelector('.status');
            if (statusElement) {
                statusElement.classList.remove('nostatus')
                statusElement.classList.add('yesstatus')

                statusElement.innerHTML = '<i class="fa-solid fa-check"></i>'
            }
        })

        document.querySelector(`.payAllButton`).style.display = "none"

        setInvoicePage(1)
    })
})

/**
 * Click listener for the Lookup Citizen Invoices button.
 */
document.getElementById("button-review-invoices-lookup").addEventListener("click", () => {
    const targetName = document.getElementById("input-review-invoices-full-name").value

    triggerCallback(`lookupCitizenInvoices`, { targetName: targetName }, (data)=>{
        if (!data) {
            return
        }

        setInvoices(data.invoices)
        reviewInvoices = true

        document.getElementById("invoices-page-type").textContent = lang["UI_CITIZEN_INVOICES"].replace("%s", targetName)

        document.querySelector(`.inspectPage`).style.display = "none"
        document.querySelector(`.General`).style.display = "flex"
    })
})

// Listen when the user select an option on the select with id="contract-select"
document.getElementById("contract-select").addEventListener("change", function(event) {
    const contractType = event.target.value

    if (contractType === "inventory-item") {
        // Show a new selector with the items as options

        document.getElementById("contract-item-box").style.display = "flex"

    } else if (contractType === "vehicle") {
        document.getElementById("contract-item-box").style.display = "none"

    }
})

// Listen when the user select an option on the select with id="contract-item-select"
document.getElementById("contract-item-select").addEventListener("change", function(event) {
    const item = Object.values(inventoryItems).find(item => item.name === event.target.value)

    if (!item) {
        debug(`Item ${event.target.value} not found`)
        return
    }

    if (item.amount > 1) {
        document.getElementById("contract-item-amount").style.display = "flex"
    } else {
        if (document.getElementById("contract-item-amount").style.display !== "none") {
            document.getElementById("contract-item-amount").style.display = "none"
        }
    }

})

/**
 * Sets the current invoices.
 * @param {Array<{ id: string, payed: boolean, sent: boolean, sender: string, date: string, amount: number}>} inv invoices
 */
function setInvoices(inv) {
    invoices = inv
    pages = inv.length / 7

    setInvoicePage(1)

    if (!reviewInvoices) {
        // Verify if there are invoices to pay
        let invoicesToPay = inv.filter(invoice => !invoice.payed && !invoice.sent)
        let payAllButton = document.querySelector(`.payAllButton`);

        // No need to show the pay all button if there are no invoices to pay
        if (invoicesToPay.length === 0) {
            payAllButton.style.display = "none"

            return
        }

        let totalToPay = 0

        invoicesToPay.forEach(invoice => {
            totalToPay += invoice.amount
        })

        let totalWithVat = totalToPay + calculateVATAmount(totalToPay)

        payAllButton.textContent = lang["UI_PAY_ALL"].replace("%s", formatNumber(totalWithVat))
        payAllButton.style.display = "flex"
    }
}

// Listen for input changes in the search field
document.getElementById("search-reference-id").addEventListener("input", function(event) {
    const searchValue = event.target.value.trim();
    filterInvoicesById(searchValue);
});

// Listen for changes in the sort selector
document.getElementById("filters").addEventListener("change", function(event) {
    currentSort = event.target.value;
    setInvoicePage(1);
});

/**
 * Filters the invoices by reference ID and displays the results.
 * @param {string} referenceId
 */
function filterInvoicesById(referenceId) {
    filteredInvoices = invoices.filter(invoice => invoice.id.includes(referenceId));

    if (filteredInvoices.length === 0) {
        pages = 0;

        document.querySelector(`.my-invoices-list`).innerHTML = ""
    } else {
        pages = Math.ceil(filteredInvoices.length / 7);
        setInvoicePage(1);
    }

    setPageBoxes(1);
}

/**
 * Sorts the invoices based on the currentSort criteria.
 * @param {Array} inv
 */
function sortInvoices(inv) {
    const [key, order] = currentSort.split('-');

    inv.sort((a, b) => {
        if (order === 'asc') {
            return new Date(a[key]) - new Date(b[key]);
        } else {
            return new Date(b[key]) - new Date(a[key]);
        }
    });
}

/**
 * Changes the current invoice page.
 * @param {number} page
 */
function setInvoicePage(page) {
    page = parseInt(page);

    let html = ``;
    let currentInvoices = filteredInvoices.length ? filteredInvoices : invoices;
    sortInvoices(currentInvoices);

    debug(`Current Invoices: ${currentInvoices.length}`)

    let start = 7 * (page - 1);
    let end = Math.min(7 * page, currentInvoices.length);

    for (let index = start; index < end; index++) {
        html += createInvoiceHTML(index, currentInvoices[index]);
    }

    document.querySelector(`.my-invoices-list`).innerHTML = html;

    setPageBoxes(page);
}

/**
 * Changes the color of the Job / Personal buttons in the create Invoice menu.
 * @param {'job'|'personal'} target
 */
function setInvoiceTarget(target) {
    let jobElement = document.getElementById("button-invoice-set-as-job")
    let personalElement = document.getElementById("button-invoice-set-as-citizen")

    if (target === 'job') {
        setInvoiceItems(jobsItems);

        jobElement.setAttribute("selected", null);
        personalElement.removeAttribute("selected");
    } else {
        setInvoiceItems(defaultItems);

        jobElement.removeAttribute("selected");
        personalElement.setAttribute("selected", null);
    }
}
// Listen for click events on the job / personal buttons
document.querySelectorAll('.createButtons').forEach(element => {
    element.addEventListener('click', (e) => {
        setInvoiceTarget(element.getAttribute('data-type'));
    });
});


/**
 * Sets the items for the create invoice menu.
 * @param items
 */
function setInvoiceItems(items) {
    let html = ``;

    // Default option
    html += `<option value="default" disabled selected>Choose an item...</option>`;

    items.forEach(item => {
        html += `<option value="${item.name}">${item.name}</option>`;
    });

    document.getElementById('create-invoice-items').innerHTML = html;
}

/**
 * Creates a new Invoice, with the values from the Invoice menu.
 */
function createInvoice() {
    let isJob = document.getElementById("button-invoice-set-as-job").hasAttribute("selected")
    let item = document.getElementById('create-invoice-items').value
    let amount = parseInt(document.getElementById('amount').value)
    let note = document.getElementById('note').value
    let date = document.getElementById('date').value

    triggerCallback('createInvoice', {
        isJob: isJob,
        item: item,
        amount: amount,
        note: note,
        date: date
    }, (success) => {
        if (!success) {
            return
        }

        closeUI()
    })
}


function setContractDetails(data) {
    clearSignatures()

    pendingContractID = data.contractID

    document.querySelector(`.contractPage span[name="sellerName"]`).textContent = data.sellerName
    document.querySelector(`.contractPage span[name="buyerName"]`).textContent = data.closestPlayer.frameworkName

    if (data.contractType === "vehicle") {
        document.querySelector(`.contractPage span[name="contractItemDetails"]`).textContent = `a ${data.vehicle.modelName} with license plate number ${data.vehicle.plate}.`
    } else if (data.contractType === "inventory-item") {
        document.querySelector(`.contractPage span[name="contractItemDetails"]`).textContent = `a quantity of ${data.inventoryItem.quantity}x ${data.inventoryItem.name}.`
    }

    document.querySelector(`.contractPage span[name="date"]`).textContent = new Date(Date.now()).toLocaleDateString(lang["JS_LOCALE_STRING"], dateFormatOptions)
    document.querySelector(`.contractPage span[name="contract-amount"]`).textContent = data.contractAmount;

    document.querySelectorAll(`.contractPage span[name="contractItem"]`).forEach(elem => {
        if (data.contractType === "vehicle") {
            document.querySelector(`.contractPage span[name="contractItem"]`).textContent = lang["UI_ITEM_VEHICLE"]
        } else if (data.contractType === "inventory-item") {
            document.querySelector(`.contractPage span[name="contractItem"]`).textContent = lang["UI_ITEM_INVENTORY"]

        }
    });
}

/**
 * Reset the contract variables.
 */
function resetContractVariables() {
    amIContractBuyer = false
    sign = false
    signStatus = 0.0
}

/**
 * Creates a new contract, with the values from the CreateInvoice menu.
 */
function createContract() {
    const contractAmount = parseInt(document.querySelector(`.createContractPage input[name="input-contract-amount"]`).value) || 0
    const contractItem = document.getElementById("contract-select").value
    const itemName = document.getElementById("contract-item-select").value
    const itemQuantity = parseInt(document.getElementById("contract-item-amount-input").value) || 1

    triggerCallback(`createContract`, {
        contractAmount: contractAmount,
        closestPlayer: closestPlayer,
        nearestVehicle: nearestVehicle,
        item: contractItem,
        inventoryItem: {
            name: itemName,
            quantity: itemQuantity
        }
    },
    /**
     *
     * @param {{ contractType: 'vehicle'|'object', seller: string, buyer: string, object: string, date: string, amount: string, account: 'bank'|'cash' }} data
     */
    (data) => {
        if (!data) {
            return
        }

        resetContractVariables()

        myPlayerName = data.sellerName
        setContractDetails(data)

        document.querySelector(`.createContractPage`).style.display = "none"
        document.querySelector(`.contractPage`).style.display = "flex"
    });
}

/**
 * Loads & opens a given category.
 * @param {'manage-invoices'|'manage-company-invoices'|create-invoice'|'create-contract'|'review-invoices'} category
 */
function view(category) {
    triggerCallback(`load-${category}`, {}, (data) => {
        switch(category) {
            case "manage-invoices": {
                setInvoices(data.invoices)

                document.getElementById("invoices-page-type").textContent = lang["UI_MY_INVOICES"]

                document.querySelector(`.categoryPage`).style.display = "none"
                document.querySelector(`.General`).style.display = "flex"
                break
            }

            case "manage-company-invoices": {
                setInvoices(data.invoices)

                document.getElementById("invoices-page-type").textContent = lang["UI_COMPANY_INVOICES"]

                document.querySelector(`.categoryPage`).style.display = "none"
                document.querySelector(`.General`).style.display = "flex"
                break
            }

            case "create-invoice": {
                // Add default items to the create invoice menu
                defaultItems = data.defaultItems
                jobsItems = data.jobsItems

                // Set the invoice as personal by default
                setInvoiceTarget("personal")

                document.querySelector(`.categoryPage`).style.display = "none"
                document.querySelector(`.createInvoicesPage`).style.display = "flex"
                break;
            }
            case "review-invoices": {
                document.querySelector(`.categoryPage`).style.display = "none"
                document.querySelector(`.inspectPage`).style.display = "flex"

                break
            }
            case "create-contract": {
                if (!data) {
                    return
                }

                // clear input fields
                document.querySelector(`.createContractPage input[name="input-contract-amount"]`).value = ""
                document.querySelector(`.createContractPage select[name="item"]`).value = ""
                document.querySelector(`.createContractPage input[name="amount"]`).value = ""

                // Hide the item selector by default
                document.getElementById("contract-item-box").style.display = "none"
                // Hide the amount input by default
                document.getElementById("contract-item-amount").style.display = "none"

                // set the default values
                inventoryItems = data.inventoryItems
                nearestVehicle = data.nearestVehicle
                closestPlayer = data.closestPlayer

                // Add the items to the select
                const options = Object.values(inventoryItems).map(item => {
                    return `<option value="${item.name}">${item.label} (x${item.amount})</option>`
                }).join('')

                document.getElementById("contract-item-select").innerHTML = `
                    <option value="" disabled selected hidden content="UI_SELECT_ITEM_INVENTORY"></option>
                    ${options}
                `

                // open the UI
                document.querySelector(`.categoryPage`).style.display = "none"
                document.querySelector(`.createContractPage`).style.display = "flex"

                break
            }
        }
    })
}

/**
 * Starts signing the contract as the given party.
 * @param {string} name
 * @param {'seller'|'buyer'} party
 * @param {boolean} isUserInteraction
 */
async function startSigning(name, party, isUserInteraction = true) {
    sign = true;

    if (!isUserInteraction) {
        signStatus = 0.0;
    }

    debug(`START SIGNING: ${name} as ${party}`);

    if (signStatus > 0.0) {
        debug("Already signing");
        return;
    }

    document.querySelector(`.${party}-signature`).textContent = name;

    signStatus += 0.1;

    while (signStatus > 0.0 && signStatus < 1.0) {
        if (sign) signStatus += 0.1;
        else signStatus -= 0.1;

        if (signStatus > 1.0) signStatus = 1.0;

        document.querySelector(`.${party}-signature`).style.clipPath = `polygon(0 0, ${signStatus * 100}% 0, ${signStatus * 100}% 100%, 0 100%)`;

        await sleep(100);
    }
    if (signStatus >= 1.0 && isUserInteraction) {
        triggerCallback(`contractSigned`, { contractID: pendingContractID }, ()=>{});
    }
    if (!isUserInteraction) {
        signStatus = 0.0;
    }
}

function clearSignatures() {
    document.querySelector(`.buyer-signature`).textContent = "";
    document.querySelector(`.seller-signature`).textContent = "";
    document.querySelector(`.buyer-signature`).style.clipPath = `polygon(0 0, 0 0, 0 100%, 0 100%)`;
    document.querySelector(`.seller-signature`).style.clipPath = `polygon(0 0, 0 0, 0 100%, 0 100%)`;
}

/**
 * Stops signing the contract as the given party.
 */
function stopSigning() {
    sign = false;
}

document.querySelector(`.signButton`).addEventListener('mousedown', (e) => {
    let party

    if (amIContractBuyer) {
        party = 'buyer'
    } else {
        party = 'seller'
    }

    startSigning(myPlayerName, party);
});

/*document.querySelector(`.signButton`).addEventListener('mouseup', (e) => {
    stopSigning();
});*/

/**
 * Sets the translations and applies them.
 * @param {json} translations
 * @param {json} dynamicValues
 */
function translate(translations, dynamicValues = {}) {
    lang = translations;

    document.body.querySelectorAll(`[content]`).forEach(element => {
        let contentName = element.getAttribute("content");

        if (!translations.hasOwnProperty(contentName)) {
            console.error(`Translation not found for ${contentName}`);
            return;
        }

        let translation = translations[contentName];

        // Check if the translation string contains placeholders for dynamic values
        if (dynamicValues.hasOwnProperty(contentName)) {
            // Replace the placeholder with the actual dynamic value
            translation = translation.replace('%s', dynamicValues[contentName]);
        }

        element.textContent = translation;
    });
    document.body.querySelectorAll(`[placeholder-content]`).forEach(element => {
        let contentName = element.getAttribute("placeholder-content");

        if (!translations.hasOwnProperty(contentName)) {
            console.error(`Translation not found for ${contentName}`);
            return;
        }

        let translation = translations[contentName];

        // Check for dynamic placeholders in the placeholder translations
        if (dynamicValues.hasOwnProperty(contentName)) {
            // Replace the placeholder with the actual dynamic value
            translation = translation.replace('%s', dynamicValues[contentName]);
        }

        element.placeholder = translation;
    });
}

/**
 * Event listeners for client->UI communication.
 */
addEventListener('message', (event) => {
    let message = event.data;
    let data = message.data;

    debug(`RECEIVED MESSAGE EVENT: ${JSON.stringify(message)}`);

    switch(message.action) {
        case "init": {
            debug(`INIT: ${JSON.stringify(data)}`);

            vatMode = data.features.vat.enabled
            vat = data.features.vat.rate

            translate(data.translations, data.dynamicValues)

            triggerCallback("receivedInit", {}, () => {})
            break
        }

        case "openUI": {
            debug(`OPEN UI: ${JSON.stringify(data)}`)

            document.querySelector('[category-box="review-invoices"]').style.display = `${data.allowReviewSomeoneInvoices ? "flex" : "none"}`
            document.querySelector('[category-box="manage-company-invoices"]').style.display = `${data.allowManageCompanyInvoices ? "flex" : "none"}`
            document.querySelector('.categoryPage').style.display = "flex"

            break
        }

        case "closeUI": {
            closeUI(data.keepFocus)

            break
        }

        case "openContractUI": {
            debug(`OPEN CONTRACT UI: ${JSON.stringify(data)}`)

            // In case the player already have the UI open, close it
            closeUI(true)
            resetContractVariables()

            amIContractBuyer = true
            myPlayerName = data.closestPlayer.frameworkName

            setContractDetails(data)

            document.querySelector(`.contractPage`).style.display = "flex"

            break
        }

        case "contractSignedByTarget": {
            debug(`CONTRACT SIGNED BY TARGET: ${JSON.stringify(data)}`)

            startSigning(data.name, data.party, false)
                .catch((e) => {
                    console.error(e)
                })

            break
        }
    }
});
