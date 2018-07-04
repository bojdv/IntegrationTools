function reportModal() {
    visibleElement = document.getElementById("xml_text_field");
    hiddenElement = document.getElementById("modal_prefix_hidden_xml");
    hiddenElement.value = visibleElement.value;
    $('#reportModal').modal();
}
$(function () {
    $('.show-popover').popover({
        container: 'body',
        trigger: 'hover focus click',
        placement: 'top',
        html:true
    })
})