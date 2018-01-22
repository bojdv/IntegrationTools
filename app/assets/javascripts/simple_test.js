function simple_get_choice_xml() { //* Получение настроек исходящего менеджера очередей */
    updateActualXml('', 'transparent');
    choice_xml = document.getElementById("xml_select_xml_name").value;
    $.ajax({
        url: "simple_tests/put_simple_test",
        type: "POST",
        dataType: "script",
        data: {
            choice_xml: choice_xml
        }});
}
function simple_test_data() { //* Получение полей Simple Test */
    updateActualXml('', 'transparent');
    choice_xml = document.getElementById("xml_select_xml_name").value;
    send_xml = document.getElementById("xml_to_send").value;
    expected_answer = document.getElementById("expected_answer").value;
    choice_category = document.getElementById("xml_select_category_name").value;
    all_category_test = document.getElementById("xml_all_category_test").checked;
    $.ajax({
        url: "simple_tests/run_simpleTest",
        type: "POST",
        dataType: "script",
        data: {
            simple_test_data: {
                choice_xml: choice_xml,
                send_xml: send_xml,
                expected_answer: expected_answer,
                choice_category: choice_category,
                all_category_test: all_category_test
            }
        }});
}
function updateActualXml(xml_text, color) {
    document.getElementById("actual_answer").value = xml_text;
    document.getElementById("actual_answer").style.backgroundColor = color;
}