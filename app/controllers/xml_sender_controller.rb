class XmlSenderController < ApplicationController
  def index
    @qm = QueueManager.pluck(:manager_name)
    @product = Product.all
    @category = Category.all
  end

  def create_xml
    new_xml_save = Xml.new(new_xml_params)
    if new_xml_save.save
      respond_to do |format|
        format.js{ render :js => "send_alert('Сохранили XML в базу')" }
      end
    else
      respond_to do |format|
        format.js{ render :js => "send_alert(#{new_xml_save.errors.full_messages.inspect})" }
      end
    end
  end
  def create_category
    new_category_save = Category.new(new_category_params)
    if new_category_save.save
      respond_to do |format|
        format.js{ render :js => "send_alert('Сохранили категорию в базу')" }
      end
    else
      respond_to do |format|
        format.js{ render :js => "send_alert(#{new_category_save.errors.full_messages.inspect})" }
      end
    end
  end
  def delete_xml
    xml_delete = Xml.find(params[:form_elements][:id])
    if xml_delete.destroy
      respond_to do |format|
        format.js{ render :js => "send_alert('Удалили XML!')" }
      end
    else
      respond_to do |format|
        format.js{ render :js => "send_alert(#{xml_delete.errors.full_messages.inspect})" }
      end
    end
  end
  def delete_category
    category_delete = Category.find(params[:form_elements][:id])
    if category_delete.destroy
      respond_to do |format|
        format.js{ render :js => "send_alert('Удалили категорию!')" }
      end
    else
      respond_to do |format|
        format.js{ render :js => "send_alert(#{category_delete.errors.full_messages.inspect})" }
      end
    end
  end
  def save_xml
    xml_edit = Xml.find(params[:form_elements][:id])
    if xml_edit.update_attributes(save_xml_params)
      respond_to do |format|
        format.js{ render :js => "send_alert('Сохранили изменения!')" }
      end
    else
      respond_to do |format|
        format.js{ render :js => "send_alert(#{xml_edit.errors.full_messages.inspect})" }
      end
    end
  end
  def crud_mq_settings
    a = params.require(:form_elements).permit(:manager_name, :queue_out, :host, :port, :user, :password, :manager_type, :amq_protocol) if params[:form_elements].has_value?('Active MQ')
    response_ajax("<h5>Не заполнены параметры:</h5>#{get_empty_values(a)}") and return if !get_empty_values(a).empty?
    if (params[:form_elements][:mode]) == 'new'
      new_settings = QueueManager.new(settings_params)
      if new_settings.save
        respond_to do |format|
          format.js{ render :js => "send_alert('Сохранили настройки в базу')" }
        end
      else
        respond_to do |format|
          format.js{ render :js => "send_alert(#{new_settings.errors.full_messages.inspect})" }
        end
      end
    else if (params[:form_elements][:mode]) == 'delete'
           delete_setting = QueueManager.find_by_manager_name(params[:form_elements][:manager_name])
           if delete_setting.destroy
             respond_to do |format|
               format.js{ render :js => "send_alert('Удалили настройку #{params[:form_elements][:manager_name]}!')" }
             end
           else
             respond_to do |format|
               format.js{ render :js => "send_alert(#{delete_setting.errors.full_messages.inspect})" }
             end
           end
         end
    end
  end

  def send_to_queue
    send_to_amq_openwire
  end

  def manager_choise
    response_ajax("Не выбраны настройки MQ из списка") and return if !get_empty_values(params).empty?
    manager_type = ["in", "out"]
    if (params[:manager]).present?
    select_manager = QueueManager.find_by_manager_name(params[:manager][:manager_name])
    respond_to do |format|
      format.js { render :js => "changeText(\"#{select_manager.manager_name}\",\"#{select_manager.queue_out}\", \"#{select_manager.host}\", \"#{select_manager.port}\", \"#{select_manager.user}\", \"#{select_manager.password}\", \"#{manager_type[1]}\");" }
      end
    else if (params[:manager_in]).present?
        select_manager = QueueManager.find_by_manager_name(params[:manager_in][:manager_name_in])
          respond_to do |format|
            format.js { render :js => "changeText(\"#{select_manager.manager_name}\",\"#{select_manager.queue}\", \"#{select_manager.host}\", \"#{select_manager.port}\", \"#{select_manager.user}\", \"#{select_manager.password}\", \"#{manager_type[0]}\");" }
          end
     end
    end
  end
  def put_xml
    response_ajax("<h5>Не заполнены параметры:</h5>#{get_empty_values(params)}") and return if !get_empty_values(params).empty?
    response_ajax("Не выбрана XML!") and return if params[:xml][:select_xml_name].nil?
    select_xml = Xml.find(params[:xml][:select_xml_name])
    respond_to do |format|
      format.js { render :js => "updateXml('#{select_xml.xml_text.inspect}', '#{select_xml.xml_name}', '#{select_xml.category.category_name}', '#{select_xml.xml_description.inspect}', '#{select_xml.private}', '#{select_xml.user.email}')" }
    end
  end
  def get_message
    response_ajax("Не заполнены параметры:#{get_empty_values(params)}") and return if !get_empty_values(params).empty?
    begin
    client = Stomp::Client.new(
        params[:mq_attributes_in][:user_in],
        params[:mq_attributes_in][:password_in],
        params[:mq_attributes_in][:host_in],
        params[:mq_attributes_in][:port_in])
    message = String.new
    inputqueue = params[:mq_attributes_in][:queue_in]
    client.subscribe(inputqueue){|msg| message << msg.body.to_s}
    client.join(1)
    response_ajax("Сообщения отсутствуют") and return if message.empty?
    respond_to do |format|
      format.js { render :js => "updateInputXml('#{message.inspect}')" }
    end
    rescue Exception => msg
      response_ajax("Случилось непредвиденное:<br/> #{msg.message}")
    ensure
      client.close if !client.nil?
    end
  end
end

private

def new_xml_params
  params.require(:form_elements).permit(:xml_text, :category_id, :xml_name, :xml_description, :private).merge(:user_id => current_user.id)
end
def save_xml_params
  params.require(:form_elements).permit(:xml_text, :category_id, :xml_name, :id, :xml_description, :private)
end
def new_category_params
  params.require(:form_elements).permit(:category_name, :product_id).merge(:user_id => current_user.id)
end
def settings_params
  params.require(:form_elements).permit(:manager_name, :queue_out, :host, :port, :user, :password, :manager_type, :amq_protocol, :channel_manager, :channel).merge(:user_id => current_user.id)
end