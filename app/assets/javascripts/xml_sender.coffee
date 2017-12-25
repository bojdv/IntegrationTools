# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
jQuery ->
  $('#xml_select_xml_name').parent().hide()
  xml = $('#xml_select_xml_name').html()
  $('#xml_product_name').change ->
    product = $('#xml_product_name :selected').text()
    options = $(xml).filter("optgroup[label = '#{product}']").html()
    if options
      $('#xml_select_xml_name').html(options)
      $('#xml_select_xml_name').parent().show()
    else
      $('#xml_select_xml_name').empty()
      $('#xml_select_xml_name').parent().hide()

@changeText = (name, host, port, user, password) ->
  $('#mq_attributes_queue').val name
  $('#mq_attributes_host').val host
  $('#mq_attributes_port').val port
  $('#mq_attributes_user').val user
  $('#mq_attributes_password').val password

@updateXml = (xml) ->
  $('#exampleInputEmail1').val(xml.slice(1, -1))