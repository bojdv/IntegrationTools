module XmlSenderHelper
  def response_ajax(text, time = 3000)
    respond_to do |format|
      format.js {render :js => "open_modal(#{text.inspect}, #{time.inspect});"}
    end
  end
  def get_empty_values hash
    a = []
    white_list = [
        'autor',
        'xml_description',
        'category_name',
        'select_category_name',
        'xml_name',
        'settings_name',
        'user',
        'password',
        'xml_in',
        'xsd',
        'queue_out',
        '@tempfile']
    #hash.reject do |k,v|
      #if v.is_a?(Hash)
    hash.reject do |key,value|
          if !white_list.include?(key)
            a << key if value.empty?
          end
        end
      #end
    #end
    puts a
    a.each_index do |index|
      a[index] = 'Очередь' if ['queue','queue_in'].include?(a[index])
      a[index] = 'Порт' if ['port','port_in'].include?(a[index])
      a[index] = 'Хост' if ['host','host_in'].include?(a[index])
      #a[index] = 'Пользователь' if ['user','user_in'].include?(a[index])
      # a#[index] = 'Пароль' if ['password','password_in'].include?(a[index])
      a[index] = 'XML сообщение' if a[index] == 'xml'
      a[index] = 'Название настройки' if ['manager_name'].include?(a[index])
      a[index] = 'Название продукта' if ['product_name'].include?(a[index])
      a[index] = 'Название XML' if ['select_xml_name'].include?(a[index])
    end
    a.map! {|value| '<br/>'+value}
    return a.join
  end
  def send_to_amq_openwire
    $CLASSPATH << "lib/activemq-all-5.11.1.jar"
    $CLASSPATH << "lib/log4j-1.2.17.jar"
    java_import 'org.apache.activemq.ActiveMQConnectionFactory'
    java_import 'javax.jms.Session'
    java_import 'javax.jms.TextMessage'
    begin
      puts "Create and setting Factory ...."
      factory = ActiveMQConnectionFactory.new
      factory.setBrokerURL("tcp://127.0.0.1:61616")
      puts "Creating Connection ...."
      connection = factory.createConnection()
      puts "Creating Session ...."
      session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
      puts "Create a messages"
      textMessage = session.createTextMessage("put some message here")
      textMessage.setJMSCorrelationID('TEST')

      puts "Receiving Response ...."
      receiver = session.createReceiver(session.createQueue("test_out"))
      puts "Send Request ...."
      sender = session.createSender(session.createQueue("test_in"))

      connection.start

      sender.send(textMessage)

      sender.close
      receiver.close
      session.close
      connection.close
    rescue => e
      puts e.message
    ensure
      receiver.close if receiver
      session.close if session
      connection.close if connection
    end
  end
  def send_to_amq_stomp
    begin
      response_ajax("<h5>Не заполнены параметры:</h5>#{get_empty_values(params)}") and return if !get_empty_values(params).empty?
      if (params[:mq_attributes][:xsd]).present?
        xsd = Nokogiri::XML::Schema(params[:mq_attributes][:xsd])
        xmlt = Nokogiri::XML(params[:mq_attributes][:xml])
        result = xsd.validate(xmlt)
        response_ajax("#{result.join('<br/>')}", 10000) and return if result.any?
      end
      client = Stomp::Client.new(
          params[:mq_attributes][:user],
          params[:mq_attributes][:password],
          params[:mq_attributes][:host],
          params[:mq_attributes][:port])
      client.publish("/queue/#{params[:mq_attributes][:queue]}", params[:mq_attributes][:xml]) #Кидаем запрос в очередь
      response_ajax('Отправили сообщение', '1500')
    rescue Exception => msg
      response_ajax("Случилось непредвиденное: #{msg.class} <br/> #{msg.message}")
    ensure
      client.close if !client.nil?
    end
  end

  def send_to_wmq
    $CLASSPATH << "lib/javax.jms-3.1.2.2.jar"
    $CLASSPATH << "lib/com.ibm.mqjms.jar"
    $CLASSPATH << "lib/com.ibm.mq.jar"
    $CLASSPATH << "lib/dhbcore.jar"
    $CLASSPATH << "lib/javax.resource.jar"
    $CLASSPATH << "lib/javax.transaction.jar"
    $CLASSPATH << "com.ibm.msg.client.osgi.wmq_7.0.1.3.jar"

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
        factory.setHostName("kc-14-52")

        factory.setQueueManager("local")
        factory.setChannel("local.server")
        factory.setPort(1414)
        factory.setClientID('mqm')
        factory.setTransportType(JMSC.MQJMS_TP_CLIENT_MQ_TCPIP)

        puts "Creating Connection ...."
        connection = factory.createQueueConnection('', '')

        puts "Creating Session ...."
        session = connection.createQueueSession(false, QueueSession::AUTO_ACKNOWLEDGE)

        puts "Receiving Response ...."
        receiver = session.createReceiver(session.createQueue("test_out"))
        puts "Send Request ...."
        sender = session.createSender(session.createQueue("test_in"))
        textMessage = session.createTextMessage("put some message here")
        textMessage.setJMSType("mcd://xmlns")
        textMessage.setJMSCorrelationID('TEST')
        textMessage.setJMSExpiration(2*1000)

        connection.start

        sender.send(textMessage)

        sender.close
        receiver.close
        session.close
        connection.close
      rescue => e
        puts e.message
      ensure
        receiver.close if receiver
        session.close if session
        connection.close if connection
      end
    end
  end
