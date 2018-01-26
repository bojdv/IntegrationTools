# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(window).load ->
jQuery ->

  # Обработка скрытия параметров автотестов
  $("#test_data_tir_version").change ->
    if $(this).val() is "ТИР 2.2"
      $("#tir_22").show()
      $('#tir_23').hide()
      menu = $("#version_functional option")
      for i in [0..menu.length]
        if menu[i] != undefined
          menu[i].selected = false
    else if $(this).val() is "ТИР 2.3"
      $("#tir_22").hide()
      $('#tir_23').show()

  $("#run-button").click ->
    menuTir22 = $("#test_data_functional_tir22 option")
    for i in [0...menuTir22.length]
      menuTir22[i].style.backgroundColor='transparent'
    menuTir23 = $("#test_data_functional_tir23 option")
    for i in [0...menuTir23.length]
      menuTir23[i].style.backgroundColor='transparent'