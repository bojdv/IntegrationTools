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
      case(@xml_doc_type)
        when 'PayDocRu'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Платежное поручение.xsd"))
        when 'CurrBuy'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Поручение на покупку валюты.xsd"))
        when 'CurrSell'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Поручение на продажу валюты.xsd"))
        when 'PayDocCur'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Поручение на перевод валюты.xsd"))
        when 'CurrConv'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Поручение на конверсию валюты.xsd"))
        when 'MandatorySaleBox'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Продажа валюты с транзитного счета.xsd"))
        when 'MT202'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Поручение на межбанковский перевод МТ202.xsd"))
        when 'MT103'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Поручение на клиентский перевод МТ103.xsd"))
        when 'StatementRequest'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Запрос выписки пользовательский.xsd"))
        when 'Statement'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Выписка.xsd"))
      end
      return xsd
    end

    def make_answer(status = 'PROCESSED', message = "\nРезультат валидации:\nвалидация пройдена\nРезультат проверки наличия эталонных элементов: \nэлементы присутствуют\n")
      begin
        answer = case(@xml_doc_type)
                   when 'PayDocRu','PayDocCur','CurrBuy','CurrSell','CurrConv','MandatorySaleBox','MT202','MT103'
                     Xml.find_by_xml_name('StateResponse')
                   when 'StatementRequest'
                     if status == 'PROCESSED'
                       Xml.find_by_xml_name('Statement')
                     else
                       Xml.find_by_xml_name('StateResponse')
                     end
                   else
                     Xml.find_by_xml_name('StateResponse')
                 end
        xml_rexml = Document.new(answer.xml_text)
        case answer.xml_name
          when 'StateResponse'
            xml_rexml.elements['//createTime'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//operationDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//docType'].text = @xml_doc_type
            xml_rexml.elements['//state'].text = status
            xml_rexml.elements['//docId'].text = @xml.elements["//docId"].text
            xml_rexml.elements['//bankMessage'].text = message
          when 'Statement'
            xml_rexml.elements['//acceptDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//fromDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//lastOperationDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//toDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//documentDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//recieptDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//valueDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//writeOffDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
        end
        xml_rexml.context[:attribute_quote] = :quote
        return xml_rexml.to_s.gsub('\'', '"') # иначе в декларации одинарные ковычки
      rescue Exception => msg
        puts "Error! #{msg.message}\n#{msg.backtrace.join("\n")}"
      end
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
          return result.join('\n').truncate(2000, :omission=> '...обрезано до 2000 символов')
        else
          CcFormatValidatorLog.create(uuid: @uuid, events: 'Валидация по XSD', status: 'OK', short_message: "Валидация по XSD выполнена успешно")
          return result
        end
      rescue Exception => msg
        CcFormatValidatorLog.create(uuid: @uuid, events: 'Валидация по XSD', status: 'FAIL', short_message: "Валидация по XSD провалена", full_message: "Ошибка! #{msg.message}\n#{msg.backtrace.join("\n")}")
        puts "Error! #{msg.message}\n#{msg.backtrace.join("\n")}"
        return msg.truncate(2000, :omission=> '...обрезано до 2000 символов')
      end
    end

    def check_etalon_elems
      begin
        etalon_elems, test_elems, not_include_elems = [], [], []
        # etalon_elems - все элементы из эталонной xml
        # test_elems - элементы из пришедшей xml
        # not_include_elems - эталонные элементы, которые отсутствуют в пришедшей xml
        category = Category.where(:category_name => "Эталонные XML. Integration Gate").first
        xml = Xml.where(:category_id => category.id, :xml_name => @xml_doc_type ).first
        xml_rexml = Document.new(xml.xml_text)
        xml_rexml.root.elements.each {|x| etalon_elems << x.name}
        @xml.root.elements.each {|x| test_elems << x.name}
        etalon_elems.each do |elem|
          not_include_elems << elem unless test_elems.include?(elem)
        end
        if not_include_elems.empty?
          CcFormatValidatorLog.create(uuid: @uuid, events: 'Проверка наличия эталонных элементов', status: 'OK', short_message: "Все эталонные элементы присутствуют в xml")
        else
          CcFormatValidatorLog.create(uuid: @uuid, events: 'Проверка наличия эталонных элементов', status: 'FAIL', short_message: "Эти элементы отсутствуют в xml: #{not_include_elems.join(',')}")
        end
        return not_include_elems
      rescue Exception => msg
        puts "Error! #{msg.message}\n#{msg.backtrace.join("\n")}"
        return not_include_elems
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
          @xml_doc_type = xml.root.name
          CcFormatValidatorLog.create(uuid: @uuid, events: 'Получение сообщения', status: 'OK', short_message: "Получили XML: #{@xml_doc_type}", xml: xml)
          return xml
        end
        return nil
      rescue => msg
        CcFormatValidatorLog.create(uuid: @uuid, events: 'Получение XML', status: 'FAIL', short_message: 'Ошибка при получении XML', full_message: "Ошибка! #{msg.message}\n#{msg.backtrace.join("\n")}")
        puts "Error! #{msg.message}\n#{msg.backtrace.join("\n")}"
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
        connection = factory.createConnection('smx', 'smx')
        session = connection.createSession(false, Session.AUTO_ACKNOWLEDGE);
        textMessage = session.createTextMessage(message)
        textMessage.setJMSCorrelationID(SecureRandom.uuid)
        sender = session.createSender(session.createQueue('correqts_out'))
        sender2 = session.createSender(session.createQueue('correqts_out2'))
        connection.start
        sender.send(textMessage)
        sender2.send(textMessage)
        sender.close
        sender2.close
        session.close
        connection.close
        CcFormatValidatorLog.create(uuid: @uuid, events: 'Отправка ответа', status: 'OK', short_message: 'Отправили ответ в очередь correqts_out', xml: textMessage.text )
      rescue => msg
        CcFormatValidatorLog.create(uuid: @uuid, events: 'Отправка ответа', status: 'FAIL', short_message: 'Ошибка при отправке ответа', full_message: "Ошибка! #{msg.message}\n#{msg.backtrace.join("\n")}")
        puts "Error! #{msg.message}\n#{msg.backtrace.join("\n")}"
      ensure
        session.close if session
        connection.close if connection
      end
    end
  end
end
