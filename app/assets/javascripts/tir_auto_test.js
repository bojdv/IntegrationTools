// evSource = new EventSource("/tir_auto_tests/tester")
// // evSource.onmessage  = function (event) {
// //     console.log("OPEN state \n"+event.data);
// // };
// evSource.addEventListener('messages.create',function(event){
//     console.log("EventListener .. code.."+event.data);
// },false);
//
// // evSource.onerror = function (e) {
// //     console.log("Error State  \n\n"+e.data);
// // };
function updateLog() {
    console.log("Start Listener");
    evSource = new EventSource("/tir_auto_tests/tester")
    evSource.addEventListener('update_log',function(event){
        document.getElementById('tir_autotests_log').value += event.data
    },false);
    evSource.addEventListener('colorize',function(event){
        console.log('Event '+event.data)
        attr = event.data.split(',')
        colorize_options(attr[0], attr[1])
    },false);
}
function kill_listener() {
    evSource.close()
    console.log("Kill Listener");
}
function clear_log() {
    document.getElementById('tir_autotests_log').value = '';
}
function deselect_options() {
    var elements = document.getElementById("test_data_functional_tir22").options;
    for(var i = 0; i < elements.length; i++){
        elements[i].selected = false;
    }
    var elements = document.getElementById("test_data_functional_tir23").options;
    for(var i = 0; i < elements.length; i++){
        elements[i].selected = false;
    }
    // document.getElementById("test_data_functional_tir22").disabled = true
}
function colorize_options(functional, color) {
    deselect_options();
    func = 'div.test_data_functional_tir22 option[value="'+functional+'"]'
    document.querySelector(func).style.backgroundColor=color;
}