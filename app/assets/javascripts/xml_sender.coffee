# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(window).load ->
jQuery ->
  $('#xml_select_xml_name').parent().hide()
  $('#xml_select_category_name').parent().hide()
  $('#xml_description').hide()
  $('#wmq_fields').hide()
  $('#wmq_fields_in').hide()
  $("#autorization").hide()
  $("#autorization_in").hide()
  xml = $('#xml_select_xml_name').html()
  category = $('#xml_select_category_name').html()

  # Обработка скрытия параметров исходящего менеджера очередей
  $("#mq_attributes_manager_type").change ->
    if $(this).val() is "Active MQ"
      $("#protocol_select").show()
      $('#wmq_fields').hide()
    else
      $("#protocol_select").hide()
      $('#wmq_fields').show()

  # Обработка скрытия флага авторизации
  $("#mq_attributes_autorization").change ->
    if ($(this).is(':checked'))
      $("#autorization").show()
      $('#autorization').show()
    else
      $("#autorization").hide()
      $('#autorization').hide()
      $('#mq_attributes_user').val('')
      $('#mq_attributes_password').val('')


  # Список продуктов, категорий, xml
  $('#xml_product_name').change ->
    product = $('#xml_product_name :selected').text()
    options = $(category).filter("optgroup[label = '#{product}']").html()
    if options
      $('#xml_select_category_name').parent().show()
      $('#xml_description').show()
      $('#xml_select_xml_name').parent().hide()
      $('#xml_select_category_name').html(options.split("<option value=\"\"></option>").join(""))
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

# Заполнение полей менеджера очередей
@changeText = (manager_name, name, host, port, user, password, manager_type, channel_manager, channel, amq_protocol, visible_all) ->
  checked = if visible_all == "true" then true else false
  $('#mq_attributes_settings_name').val manager_name
  $('#mq_attributes_queue').val name
  $('#mq_attributes_host').val host
  $('#mq_attributes_port').val port
  $('#mq_attributes_visible_all').prop('checked', checked)
  if user # Заполнение авторизации исходящего менеджера
    $('#mq_attributes_autorization').prop('checked', true)
    $("#autorization").show()
    $('#mq_attributes_user').val user
    $('#mq_attributes_password').val password
  else
    $("#autorization").hide()
    $('#mq_attributes_autorization').prop('checked', false)
    $('#mq_attributes_user').val user
    $('#mq_attributes_password').val password
  if manager_type == 'Active MQ' # Заполнение типа исходящего менеджера
    $('#wmq_fields').hide()
    $("#protocol_select").show()
    $('#mq_attributes_manager_type').val manager_type
    $('#mq_attributes_protocol').val amq_protocol
  else if manager_type == 'WebSphere MQ'
    $('#wmq_fields').show()
    $("#protocol_select").hide()
    $('#mq_attributes_manager_type').val manager_type
    $('#mq_attributes_channel_manager').val channel_manager
    $('#mq_attributes_channel').val channel



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
@updateOutputXml = (xml_text) ->
  $('#xml_text_field').val(xml_text.slice(1, -1))