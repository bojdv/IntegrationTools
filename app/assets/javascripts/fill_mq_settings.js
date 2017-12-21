/**
 * Created by PekAV on 21.12.2017.
 */
function changeText()
{
    element = document.getElementById('mq_name');
    option = element.options[element.selectedIndex].text;
    document.getElementById('mq_attributes_queue').value = option;
}
function test_call(val)
{
    new Ajax.Request('/xml_sender/manager_choise', {
        method: 'post',
        parameters: {
            menu_id: val,
        }
    });
}