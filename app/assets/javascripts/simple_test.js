function simple_get_choice_xml() { //* Получение настроек исходящего менеджера очередей */
    updateActualXml('', '#e9ecef');
    choice_xml = document.getElementById("xml_select_xml_name").value;
    $.ajax({
        url: "simple_tests/put_simple_test",
        type: "POST",
        dataType: "script",
        data: {
            choice_xml: choice_xml
        }});
}
function updateSimpleTest(xml_text, xml_answer, xml_description, autor, manager_name, queue_out, queue_in) {
    $('#xml_to_send').val(xml_text.slice(1, -1));
    $('#expected_answer').val(xml_answer.slice(1, -1));
    $('#xml_xml_description').val(xml_description);
    $('#xml_autor').val(autor);
    if ((manager_name && queue_out && queue_in) !== undefined && (manager_name && queue_out && queue_in) !== '') {
        $('#label_for_xml').html('<b>XML для запроса в очередь '+queue_out+' менеджера '+manager_name+'</b>');
        $('#label_for_expected_response').html('<b>Ожидаем получить из очереди: '+queue_in+'</b>');
    }
    else {
        $('#label_for_xml').html('<b>XML для запроса:</b>');
        $('#label_for_expected_response').html('<b>Ожидаем получить:</b>');
    }

}

function simple_test_data() { //* Получение полей Simple Test */
    updateActualXml('', '#e9ecef');
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
    document.getElementById("actual_answer").disabled = true;
}