# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(window).load ->
jQuery ->

# Обработка скрытия параметров автотестов
  $("#test_data_egg_version").change ->
    if $(this).val() is "eGG 6.7"
      $("#egg_67").show()
      $('#egg_68').hide()
      menu = $("#version_functional option")
      for i in [0..menu.length]
        if menu[i] != undefined
          menu[i].selected = false
    else if $(this).val() is "eGG 6.8"
      $("#egg_67").hide()
      $('#egg_68').show()

  $("#run-button").click ->
    menuEgg67 = $("#test_data_functional_egg67 option")
    for i in [0...menuEgg67.length]
      menuEgg67[i].style.backgroundColor='transparent'
    menuEgg68 = $("#test_data_functional_egg68 option")
    for i in [0...menuEgg68.length]
      menuEgg68[i].style.backgroundColor='transparent'