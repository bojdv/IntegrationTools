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
    newnewparams = new_category_params.merge(:creator_id => current_user.id.to_s)
    puts newnewparams
    new_category_save = Category.new(newnewparams)
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
    if xml_edit.update_attributes(new_xml_params)
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

         end
    end
  end
  def send_to_queue
    if (params[:mq_attributes][:xsd]).present?
      puts "xsd"
      xsd = Nokogiri::XML::Schema(params[:mq_attributes][:xsd])
      xmlt = Nokogiri::XML(params[:mq_attributes][:xml])
      result = xsd.validate(xmlt)
      respond_to do |format|
        format.js { render :js => "send_alert(\"#{result}\")" }
      end
    end
    puts "no xsd"
    client = Stomp::Client.new(
        params[:mq_attributes][:user],
        params[:mq_attributes][:password],
        params[:mq_attributes][:host],
        params[:mq_attributes][:port])
    client.publish("/queue/#{params[:mq_attributes][:queue]}", params[:mq_attributes][:xml]) #Кидаем запрос в очередь
    client.close
  end

  def manager_choise
    manager_type = ["in", "out"]
    if (params[:manager]).present?
    select_manager = QueueManager.find_by_manager_name(params[:manager][:manager_name])
    respond_to do |format|
      format.js { render :js => "changeText(\"#{select_manager.manager_name}\",\"#{select_manager.queue}\", \"#{select_manager.host}\", \"#{select_manager.port}\", \"#{select_manager.user}\", \"#{select_manager.password}\", \"#{manager_type[1]}\");" }
      end
    else if (params[:manager_in]).present?
        select_manager = QueueManager.find_by_manager_name(params[:manager_in][:manager_name_in])
          respond_to do |format|
            format.js { render :js => "changeText(\"#{select_manager.queue}\", \"#{select_manager.host}\", \"#{select_manager.port}\", \"#{select_manager.user}\", \"#{select_manager.password}\", \"#{manager_type[0]}\");" }
          end
     end
    end
  end
  def put_xml
    select_xml = Xml.find(params[:xml][:select_xml_name])
    respond_to do |format|
      format.js { render :js => "updateXml('#{select_xml.xml_text.inspect}', '#{select_xml.xml_name.inspect}', '#{select_xml.category.category_name}')" }
    end
  end
  def get_message
    client = Stomp::Client.new(
        params[:mq_attributes_in][:user_in],
        params[:mq_attributes_in][:password_in],
        params[:mq_attributes_in][:host_in],
        params[:mq_attributes_in][:port_in])
    message = String.new
    inputqueue = params[:mq_attributes_in][:queue_in]
    client.subscribe(inputqueue){|msg| message << msg.body.to_s}
    client.join(1)
    client.close
    puts message.first
    respond_to do |format|
      format.js { render :js => "updateInputXml('#{message.inspect}')" }
    end
  end

end



private

def new_xml_params
  params.require(:form_elements).permit(:xml_text, :category_id, :xml_name, :id, :creator_id => current_user)
end
def new_category_params
  params.require(:form_elements).permit(:category_name, :product_id, :creator_id)
end
def settings_params
  params.require(:form_elements).permit(:manager_name, :queue, :host, :port, :user, :password)
end