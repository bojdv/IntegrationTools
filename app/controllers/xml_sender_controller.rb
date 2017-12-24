class XmlSenderController < ApplicationController
  def index
    @qm = QueueManager.pluck(:manager_name)
    @product = Product.all
  end
  def send_to_queue
    client = Stomp::Client.new(
        params[:mq_attributes][:user],
        params[:mq_attributes][:password],
        params[:mq_attributes][:host],
        params[:mq_attributes][:port])
    client.publish("/queue/test_in", params[:mq_attributes][:xml]) #Кидаем запрос в очередь
    client.close
  end
  def manager_choise
    select_manager = QueueManager.find_by_manager_name(params[:manager][:manager_name])
    respond_to do |format|
      format.js { render :js => "changeText(\"#{select_manager.queue}\", \"#{select_manager.host}\", \"#{select_manager.port}\", \"#{select_manager.user}\", \"#{select_manager.password}\");" }
    end
  end
  def get_xml_by_product
    @select_xml = Xml.where(product_name: 'TIR')
    send(list)
    @select_xml.each do |x|
      puts x.name
    end
    #@select_xml = Xml.where("product = '#{params[:product_name][:name]}'")
    #xml_list = "<a>#{select_xml}</a>"
    respond_to do |format|
      format.js { render :js => "addElement();" }
    end
  end
  def put_xml

  end
end