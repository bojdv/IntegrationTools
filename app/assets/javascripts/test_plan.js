function reportModal() {
    visibleElement = document.getElementById("xml_text_field");
    hiddenElement = document.getElementById("modal_prefix_hidden_xml");
    hiddenElement.value = visibleElement.value;
    $('#reportModal').modal();
}
$(function () {
    $('.show-popover').popover({
        container: 'body',
        trigger: 'hover focus',
        placement: 'top',
        html:true
    })
})
function show_comment(text, id) {
    if (text) {
        space = '\n'
    } else {
        space = ''
    }
    var utc = new Date().toJSON().slice(0,10);
    comment = document.getElementById('commentModal-text');
    comment.value = text + space + utc + ':\n';
    $('#commentModal').modal();
    $('#featureId').html(id);
}

function sendCommentText() {
    commentModal = document.getElementById("commentModal-text").value;
    featureId = document.getElementById("featureId").value;
    $.ajax({
        url: "safe_comment",
        type: "POST",
        dataType: "script",
        data: {
                comment: commentModal,
                featureId: featureId
        }});
    $('#commentModal').modal('hide')
}