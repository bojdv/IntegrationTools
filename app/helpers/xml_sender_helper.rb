module XmlSenderHelper
  def response_ajax(text, time = 2000)
    respond_to do |format|
      format.js {render :js => "open_modal(#{text.inspect}, #{time.inspect});"}
    end
  end
  def get_empty_values hash
    @empty_filds = []
    # white_list = [
    #     'autor',
    #     'xml_description',
    #     'category_name',
    #     'select_category_name',
    #     'xml_name',
    #     'settings_name',
    #     'user',
    #     'password',
    #     'xml_in',
    #     'xsd',
    #     'queue_out',
    #     '@tempfile']
    #hash.reject do |k,v|
    #if v.is_a?(Hash)
    hash.reject do |key,value|
      #if !white_list.include?(key)
      @empty_filds << key if value.empty?
      #end
    end
    #end
    #end
    @empty_filds.each_index do |index|
      @empty_filds[index] = 'Очередь' if ['queue', 'queue_in'].include?(@empty_filds[index])
      @empty_filds[index] = 'Порт' if ['port', 'port_in'].include?(@empty_filds[index])
      @empty_filds[index] = 'Хост' if ['host', 'host_in'].include?(@empty_filds[index])
      @empty_filds[index] = 'Пользователь' if ['user','user_in'].include?(@empty_filds[index])
      @empty_filds[index] = 'Пароль' if ['password','password_in'].include?(@empty_filds[index])
      @empty_filds[index] = 'XML сообщение' if ['xml','xml_text'].include?(@empty_filds[index])
      @empty_filds[index] = 'Название настройки' if ['manager_name'].include?(@empty_filds[index])
      @empty_filds[index] = 'Название продукта' if ['product_name'].include?(@empty_filds[index])
      @empty_filds[index] = 'Название XML' if ['select_xml_name', 'xml_name'].include?(@empty_filds[index])
      @empty_filds[index] = 'Описание XML' if ['xml_description'].include?(@empty_filds[index])
      @empty_filds[index] = 'Название канала' if ['channel', 'channel_in'].include?(@empty_filds[index])
      @empty_filds[index] = 'Название Администратора очередей' if ['channel_manager', 'channel_manager_in'].include?(@empty_filds[index])
      @empty_filds[index] = 'Название очереди' if ['queue_out', 'queue_in'].include?(@empty_filds[index])
    end
    @empty_filds.map! {|value| '<br/>'+value}
    return @empty_filds
  end
  def send_to_amq_openwire # Отправка сообщений в Active MQ по протоколу OpenWire
    java_import 'org.apache.activemq.ActiveMQConnectionFactory'
    java_import 'javax.jms.Session'
    java_import 'javax.jms.TextMessage'
    puts 'Sending message to AMQ (OpenWire)'
    begin
      puts "Create and setting Factory ...."
      factory = ActiveMQConnectionFactory.new
      factory.setBrokerURL("tcp://#{params[:mq_attributes][:host]}:#{params[:mq_attributes][:port]}")
      puts "Creating Connection ...."
      connection = factory.createQueueConnection(params[:mq_attributes][:user], params[:mq_attributes][:password])
      puts "Creating Session ...."
      session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
      puts "Create a messages"
      textMessage = session.createTextMessage(params[:mq_attributes][:xml])
      textMessage.setJMSCorrelationID(params[:mq_attributes][:correlation_id])
      puts "Send Request ...."
      sender = session.createSender(session.createQueue(params[:mq_attributes][:queue]))
      connection.start
      sender.send(textMessage)
      response_ajax("Отправили сообщение в очередь: #{params[:mq_attributes][:queue]}") and return
      sender.close
      session.close
      connection.close
    rescue => msg
      response_ajax("Случилось непредвиденное:<br/> #{msg.message}", 5000)
    ensure
      session.close if session
      connection.close if connection
    end
  end
  def receive_from_amq_openwire # Получение сообщений из Active MQ по протоколу OpenWire
    java_import 'org.apache.activemq.ActiveMQConnectionFactory'
    java_import 'javax.jms.Session'
    java_import 'javax.jms.TextMessage'
    java_import 'org.apache.activemq.command.ActiveMQDestination'
    puts 'Receive message from AMQ (OpenWire)'
    begin
      puts "Create and setting Factory ...."
      factory = ActiveMQConnectionFactory.new
      factory.setBrokerURL("tcp://#{params[:mq_attributes_in][:host_in]}:#{params[:mq_attributes_in][:port_in]}")
      puts "Creating Connection ...."
      connection = factory.createQueueConnection(params[:mq_attributes_in][:user_in], params[:mq_attributes_in][:password_in])
      puts "Creating Session ...."
      session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
      puts "Receiving Response ...."
      receiver = session.createReceiver(session.createQueue(params[:mq_attributes_in][:queue_in]))
      connection.start
      xml = receiver.receive(1000)
      response_ajax("Сообщения не найдены") and return if xml.nil?
      respond_to do |format|
        format.js { render :js => "updateInputXml('#{xml.getText.inspect}')" }
      end
      receiver.close
      connection.destroyDestination(session.createQueue(params[:mq_attributes_in][:queue_in])) # Удаляем очередь.
      session.close
      connection.close
    rescue => msg
      response_ajax("Случилось непредвиденное:<br/> #{msg.message}", 5000)
    ensure
      receiver.close if receiver
      session.close if session
      connection.close if connection
    end
  end
  def send_to_amq_stomp
    puts 'Sending message to AMQ (STOMP)'
    begin
      client = Stomp::Client.new(
          params[:mq_attributes][:user],
          params[:mq_attributes][:password],
          params[:mq_attributes][:host],
          params[:mq_attributes][:port])
      client.publish("/queue/#{params[:mq_attributes][:queue]}", params[:mq_attributes][:xml], headers = {'correlation-id'=>params[:mq_attributes][:correlation_id]}) #Кидаем запрос в очередь
      response_ajax("Отправили сообщение в очередь: #{params[:mq_attributes][:queue]}") and return
    rescue Exception => msg
      response_ajax("Случилось непредвиденное: #{msg.class} <br/> #{msg.message}")
    end
  end
  def receive_from_amq_stomp
    puts 'Receive message from AMQ (STOMP)'
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
      response_ajax("Случилось непредвиденное: #{msg.class} <br/> #{msg.message}")
    end
  end

  def send_to_wmq
    puts 'Sending message to WMQ'
    java_import 'javax.jms.JMSException'
    java_import 'javax.jms.QueueConnection'
    java_import 'javax.jms.QueueSender'
    java_import 'javax.jms.QueueReceiver'
    java_import 'javax.jms.QueueSession'
    java_import 'javax.jms.Session'
    java_import 'javax.jms.TextMessage'
    java_import 'com.ibm.mq.MQMessage'
    java_import 'com.ibm.mq.jms.MQQueueConnectionFactory'
    java_import 'com.ibm.mq.jms.JMSC'
    begin
      puts "Setting Factory ...."
      factory = MQQueueConnectionFactory.new
      factory.setHostName(params[:mq_attributes][:host])
      factory.setQueueManager(params[:mq_attributes][:channel_manager])
      factory.setChannel(params[:mq_attributes][:channel])
      factory.setPort(1414)
      factory.setClientID('mqm')
      factory.setTransportType(JMSC.MQJMS_TP_CLIENT_MQ_TCPIP)
      puts "Creating Connection ...."
      connection = factory.createQueueConnection(params[:mq_attributes][:user], params[:mq_attributes][:password])
      puts "Creating Session ...."
      session = connection.createQueueSession(false, QueueSession::AUTO_ACKNOWLEDGE)
      puts "Send Request ...."
      sender = session.createSender(session.createQueue(params[:mq_attributes][:queue]))
      textMessage = session.createTextMessage(params[:mq_attributes][:xml])
      textMessage.setJMSType("mcd://xmlns")
      textMessage.setJMSCorrelationID(params[:mq_attributes][:correlation_id])
      textMessage.setJMSExpiration(2*1000)
      connection.start
      sender.send(textMessage)
      sender.close
      session.close
      connection.close
      response_ajax("Отправили сообщение в очередь: #{params[:mq_attributes][:queue]}") and return
    rescue => msg
      response_ajax("Случилось непредвиденное: #{msg.class} <br/> #{msg.message}")
    ensure
      session.close if session
      connection.close if connection
    end
  end
  def receive_from_wmq
    puts 'Sending message to WMQ'
    java_import 'javax.jms.JMSException'
    java_import 'javax.jms.QueueConnection'
    java_import 'javax.jms.QueueSender'
    java_import 'javax.jms.QueueReceiver'
    java_import 'javax.jms.QueueSession'
    java_import 'javax.jms.Session'
    java_import 'javax.jms.TextMessage'
    java_import 'com.ibm.mq.MQMessage'
    java_import 'com.ibm.mq.jms.MQQueueConnectionFactory'
    java_import 'com.ibm.mq.jms.JMSC'
    begin
      puts "Setting Factory ...."
      factory = MQQueueConnectionFactory.new
      factory.setHostName(params[:mq_attributes_in][:host_in])
      factory.setQueueManager(params[:mq_attributes_in][:channel_manager_in])
      factory.setChannel(params[:mq_attributes_in][:channel_in])
      factory.setPort(params[:mq_attributes_in][:port_in].to_i)
      factory.setClientID('mqm')
      factory.setTransportType(JMSC.MQJMS_TP_CLIENT_MQ_TCPIP)
      puts "Creating Connection ...."
      connection = factory.createQueueConnection(params[:mq_attributes_in][:user_in], params[:mq_attributes_in][:password_in])
      puts "Creating Session ...."
      session = connection.createQueueSession(false, QueueSession::AUTO_ACKNOWLEDGE)
      puts "Receiving Response ...."
      receiver = session.createReceiver(session.createQueue(params[:mq_attributes_in][:queue_in]))
      connection.start
      xml = receiver.receive(1000)
      response_ajax("Сообщения не найдены") and return if xml.nil?
      respond_to do |format|
        format.js { render :js => "updateInputXml('#{xml.getText.inspect}')" }
      end
      receiver.close
      session.close
      connection.close
    rescue => msg
      response_ajax("Случилось непредвиденное: #{msg.class} <br/> #{msg.message}")
    ensure
      receiver.close if receiver
      session.close if session
      connection.close if connection
    end
  end
# Валидация по XSD
  def validate_xsd(xsd, xml)
    begin
      xsd = Nokogiri::XML::Schema(xsd)
      xml = Nokogiri::XML(xml)
      result = xsd.validate(xml)
      if result.any?
        response_ajax("#{result.join('<br/>')}", 20000) and return
      else
        response_ajax("Валидация прошла успешно!") and return
      end
    rescue Exception => msg
      response_ajax("Случилось непредвиденное:<br/> #{msg.message}")
    end
  end
# Валидация синтаксиса
  def validate(xml)
    begin
      xml = Nokogiri::XML(xml)
      if xml.errors.any?
        response_ajax("XML не валидна:<br/> #{xml.errors.join('<br/>')}", 20000) and return
      else
        response_ajax("Валидация прошла успешно!") and return
      end
    rescue Exception => msg
      response_ajax("Случилось непредвиденное:<br/> #{msg.message}")
    end
  end
end
