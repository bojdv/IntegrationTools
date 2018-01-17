class XmlSenderController < ApplicationController
  def index

    logged_in? ? @qm = QueueManager.where(user_id: current_user.id).order('manager_name').pluck(:manager_name) : @qm = QueueManager.pluck(:manager_name)
    @product = Product.all.order('product_name')
    @category = Category.all.order('category_name')
  end

  def create_xml
    response_ajax("<h5>Не заполнены параметры:</h5>#{@empty_filds.join}", 4000) and return if !get_empty_values(new_xml_params).empty?
    begin
      new_xml_save = Xml.new(new_xml_params)
      if new_xml_save.save
        response_ajax("Сохранили XML #{new_xml_params[:xml_name]} в категорию #{Category.where(id: new_xml_params[:category_id]).pluck(:category_name).join}") and return
      else
        response_ajax("Ошибка при сохранении:<br/> #{new_xml_save.errors.full_messages.inspect}") and return
      end
    rescue Exception => msg
      response_ajax("Что-то пошло не так:<br/> #{msg.message}", 4000)
    end
  end
  def create_category
    new_category_save = Category.new(new_category_params)
    begin
      if new_category_save.save
        response_ajax("Сохранили категорию #{new_category_params[:category_name]} для продукта #{Product.where(id: new_category_params[:product_id]).pluck(:product_name).join}") and return
      else
        response_ajax("Ошибка при сохранении:<br/> #{new_category_save.errors.full_messages.inspect}") and return
      end
    rescue Exception => msg
      response_ajax("Что-то пошло не так:<br/> #{msg.message}", 4000)
    end
  end
  def delete_xml
    xml_delete = Xml.find(params[:form_elements][:id])
    begin
      if xml_delete.destroy
        response_ajax("Удалили XML: #{xml_delete.xml_name}") and return
      else
        response_ajax("Ошибка при удалении:<br/> #{xml_delete.errors.full_messages.inspect}") and return
      end
    rescue Exception => msg
      response_ajax("Что-то пошло не так:<br/> #{msg.message}", 4000)
    end
  end
  def delete_category
    category_delete = Category.find(params[:form_elements][:id])
    begin
      if category_delete.destroy
        response_ajax("Удалили категорию: #{category_delete.xml_name}") and return
      else
        response_ajax("Ошибка при удалении:<br/> #{category_delete.errors.full_messages.inspect}") and return
      end
    rescue Exception => msg
      response_ajax("Что-то пошло не так:<br/> #{msg.message}", 4000)
    end
  end
  def save_xml
    begin
      xml_edit = Xml.find(params[:form_elements][:id])
      if xml_edit.update_attributes(save_xml_params)
        response_ajax("Сохранили изменения в XML #{xml_edit.xml_name}") and return
      else
        response_ajax("Ошибка при сохранении:<br/> #{xml_edit.errors.full_messages.inspect}") and return
      end
    rescue Exception => msg
      response_ajax("Случилось непредвиденное:<br/> #{msg.message}")
    end
  end
  # Создание, редактирование, удаление настроек менеджера очередей
  def crud_mq_settings
    begin
      if (params[:form_elements][:mode]) == 'new' # Создание настройки
        response_ajax("<h5>Не заполнены параметры:</h5>#{@empty_filds.join}") and return if !get_empty_values(manager_params).empty?
        new_settings = QueueManager.new(manager_params)
        if new_settings.save
          response_ajax("Создали настройки для #{manager_params[:manager_name]}", 2000) and return
        else
          response_ajax("#{new_settings.errors.full_messages.inspect}") and return
        end
      else if (params[:form_elements][:mode]) == 'edit' # Редактирование настройки
             response_ajax("<h5>Не заполнены параметры:</h5>#{@empty_filds.join}") and return if !get_empty_values(manager_params).empty?
             edit_manager = QueueManager.find_by_manager_name(params[:form_elements][:system_manager_name])
             puts manager_params
             if edit_manager.update_attributes(manager_params)
               response_ajax("Отредактировали настройки для #{manager_params[:manager_name]}", 2000) and return
             else
               response_ajax("#{new_settings.errors.full_messages.inspect}") and return
             end
           else if (params[:form_elements][:mode]) == 'delete' # Удаление настройки
                  response_ajax("Не выбрана настройка для удаления!") and return if params[:form_elements][:manager_name].empty?
                  delete_setting = QueueManager.find_by_manager_name(params[:form_elements][:manager_name])
                  if delete_setting.destroy
                    response_ajax("Удалили настройку #{manager_params[:manager_name]}", 2000) and return
                  else
                    response_ajax("#{new_settings.errors.full_messages.inspect}") and return
                  end
                end
           end
      end
    rescue Exception => msg
      response_ajax("Случилось непредвиденное:<br/> #{msg.message}", 5000)
    ensure
      puts 'ensure'
    end
  end

  def send_to_queue # Отправка сообщений в очередь
    response_ajax("<h5>Не заполнены параметры:</h5>#{@empty_filds.join}") and return if !get_empty_values(send_to_queue_params).empty?
    if (params[:mq_attributes][:manager_type]) == 'Active MQ'
      if (params[:mq_attributes][:protocol]) == 'OpenWire'
        send_to_amq_openwire
      else
        send_to_amq_stomp
      end
    else
      send_to_wmq
    end
  end
  def get_message # Получение сообщение из очереди
    response_ajax("Не заполнены параметры:#{@empty_filds.join}") and return if !get_empty_values(receive_queue_params).empty?
    if (params[:mq_attributes_in][:manager_type_in]) == 'Active MQ'
      if (params[:mq_attributes_in][:protocol_in]) == 'OpenWire'
        receive_from_amq_openwire
      else
        receive_from_amq_stomp
      end
    else
      receive_from_wmq
    end
  end

  def manager_choise # Заполнение параметров менеджера очередей
    manager_in_out = ["in", "out"]
    if (params[:manager]).present? # Исходящие параметры
      new_params = params.require(:manager).permit(:manager_name)
      response_ajax("Не выбраны настройки MQ из списка") and return if !get_empty_values(new_params).empty?
      select_manager = QueueManager.find_by_manager_name(params[:manager][:manager_name])
      respond_to do |format|
        format.js { render :js => "changeText(\"#{select_manager.manager_name}\",\"#{select_manager.queue_out}\", \"#{select_manager.host}\", \"#{select_manager.port}\", \"#{select_manager.user}\", \"#{select_manager.password}\", \"#{select_manager.manager_type}\", \"#{select_manager.channel_manager}\", \"#{select_manager.channel}\", \"#{select_manager.amq_protocol}\", \"#{select_manager.visible_all}\", \"#{manager_in_out[1]}\");" }
      end
    else if (params[:manager_in]).present? # Входящие параметры
           new_params = params.require(:manager_in).permit(:manager_name_in)
           response_ajax("Не выбраны настройки MQ из списка") and return if !get_empty_values(new_params).empty?
           select_manager = QueueManager.find_by_manager_name(params[:manager_in][:manager_name_in])
           respond_to do |format|
             format.js { render :js => "changeText(\"#{select_manager.manager_name}\",\"#{select_manager.queue_in}\", \"#{select_manager.host}\", \"#{select_manager.port}\", \"#{select_manager.user}\", \"#{select_manager.password}\", \"#{select_manager.manager_type}\", \"#{select_manager.channel_manager}\", \"#{select_manager.channel}\", \"#{select_manager.amq_protocol}\", \"#{select_manager.visible_all}\",\"#{manager_in_out[0]}\");" }
           end
         end
    end
  end
  def put_xml
    new_params = params.require(:xml).permit(:product_name, :select_xml_name)
    response_ajax("<h5>Не заполнены параметры:</h5>#{@empty_filds.join}") and return if !get_empty_values(new_params).empty?
    response_ajax("Не выбрана XML!") and return if params[:xml][:select_xml_name].nil?
    select_xml = Xml.find(params[:xml][:select_xml_name])
    respond_to do |format|
      format.js { render :js => "updateXml('#{select_xml.xml_text.inspect}', '#{select_xml.xml_name}', '#{select_xml.category.category_name}', '#{select_xml.xml_description.inspect}', '#{select_xml.private}', '#{select_xml.user.email}')" }
    end
  end

  # Валидация XML по XSD и просто
  def validate_xml
    if params[:xml].present?
      if params[:mode] == 'validate'
        response_ajax("Нет xml для валидации.") and return if params[:xml].empty?
        validate(params[:xml])
      else if params[:mode] == 'pretty'
             xml = Nokogiri::XML(params[:xml])
             respond_to do |format|
               format.js { render :js => "updateOutputXml('#{xml.to_xml.inspect}')" }
             end
           end
      end
    else if params[:xsd_choice].present?
           response_ajax("Нет xml для валидации.") and return if params[:xsd_choice][:xml_hidden].empty?
           validate_xsd(params[:xsd_choice][:xsd], params[:xsd_choice][:xml_hidden])
         end
    end
  end

  def add_prefix
    xml_in = params[:prefix_choice][:modal_prefix_hidden_xml]
    xml_out = String.new
    prefix = params[:prefix_choice][:prefix]
    xml_in.each_line do |line|
      line.gsub!("<", "<#{prefix}:")
      line.gsub!("<#{prefix}:/", "</#{prefix}:")
      line.gsub!("xmlns=", "xmlns:#{prefix}=")
      line.gsub!("xmlns:Dbo", "xmlns:#{prefix}Dbo")
      line.gsub!("<#{prefix}:?xml", "<?xml")
      xml_out << line
    end
    respond_to do |format|
      format.js { render :js => "updateOutputXml('#{xml_out.inspect}')" }
    end
  end
