# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->
  jQuery ->
  $('#xml_select_xml_name').parent().hide()
  $('#xml_select_category_name').parent().hide()
  xml = $('#xml_select_xml_name').html()
  category = $('#xml_select_category_name').html()

  $('#xml_product_name').change ->
    product = $('#xml_product_name :selected').text()
    options = $(category).filter("optgroup[label = '#{product}']").html()
    if options
      $('#xml_select_category_name').parent().show()
      $('#xml_select_xml_name').parent().hide()
      $('#xml_select_category_name').html(options)
      $('#xml_select_xml_name').empty()
    else
      $('#xml_select_category_name').empty()
      $('#xml_select_xml_name').empty()
      $('#xml_select_category_name').parent().hide()
      $('#xml_select_xml_name').parent().hide()

  $('#xml_select_category_name').click ->
    category_select = $('#xml_select_category_name :selected').text()
    options2 = $(xml).filter("optgroup[label = '#{category_select}']").html()
    if options2
      $('#xml_select_xml_name').parent().show()
      $('#xml_select_xml_name').html(options2)
    else
      $('#xml_select_xml_name').empty()
      $('#xml_select_xml_name').parent().hide()

@changeText = (name, host, port, user, password) ->
  $('#mq_attributes_queue').val name
  $('#mq_attributes_host').val host
  $('#mq_attributes_port').val port
  $('#mq_attributes_user').val user
  $('#mq_attributes_password').val password

@updateXml = (xml_text, xml_name) ->
  $('#xml_text_field').val(xml_text.slice(1, -1))
  $('#xml_xml_name').val(xml_name.slice(1, -1))