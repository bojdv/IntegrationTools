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
function send_alert(message)
{
    alert(message);
}
function get_xml_text(xsd)
{
    xml = document.getElementById("xml_text_field").value;
    $.ajax({
        url: "/xml_sender/tester",
        type: "POST",
        data: { xmlvalue: { xml_value: xml, xsd_value: xsd} },
    });
}
function addElement(text)
{
    $('#list').html(text);
}
function Base64(coding_mode){
    textarea = document.getElementById("xml_text_field");
    selection = (textarea.value).substring(textarea.selectionStart,textarea.selectionEnd);
    if (coding_mode == "encode"){
        selectionEncode = window.btoa(unescape(encodeURIComponent(selection)));
    }
    else{
        selectionEncode = decodeURIComponent(escape(window.atob(selection)));
    }
    new_text = textarea.value.replace(selection, selectionEncode);
    textarea.value = new_text;
}
function updateDiv()
{
    $( "#list" ).load(window.location.href + " #list" );
}
function test_call()
{
    $.ajax({
        url: "/xml_sender/tester",
        type: "POST",
        data: { product: { name: "Filip", description: "whatever" } },
    });
}