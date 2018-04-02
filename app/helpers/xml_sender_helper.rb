module XmlSenderHelper

  def response_ajax(text, time = 3000)
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
      @empty_filds[index] = 'XML сообщение' if ['xml','xml_text', 'send_xml'].include?(@empty_filds[index])
      @empty_filds[index] = 'Не выбрана XML из списка' if ['choice_xml'].include?(@empty_filds[index])
      @empty_filds[index] = 'Ответное XML сообщение' if ['xml_answer'].include?(@empty_filds[index])
      @empty_filds[index] = 'Ожидаемый ответ' if ['expected_answer'].include?(@empty_filds[index])
      @empty_filds[index] = 'Название настройки' if ['manager_name'].include?(@empty_filds[index])
      @empty_filds[index] = 'Не выбран менеджер очереди' if ['system_manager_name', 'manager_name_in'].include?(@empty_filds[index])
      @empty_filds[index] = 'Не выбрана категория' if ['choice_category'].include?(@empty_filds[index])
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
      factory = ActiveMQConnectionFactory.new
      factory.setBrokerURL("tcp://#{params[:mq_attributes][:host]}:#{params[:mq_attributes][:port]}")
      connection = factory.createQueueConnection(params[:mq_attributes][:user], params[:mq_attributes][:password])
      session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
      textMessage = session.createTextMessage(params[:mq_attributes][:xml])
      textMessage.setJMSCorrelationID(params[:mq_attributes][:correlation_id])
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
  def receive_from_amq_openwire(manager, mode) # Получение сообщений из Active MQ по протоколу OpenWire
    java_import 'org.apache.activemq.ActiveMQConnectionFactory'
    java_import 'javax.jms.Session'
    java_import 'javax.jms.TextMessage'
    java_import 'org.apache.activemq.command.ActiveMQDestination'
    puts 'Receive message from AMQ (OpenWire)'
    begin
      factory = ActiveMQConnectionFactory.new
      factory.setBrokerURL("tcp://#{manager.host}:#{manager.port}")
      manager.user.nil? ? user ='' : user=manager.user
      manager.password.nil? ? password ='' : password=manager.user
      connection = factory.createQueueConnection(user, password)
      session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
      receiver = session.createReceiver(session.createQueue(manager.queue_in))
      connection.start
      if mode == 'Получить первое сообщение'
        xml = receiver.receive(1000)
        response_ajax("Сообщения не найдены") and return if xml.nil?
        respond_to do |format|
          format.js { render :js => "updateInputXml('#{xml.getText.inspect}')" }
        end
      elsif mode == 'Получить все сообщения'
        count = 0
        xml_text = String.new
        xml = receiver.receive(100)
        response_ajax("Сообщения не найдены") and return if xml.nil?
        while !xml.nil?
          xml_text << xml.getText.inspect
          xml = receiver.receive(100)
          count +=1
          response_ajax("Невозможно удалить больше 50 сообщений:(") and return if count > 49
        end
        respond_to do |format|
          format.js { render :js => "updateInputXml('#{xml_text}')" }
        end
        #response_ajax("Получили #{count} сообщений") and return
      elsif mode == 'Очистить очередь'
        receiver.close if receiver
        connection.destroyDestination(session.createQueue(manager.queue_in)) # Удаляем очередь.
        response_ajax("Очистили очередь") and return
      end
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
  def receive_from_amq_stomp(manager, mode)
    puts 'Receive message from AMQ (STOMP)'
    begin
      client = Stomp::Client.new(
          manager.user,
          manager.password,
          manager.host,
          manager.port)
      message = String.new
      inputqueue = manager.queue_in
      if mode == ('Получить первое сообщение' || 'Получить все сообщения')
        client.subscribe(inputqueue){|msg| message << msg.body.to_s}
        client.join(1)
        client.close
        response_ajax("Сообщения не найдены") and return if message.empty?
        respond_to do |format|
          format.js { render :js => "updateInputXml('#{message.inspect}')" }
        end
      elsif mode == 'Очистить очередь'
        client.subscribe(inputqueue){|msg| message << msg.body.to_s}
        client.join(1)
        client.close
        response_ajax("Очистили очередь") and return
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
      factory = MQQueueConnectionFactory.new
      factory.setHostName(params[:mq_attributes][:host])
      factory.setQueueManager(params[:mq_attributes][:channel_manager])
      factory.setChannel(params[:mq_attributes][:channel])
      factory.setPort(1414)
      factory.setClientID('mqm')
      factory.setTransportType(JMSC.MQJMS_TP_CLIENT_MQ_TCPIP)
      connection = factory.createQueueConnection(params[:mq_attributes][:user], params[:mq_attributes][:password])
      session = connection.createQueueSession(false, QueueSession::AUTO_ACKNOWLEDGE)
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
  def receive_from_wmq(manager, mode)
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
      factory = MQQueueConnectionFactory.new
      factory.setHostName(manager.host)
      factory.setQueueManager(manager.channel_manager)
      factory.setChannel(manager.channel)
      factory.setPort(manager.port.to_i)
      factory.setClientID('mqm')
      factory.setTransportType(JMSC.MQJMS_TP_CLIENT_MQ_TCPIP)
      manager.user.nil? ? user ='' : user=manager.user
      manager.password.nil? ? password ='' : password=manager.user
      connection = factory.createQueueConnection(user, password)
      session = connection.createQueueSession(false, QueueSession::AUTO_ACKNOWLEDGE)
      receiver = session.createReceiver(session.createQueue(manager.queue_in))
      connection.start
      if mode == 'Получить первое сообщение'
        xml = receiver.receive(1000)
        response_ajax("Сообщения не найдены") and return if xml.nil?
        respond_to do |format|
          format.js { render :js => "updateInputXml('#{xml.getText.inspect}')" }
        end
      elsif mode == 'Получить все сообщения'
        count = 0
        xml_text = String.new
        xml = receiver.receive(100)
        response_ajax("Сообщения не найдены") and return if xml.nil?
        while !xml.nil?
          xml_text << xml.getText.inspect
          xml = receiver.receive(100)
          count +=1
          response_ajax("Невозможно удалить больше 50 сообщений:(") and return if count > 49
        end
        respond_to do |format|
          format.js { render :js => "updateInputXml('#{xml_text}')" }
        end
      elsif mode == 'Очистить очередь'
        count = 0
        while count < 50
          xml = receiver.receive(100)
          if xml.nil?
            response_ajax("Очистили очередь.<br/>Удалили #{count} сообщений") and return
            return false
          end
          count +=1
        end
        response_ajax("Невозможно удалить больше 50 сообщений:(") if count == 50
      end
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
