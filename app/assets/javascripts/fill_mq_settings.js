/**
 * Created by PekAV on 21.12.2017.
 */
function changeText(name, host, port, user, password)
{
    document.getElementById('mq_attributes_queue').value = name;
    document.getElementById('mq_attributes_host').value = host;
    document.getElementById('mq_attributes_port').value = port;
    document.getElementById('mq_attributes_user').value = user;
    document.getElementById('mq_attributes_password').value = password;
}
function addElement(text)
{
    $('#list').html(text);
}
function updateDiv()
{
    $( "#list" ).load(window.location.href + " #list" );
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