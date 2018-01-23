# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

###
@updateSimpleTest = (xml_text, xml_answer,xml_description, autor) ->
  $('#xml_to_send').val(xml_text.slice(1, -1))
  $('#expected_answer').val(xml_answer.slice(1, -1))
  $('#xml_xml_description').val(xml_description)
  $('#xml_autor').val(autor)###
