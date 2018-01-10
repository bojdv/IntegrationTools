# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(window).load ->
jQuery ->
  $('#xml_select_xml_name').parent().hide()
  $('#xml_select_category_name').parent().hide()
  $('#xml_description').hide()
  xml = $('#xml_select_xml_name').html()
  category = $('#xml_select_category_name').html()

  $('#xml_product_name').change ->
    product = $('#xml_product_name :selected').text()
    options = $(category).filter("optgroup[label = '#{product}']").html()
    if options
      $('#xml_select_category_name').parent().show()
      $('#xml_description').show()
      $('#xml_select_xml_name').parent().hide()
      $('#xml_select_category_name').html(options)
      $('#xml_select_xml_name').empty()
    else
      $('#xml_select_category_name').empty()
      $('#xml_select_xml_name').empty()
      $('#xml_select_category_name').parent().hide()
      $('#xml_select_xml_name').parent().hide()
      $('#xml_description').hide()

  $('#xml_select_category_name').click ->
    category_select = $('#xml_select_category_name :selected').text()
    $('#xml_category_name').val category_select
    options2 = $(xml).filter("optgroup[label = '#{category_select}']").html()
    if options2
      $('#xml_select_xml_name').parent().show()
      $('#xml_select_xml_name').html(options2.split("<option value=\"\"></option>").join(""))
    else
      $('#xml_select_xml_name').empty()
      $('#xml_select_xml_name').parent().hide()

@changeText = (manager_name, name, host, port, user, password, manager_type) ->
  if manager_type == 'out'
    $('#mq_attributes_settings_name').val manager_name
    $('#mq_attributes_queue').val name
    $('#mq_attributes_host').val host
    $('#mq_attributes_port').val port
    $('#mq_attributes_user').val user
    $('#mq_attributes_password').val password
  else if manager_type == 'in'
    $('#mq_attributes_in_queue_in').val name
    $('#mq_attributes_in_host_in').val host
    $('#mq_attributes_in_port_in').val port
    $('#mq_attributes_in_user_in').val user
    $('#mq_attributes_in_password_in').val password


@updateXml = (xml_text, xml_name, category_name, xml_description, private_xml, xml_autor) ->
  checked = if private_xml == "true" then true else false
  $('#xml_text_field').val(xml_text.slice(1, -1))
  $('#xml_xml_name').val(xml_name)
  $('#xml_category_name').val(category_name)
  $('#xml_xml_description').val(xml_description.slice(1, -1))
  $('#xml_private_xml').prop('checked', checked)
  $('#xml_autor').val(xml_autor)
@updateInputXml = (xml_text) ->
  $('#xml_text_in_field').val(xml_text.slice(1, -1))