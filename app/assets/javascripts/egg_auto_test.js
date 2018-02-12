
function updateLog_egg() {
    console.log("Start Listener");
    evSource = new EventSource("/egg_auto_tests/live_stream")
    evSource.addEventListener('update_log',function(event){
        document.getElementById('egg_autotests_log').value += event.data
    },false);
    evSource.addEventListener('colorize',function(event){
        attr = event.data.split(',')
        colorize_options_egg(attr[0], attr[1], attr[2])
    },false);
}
function kill_listener_egg() {
    evSource.close()
    console.log("Kill Listener");
}
function clear_log_egg() {
    document.getElementById('egg_autotests_log').value = '';
}
function deselect_options_egg() {
    var elements = document.getElementById("test_data_functional_egg67").options;
    for(var i = 0; i < elements.length; i++){
        elements[i].selected = false;
    }
    var elements = document.getElementById("test_data_functional_egg68").options;
    for(var i = 0; i < elements.length; i++){
        elements[i].selected = false;
    }
    // document.getElementById("test_data_functional_tir22").disabled = true
}
function colorize_options_egg(egg_version, functional, color) {
    deselect_options_egg();
    if (egg_version == 'eGG 6.7'){
        func = 'div.test_data_functional_egg67 option[value="'+functional+'"]';
    }
    else if (egg_version == 'eGG 6.8'){
        func = 'div.test_data_functional_egg68 option[value="'+functional+'"]';
    }
    document.querySelector(func).style.backgroundColor=color;
}
function download_link_egg(log_file_name) {

    link = document.getElementById('download-link');
    link.setAttribute('href', '/egg_auto_tests/download_log?filename='+log_file_name);
    link.style.display = 'inline';
}