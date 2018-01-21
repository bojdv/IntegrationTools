function simple_get_choice_xml() { //* Получение настроек исходящего менеджера очередей */
    choice_xml = document.getElementById("xml_select_xml_name").value;
    $.ajax({
        url: "simple_tests/put_simple_test",
        type: "POST",
        dataType: "script",
        data: {
            choice_xml: choice_xml
        }});
}