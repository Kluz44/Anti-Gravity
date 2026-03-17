
var CURRENT_ATM_MODEL = null;
var ACTUAL_DATA = null;

function createBtn(name, index) {
    const btn = $('<div>');
    btn.addClass(CURRENT_ATM_MODEL)
        .addClass('panel-btn')
        .addClass(`btn-${index}`);
    btn.html(name);
    return btn;
}

function createPage(_title, _subtitle, _description, _buttons, _input) {
    $('#page').empty();
    const title = $('<div class="title">');
    const subtitle = $('<div class="selectedOptionTitle">');
    const description = $('<p class="description">');
   
    title.text(_title);
    subtitle.text(_subtitle);
    description.html(_description);

    for (let i = 0; i < _buttons.length; i++) {
        const btn = createBtn(_buttons[i].text, _buttons[i].index);
        $('#page').append(btn);
    }

    $('#page').append(subtitle)
        .append(title)
        .append(description);
    if (_input) {
        const input = $(_input);
        $('#page').append(input);
    }
}

window.addEventListener('message', function (event) {
    const data = event.data;
    switch (data.action) {
        case "createPage":
            createPage(data.title, data.subtitle, data.description, data.buttons, data.input);
            break;
        case "getDuiState":
            $.post(`https://Ethorium_Banking/duiIsReady`, JSON.stringify({ ok: true }))
            break;
        case "openATM":
            if (data.show) {
                $('body').show();
                CURRENT_ATM_MODEL = data.modelName;
                $('.atm-panel').addClass(CURRENT_ATM_MODEL);
                ACTUAL_DATA = data;
                if (data.modelName === 'prop_fleeca_atm') {
                    $('body').css({
                        'width': '1533px',
                        'height': '1117px',
                        'background-image': 'url("./atm2.webp")',
                        'background-repeat': 'no-repeat',
                    });
                    $('.atm-panel').css({
                        bottom: '40px',
                        left: '15px'
                    })
                } else {
                    $('body').css({
                        'width': '742px',
                        'height': '512px',
                        'background-image': 'none',
                    });
                    $('.atm-panel').css({
                        bottom: '0',
                        left: '0'
                    })
                }

                if (data.waterMarkLink) {
                    $('.watermark').attr('src', data.waterMarkLink);
                } else {
                    $('.watermark').hide();
                }

                if (data.colorHash) {
                    $('.atm-panel').css('background-color', data.colorHash);
                }

                if (data.btnColorHash) {
                    $('.panel-btn').css('background-color', data.btnColorHash);
                }
            } else {
                $('body').hide();
                CURRENT_ATM_MODEL = null;
                ACTUAL_DATA = null;
                $('.atm-panel').removeClass().addClass('atm-panel');
                $('.panel-btn').removeAttr('style');
            }
            break;
        case "updateInput":
            const inputElement = $(".inputField");
            inputElement.text(data.value);
            break;
        case "playSound":
            const audio = new Audio(data.audioFile);
            audio.volume = data.volume || 0.5;
            audio.play();
            break;
        default:
            break;
    }
});
