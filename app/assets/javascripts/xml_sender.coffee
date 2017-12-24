# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
jQuery ->
  #$('#xml_xml_name').parent().hide()
  xml = $('#xml_xml_name').html()
  $('#xml_product_name').change ->
    product = $('#xml_product_name :selected').text()
    options = $(xml).filter("optgroup[label = '#{product}']").html()
    if options
      $('#xml_xml_name').html(options)
      $('#xml_xml_name').parent().show()
    else
      $('#xml_xml_name').empty()
      #$('#xml_xml_name').parent().hide()