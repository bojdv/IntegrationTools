# encoding: utf-8
module CcFormatValidatorHelper

  class Validator
    require 'rexml/document'
    include REXML
    require 'nokogiri'

    def initialize
      @uuid = SecureRandom.uuid
      @xml = receive_xml
    end
    attr_accessor :xml

    def get_xsd
      case(@xml.root.elements[1].name)
        when 'PayDocRu','PayDocCur','CurrBuy','CurrSell','CurrConv','MandatorySaleBox','StatementRequest','SystemStatementRequest'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/xml_gate/request.xsd"))
        when 'StatementRequest'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/xml_gate/Запрос выписки пользовательский.xsd"))
      end
      return xsd
    end

    def make_answer(status = 'PROCESSED', message = 'Валидация пройдена')
      case(@xml.root.elements[1].name)
        when 'PayDocRu','PayDocCur','CurrBuy','CurrSell','CurrConv','MandatorySaleBox'
          answer  = Xml.find_by_xml_name('Ticket')
        when 'StatementRequest'
          answer = Xml.find_by_xml_name('Ticket')
      end
      case answer.xml_name
        when 'Ticket'
          xml_rexml = Document.new(answer.xml_text)
          xml_rexml.elements['//p:Ticket'].attributes['docType'] = @xml.root.elements[1].name
          xml_rexml.elements['//p:Ticket'].attributes['statusStateCode'] = status
          xml_rexml.elements['//p:Ticket'].attributes['docId'] = @xml.elements["//#{@xml.root.elements[1].name}"].attributes['docId']
          xml_rexml.elements['//p:MsgFromBank'].attributes['author'] = '&lt;iTools&gt;'
          xml_rexml.elements['//p:MsgFromBank'].attributes['message'] = message
      end
      return xml_rexml.to_s
    end

    def validate_cc_xml
      begin
        xsd = get_xsd
        if xsd.nil?
          CcFormatValidatorLog.create(uuid: @uuid, events: 'Валидация по XSD', status: 'FAIL', short_message: "Валидация по XSD провалена. Не найдена XSD")
          return
        end
        xml = Nokogiri::XML(@xml.to_s)
        result = xsd.validate(xml)
        if result.any?
          CcFormatValidatorLog.create(uuid: @uuid, events: 'Валидация по XSD', status: 'FAIL', short_message: "Валидация по XSD провалена", full_message: result.join('\n'))
          return result.join('\n').truncate(2500, :omission=> '...обрезано до 2500 символов')
        else
          CcFormatValidatorLog.create(uuid: @uuid, events: 'Валидация по XSD', status: 'OK', short_message: "Валидация по XSD выполнена успешно")
          return nil
        end
      rescue Exception => msg
        CcFormatValidatorLog.create(uuid: @uuid, events: 'Валидация по XSD', status: 'FAIL', short_message: "Валидация по XSD провалена", full_message: "Ошибка! #{msg.message}\n#{msg.backtrace.join("\n")}")
        return msg.truncate(2500, :omission=> '...обрезано до 2500 символов')
      end
    end

    def receive_xml # Получение сообщений из Active MQ по протоколу OpenWire
      manager = QueueManager.find_by_manager_name('iTools[CC_Validator]')
      queue = 'correqts_in'
      java_import 'org.apache.activemq.ActiveMQConnectionFactory'
      java_import 'javax.jms.Session'
      java_import 'javax.jms.TextMessage'
      java_import 'org.apache.activemq.command.ActiveMQDestination'
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
        puts "#{msg.message} #{msg.backtrace}"
      ensure
        receiver.close if receiver
        session.close if session
        connection.close if connection
      end
    end

    def send_to_amq_openwire(message) # Отправка сообщений в Active MQ по протоколу OpenWire
      java_import 'org.apache.activemq.ActiveMQConnectionFactory'
      java_import 'javax.jms.Session'
      java_import 'javax.jms.TextMessage'
      begin
        factory = ActiveMQConnectionFactory.new
        factory.setBrokerURL("tcp://vm-itools:61611")
        connection = factory.createQueueConnection('smx', 'smx')
        session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
        textMessage = session.createTextMessage(message)
        textMessage.setJMSCorrelationID(SecureRandom.uuid)
        sender = session.createSender(session.createQueue('correqts_out'))
        connection.start
        sender.send(textMessage)
        sender.close
        session.close
        connection.close
        CcFormatValidatorLog.create(uuid: @uuid, events: 'Отправка ответа', status: 'OK', short_message: 'Отправили ответ в очередь correqts_out', xml: textMessage.text )
      rescue => msg
        CcFormatValidatorLog.create(uuid: @uuid, events: 'Отправка ответа', status: 'FAIL', short_message: 'Ошибка при отправке ответа', full_message: "Ошибка! #{msg.message}\n#{msg.backtrace.join("\n")}")
        puts "#{msg.message} #{msg.backtrace}"
      ensure
        session.close if session
        connection.close if connection
      end
    end
  end
end
