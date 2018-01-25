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
}
function kill_listener() {
    evSource.close()
    console.log("Kill Listener");
    colorize_options();
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
}
function colorize_options() {
    deselect_options();
    document.querySelector('div.test_data_functional_tir22 option[value="Проверка адаптера БД"]').style.backgroundColor="green";
}