end

private

def new_xml_params
  params.require(:form_elements).permit(:xml_text, :category_id, :xml_name, :xml_description, :private).merge(:user_id => current_user.id.inspect)
end
def save_xml_params
  params.require(:form_elements).permit(:xml_text, :category_id, :xml_name, :id, :xml_description, :private)
end
def new_category_params
  params.require(:form_elements).permit(:category_name, :product_id).merge(:user_id => current_user.id.inspect)
end
def manager_params
  if params[:form_elements].has_value?('Active MQ')
    if params[:form_elements][:autorization] == 'true'
      params.require(:form_elements).permit(:manager_name, :queue_out, :host, :port, :user, :password, :manager_type, :amq_protocol, :visible_all).merge(:user_id => current_user.id.inspect)
    else
      params.require(:form_elements).permit(:manager_name, :queue_out, :host, :port, :manager_type, :amq_protocol, :visible_all).merge(:user_id => current_user.id.inspect)
    end
  else
    if params[:form_elements][:autorization] == 'true'
      params.require(:form_elements).permit(:manager_name, :queue_out, :host, :port, :user, :password, :manager_type, :channel, :channel_manager, :visible_all).merge(:user_id => current_user.id.inspect)
    else
      params.require(:form_elements).permit(:manager_name, :queue_out, :host, :port, :manager_type, :channel, :channel_manager, :visible_all).merge(:user_id => current_user.id.inspect)
    end
  end
