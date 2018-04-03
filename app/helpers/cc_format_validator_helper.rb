module CcFormatValidatorHelper
  require 'rexml/document'
  include REXML
  require 'nokogiri'

  def receive_xml # Получение сообщений из Active MQ по протоколу OpenWire
    manager = QueueManager.find_by_manager_name('KC-14-52 AMQ OpenWire')
    queue = 'test_in'
    @uuid = SecureRandom.uuid
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
      session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE)
      receiver = session.createReceiver(session.createQueue(queue))
      connection.start
      xml = receiver.receive(1000)
      if !xml.nil?
        xml = Document.new(xml.getText)
        doctype = xml.elements[1].name
        CcFormatValidatorLog.create(uuid: @uuid, events: 'Получение сообщения', status: 'OK', short_message: "Получили XML: #{doctype}", xml: xml)
        return xml
      end
      return nil
    rescue => msg
      CcFormatValidatorLog.create(uuid: @uuid, events: 'Получение XML', status: 'FAIL', short_message: 'Ошибка при получении XML', full_message: "Ошибка! #{msg.message}\n#{msg.backtrace.join("\n")}")
    ensure
      receiver.close if receiver
      session.close if session
      connection.close if connection
    end
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

  def get_xsd(xml)
    case(xml.elements[1].name)
      when 'PayDocRu'
        xsd = Nokogiri::XML::Schema(File.read("#{Rails.root}/lib/cc_format_validator/xsd/Платежное поручение.xsd"))
      when 'StatementRequest'
        xsd = Nokogiri::XML::Schema(File.read("#{Rails.root}/lib/cc_format_validator/xsd/Запрос выписки пользовательский.xsd"))
    end
      puts "XSD: #{xsd}"
      return xsd
  end

  def validate_cc_xml(xml)
    begin
      xsd = get_xsd(xml)
      if xsd.nil?
        CcFormatValidatorLog.create(uuid: @uuid, events: 'Валидация по XSD', status: 'FAIL', short_message: "Валидация по XSD провалена. Не найдена XSD")
        return
      end
      xml = Nokogiri::XML(xml.to_s)
      result = xsd.validate(xml)
      if result.any?
        CcFormatValidatorLog.create(uuid: @uuid, events: 'Валидация по XSD', status: 'FAIL', short_message: "Валидация по XSD провалена", full_message: result.join('\n'))
      else
        CcFormatValidatorLog.create(uuid: @uuid, events: 'Валидация по XSD', status: 'OK', short_message: "Валидация по XSD выполнена успешно")
      end
    rescue Exception => msg
      puts msg
      puts msg.backtrace.join("\n")
      CcFormatValidatorLog.create(uuid: @uuid, events: 'Валидация по XSD', status: 'FAIL', short_message: "Валидация по XSD провалена", full_message: "Ошибка! #{msg.message}\n#{msg.backtrace.join("\n")}")
    end
  end
end
