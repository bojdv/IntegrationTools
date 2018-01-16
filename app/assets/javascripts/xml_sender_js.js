/**
 * Created by PekAV on 21.12.2017.
 */
/**
 function changeText(name, host, port, user, password)
 {
     document.getElementById('mq_attributes_queue').value = name;
     document.getElementById('mq_attributes_host').value = host;
     document.getElementById('mq_attributes_port').value = port;
     document.getElementById('mq_attributes_user').value = user;
     document.getElementById('mq_attributes_password').value = password;
 }
 */
/** $(document).ready(function() { */
function send_alert(message) {
    alert(message);
}

function SaveXml() {
    text = [document.getElementById("xml_text_field").value]
    xml_name = document.getElementById("xml_xml_name").value
    file_name = xml_name ? xml_name + '.xml' : 'Xml.xml'
    var file = new File(text, file_name, {type: "text/plain;charset=utf-8"});
    saveAs(file);
}

function open_modal(text, time) {
    $('#modal-close-button2').hide();
    $('#modal-close-button').show();
    $('#modal-text').html(text);
    $('#modal-close-button').html('Отменить (' + time / 1000 + ')');
    timerId = setInterval(function () {
        time = time - 1000;
        $('#modal-close-button').html('Отменить (' + time / 1000 + ')');
    }, 1000);
    $('#messageModal').modal({
        keyboard: true,
    })
    modalTimer = setTimeout(function () {
        $('#messageModal').modal('hide');
    }, time);
    $('#messageModal').on('hide.bs.modal hidden.bs.modal', function () {
        clearTimeout(timerId);
    })
}

function get_manager_form_data() {
    form_settings_name = document.getElementById("mq_attributes_settings_name").value;
    form_host = document.getElementById("mq_attributes_host").value;
    form_port = document.getElementById("mq_attributes_port").value;
    form_login = document.getElementById("mq_attributes_user").value;
    form_password = document.getElementById("mq_attributes_password").value;
    form_output_queue = document.getElementById("mq_attributes_queue").value;
    form_manager_type = document.getElementById("mq_attributes_manager_type").value;
    form_amq_protocol = document.getElementById("mq_attributes_protocol").value;
    form_channel_manager = document.getElementById("mq_attributes_channel_manager").value;
    form_channel = document.getElementById("mq_attributes_channel").value;
    form_autorization = document.getElementById("mq_attributes_autorization").checked;
    form_visible_all = document.getElementById("mq_attributes_visible_all").checked;
    return {
        form_settings_name: form_settings_name,
        form_host: form_host,
        form_port: form_port,
        form_login: form_login,
        form_password: form_password,
        form_output_queue: form_output_queue,
        form_manager_type: form_manager_type,
        form_amq_protocol: form_amq_protocol,
        form_channel_manager: form_channel_manager,
        form_channel: form_channel,
        form_autorization: form_autorization,
        form_visible_all: form_visible_all
    };
}

function get_form_data() {
    form_xml = document.getElementById("xml_text_field").value;
    form_product = document.getElementById("xml_product_name").value;
    form_category = document.getElementById("xml_select_category_name").value;
    form_category_user = document.getElementById("xml_category_name").value;
    form_xml_name = document.getElementById("xml_xml_name").value;
    form_xml_description = document.getElementById("xml_xml_description").value;
    form_xml_private = document.getElementById("xml_private_xml").checked;
    form_xml_selected_name = document.getElementById("xml_select_xml_name").value;
    return {
        form_xml: form_xml,
        form_product: form_product,
        form_category: form_category,
        form_category_user: form_category_user,
        form_xml_name: form_xml_name,
        form_xml_description: form_xml_description,
        form_xml_private: form_xml_private,
        form_xml_selected_name: form_xml_selected_name
    };
}

function addElement(text) {
    $('#list').html(text);
}

function Base64(coding_mode) {
    textarea = document.getElementById("xml_text_field");
    selection = (textarea.value).substring(textarea.selectionStart, textarea.selectionEnd);
    if (coding_mode == "encode") {
        selectionEncode = window.btoa(unescape(encodeURIComponent(selection)));
    }
    else if (coding_mode == "decode") {
        selectionEncode = decodeURIComponent(escape(window.atob(selection)));
    }
    else if (coding_mode == "uuid") {
        function s4() {
            return Math.floor((1 + Math.random()) * 0x10000)
                .toString(16)
                .substring(1);
        }

        selectionEncode = s4() + s4() + '-' + s4() + '-' + s4() + '-' + s4() + '-' + s4() + s4() + s4();
    }
    new_text = textarea.value.replace(selection, selectionEncode);
    textarea.value = new_text;
}

function getSelectedId() {
    textarea = document.getElementById("xml_text_field");
    selection = (textarea.value).substring(textarea.selectionStart, textarea.selectionEnd);
    $.ajax({
        url: "/xml_sender/changeId",
        type: "POST",
        data: {changeXml: {tag: selection, xml: textarea.value}},
    });
}

function updateDiv() {
    $("#list").load(window.location.href + " #list");
}

