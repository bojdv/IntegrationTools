class XmlSenderController < ApplicationController
  def index
    @qm = QueueManager.pluck(:manager_name)
    @product = Product.all
  end
  def new
    @new_xml = Xml.new
    @product_name = Product.all
  end
  def create_xml
    @new_xml_save = Xml.new(new_xml_params)
    if @new_xml_save.save
      puts "Ok!"
    else
      @new_xml_save.errors.full_messages.each do |msg|
        puts msg
      end
    end

  end
  def send_to_queue
    if (params[:mq_attributes][:xsd]).blank?
      client = Stomp::Client.new(
          params[:mq_attributes][:user],
          params[:mq_attributes][:password],
          params[:mq_attributes][:host],
          params[:mq_attributes][:port])
      client.publish("/queue/#{params[:mq_attributes][:queue]}", params[:mq_attributes][:xml]) #Кидаем запрос в очередь
      client.close
    else
      puts "hi"
      xsd = Nokogiri::XML::Schema(params[:mq_attributes][:xsd])
      xml = Nokogiri::XML(params[:mq_attributes][:xml])
      result = xsd.validate(xml)
      respond_to do |format|
        format.js { render :js => "send_alert(\"#{result}\")" }
      end
    end

  end
  def manager_choise
    select_manager = QueueManager.find_by_manager_name(params[:manager][:manager_name])
    respond_to do |format|
      format.js { render :js => "changeText(\"#{select_manager.queue}\", \"#{select_manager.host}\", \"#{select_manager.port}\", \"#{select_manager.user}\", \"#{select_manager.password}\");" }
    end
  end
  def put_xml
    select_xml = Xml.find(params[:xml][:select_xml_name])
    respond_to do |format|
      format.js { render :js => "updateXml('#{select_xml.xml_text.inspect}')" }
    end
  end
  def tester
    if params[:xmlvalue].nil?
      respond_to do |format|
        format.js { render :js => "get_xml_text(\"#{Nokogiri::XML::Schema(params[:xsd_file][:xsd])}\")" }
      end
    else
      xsd = Nokogiri::XML::Schema(params[:xmlvalue][:xsd_path])
      puts xsd
      xml = Nokogiri::XML(params[:xmlvalue][:xml_value])
      puts xml
      result = xsd.validate(xml)
      respond_to do |format|
        format.js { render :js => "send_alert(\"#{result}\")" }
      end
    end
  end
end

private

def new_xml_params
  params.require(:xml).permit(:xml_text, :xml_name, :product_id)
end