end
def send_to_queue_params
  if params[:mq_attributes].has_value?('Active MQ')
    if params[:mq_attributes][:autorization] == 'true'
      params.require(:mq_attributes).permit(:manager_type, :protocol, :amq_protocol, :queue, :host, :port, :correlation_id, :xml, :user, :password)
    else
      params.require(:mq_attributes).permit(:manager_type, :protocol, :amq_protocol, :queue, :host, :port, :correlation_id, :xml)
    end
  else
    if params[:mq_attributes][:autorization] == 'true'
      params.require(:mq_attributes).permit(:manager_type, :protocol, :queue, :host, :port, :correlation_id, :xml, :channel, :channel_manager, :user, :password)
    else
      params.require(:mq_attributes).permit(:manager_type, :protocol, :queue, :host, :port, :correlation_id, :xml, :channel, :channel_manager)
    end
  end
end
def receive_queue_params
  if params[:mq_attributes_in].has_value?('Active MQ')
    if params[:mq_attributes_in][:autorization_in] == 'true'
      params.require(:mq_attributes_in).permit(:manager_type_in, :protocol_in, :amq_protocol_in, :queue_in, :host_in, :port_in, :user_in, :password_in)
    else
      params.require(:mq_attributes_in).permit(:manager_type_in, :protocol_in, :amq_protocol_in, :queue_in, :host_in, :port_in)
    end
  else
    if params[:mq_attributes_in][:autorization] == 'true'
      params.require(:mq_attributes_in).permit(:manager_type_in, :protocol_in, :queue_in, :host_in, :port_in, :channel_in, :channel_manager_in, :user_in, :password_in)
    else
      params.require(:mq_attributes_in).permit(:manager_type_in, :protocol_in, :queue_in, :host_in, :port_in, :channel_in, :channel_manager_in)
    end
  end
end