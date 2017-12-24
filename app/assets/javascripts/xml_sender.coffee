# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
jQuery ->
  $('#xml_xml').parent().hide()
  xml = $('#xml_xml').html()
  $('#xml_name').change ->
    product = $('#xml_name :selected').text()
    options = $(xml).filter("optgroup[label = '#{product}']").html()
    if options
      $('#xml_xml').html(options)
      $('#xml_xml').parent().show()
    else
      $('#xml_xml').empty()
      $('#xml_xml').parent().hide()