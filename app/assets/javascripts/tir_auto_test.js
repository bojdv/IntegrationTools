
var evSource = new EventSource("/tir_auto_tests/tester");

evSource.onmessage  = function (e) {
    console.log("OPEN state \n"+e.data);
    open_modal(e.data);
};


/*
evSource.addEventListener('message',function(e){
    console.log("EventListener .. code..");
},false);

evSource.onerror = function (e) {
    console.log("Error State  \n\n"+e.data);
};*/