/** Контекстное меню xml*/
$(function () {
    $.contextMenu({
        selector: '.context-menu-one',
        callback: function (key, options) {
            form_elements = get_form_data();
            request = {
                form_elements: {
                    xml_text: form_elements.form_xml,
                    category_id: form_elements.form_category,
                    form_product: form_elements.form_product,
                    xml_name: form_elements.form_xml_name,
                    xml_description: form_xml_description,
                    private: form_xml_private,
                    id: form_elements.form_xml_selected_name
                }
            }
            if (key == 'new') {
                $.ajax({
                    url: "xml_sender/create_xml",
                    type: "POST",
                    dataType: "script",
                    data: request
                });
            }
            if (key == 'delete') {
                $.ajax({
                    url: "xml_sender/delete_xml",
                    type: "POST",
                    dataType: "script",
                    data: request
                });
            }
            if (key == 'save') {
                $.ajax({
                    url: "xml_sender/save_xml",
                    type: "POST",
                    dataType: "script",
                    data: request
                });
            }

        },
        items: {
            "save": {name: "Сохранить изменения", icon: "edit"},
            "new": {name: "Сохранить,как новую", icon: "edit"},
            "delete": {name: "Удалить", icon: "delete"},
        }
    });
});
/** Контекстное меню категории*/
$(function () {
    $.contextMenu({
        selector: '.context-menu-category',
        callback: function (key, options) {
            form_elements = get_form_data();
            if (key == 'new') {
                $.ajax({
                    url: "xml_sender/create_category",
                    type: "POST",
                    dataType: "script",
                    data: {
                        form_elements: {
                            category_name: form_elements.form_category_user,
                            product_id: form_elements.form_product,
                        }
                    },
                });
            }
            if (key == 'delete') {
                $.ajax({
                    url: "xml_sender/delete_category",
                    type: "POST",
                    dataType: "script",
                    data: {
                        form_elements: {
                            id: form_elements.form_category
                        }
                    },
                });
            }

        },
        items: {
            "new": {name: "Добавить категорию", icon: "edit"},
            "delete": {name: "Удалить категорию", icon: "delete"},
        }
    });
});
/** Контекстное меню менеджера очередей*/
$(function () {
    $.contextMenu({
        selector: '.context-menu-manager-settings',
        callback: function (key, options) {
            form_elements = get_manager_form_data();
            $.ajax({
                url: "xml_sender/crud_mq_settings",
                type: "POST",
                dataType: "script",
                data: {
                    form_elements: {
                        manager_name: form_elements.form_settings_name,
                        queue_out: form_elements.form_output_queue,
                        host: form_elements.form_host,
                        port: form_elements.form_port,
                        user: form_elements.form_login,
                        password: form_elements.form_password,
                        manager_type: form_elements.form_manager_type,
                        amq_protocol: form_elements.form_amq_protocol,
                        channel_manager: form_elements.form_channel_manager,
                        channel: form_elements.form_channel,
                        autorization: form_elements.form_autorization,
                        visible_all: form_elements.form_visible_all,
                        mode: key
                    },
                },
            });
        },
        items: {
            "new": {name: "Создать новую"},
            "edit": {name: "Отредактировать"},
            "delete": {name: "Удалить", icon: "delete"},
        }
    });
});
/** Контекстное меню редактирования XML*/
$(function () {
    $.contextMenu({
        selector: '.context-menu-xml',
        callback: function (key, options) {
            if (key == 'decode' || key == 'encode' || key == 'uuid') {
                Base64(key)
            }
            if (key == 'clear') {
                $('#xml_text_field').val('');
            }
            if (key == 'save_xml') {
                SaveXml();
            }
            if (key == 'validate') {
                validate_xml(mode = 'validate')
            }
            if (key == 'validate_xsd') {
                xsd_upload()
            }
            if (key == 'prefix') {
                prefixModal()
            }
            if (key == 'pretty') {
                validate_xml(mode = 'pretty')
            }
        },
        items: {
            "pretty": {name: "Выровнить XML"},
            "decode": {name: "Декодировать Base64"},
            "encode": {name: "Кодировать в Base64"},
            "uuid": {name: "Сгенерировать ID"},
            "prefix": {name: "Добавить префикс"},
            "validate": {name: "Валидировать XML"},
            "validate_xsd": {name: "Валидировать по XSD"},
            "save_xml": {name: "Сохранить XML в файл"},
            "clear": {name: "Очистить XML"}
        }
    });
});

/** Инициация загрузки xsd*/
function xsd_upload() {
    visibleElement = document.getElementById("xml_text_field");
    hiddenElement = document.getElementById("hidden_xml_text_field");
    hiddenElement.value = visibleElement.value;
    $('#xsd_choice_xsd').trigger('click');
}

/** Отправка содержимого XML*/
function prefixModal() {
    visibleElement = document.getElementById("xml_text_field");
    hiddenElement = document.getElementById("modal_prefix_hidden_xml");
    hiddenElement.value = visibleElement.value;
    $('#prefixModal').modal();
}

function validate_xml(mode) {
    xml = document.getElementById("xml_text_field").value;
    $.ajax({
        url: "xml_sender/validate_xml",
        type: "POST",
        dataType: "script",
        data: {xml: xml, mode: mode},
    });
}

/** Подтверждение выбора*/
/*

modalConfirm('Сохранить настройку '+form_elements.form_settings_name+' ?', function (confirm) {
    if (confirm) {

    }
}
function modalConfirm(text, callback) {
    $('#confirmModal-text').html(text);
    $("#confirmModal").modal('show');
    $("#modal-confirm-button").off('click').one("click", function () {
        callback(true);
        $("#confirmModal").modal('hide');
    });
};*/
