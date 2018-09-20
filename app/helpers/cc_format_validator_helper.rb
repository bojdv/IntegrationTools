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

    def receive_xml # Получение сообщений из Active MQ по протоколу OpenWire
      manager = QueueManager.find_by_manager_name('iTools[CC_Validator]')
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
        receiver = session.createReceiver(session.createQueue(manager.queue_out))
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
        when 'CancelRequest'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Запрос на отзыв документа.xsd"))
        when 'NsoOpen'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Заявление на установление неснижаемого остатка на счете.xsd"))
        when 'PayRequest'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Исходящее платежное требование.xsd"))
        when 'CashFunds'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Заявление на выдачу наличных денежных средств.xsd"))
        when 'CollectionOrder'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Инкассовое поручение.xsd"))
        when 'SalaryDoc'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Зарплатная ведомость.xsd"))
        when 'PayRoll'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Зарплатная ведомость зарплатного проекта.xsd"))
        when 'DepositAddGrant'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Заявка на пополнение депозита.xsd"))
        when 'DepositLongGrand'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Заявка на пролонгацию депозита.xsd"))
        when 'DepositReturnGrant'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Заявки на возврат депозита.xsd"))
        when 'DepositGrant'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Заявки на депозит.xsd"))
        when 'CreditRepay'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Заявление на досрочное погашение кредита.xsd"))
        when 'CreditGrant'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Заявление на кредит.xsd"))
        when 'AccrRu'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Заявление на открытие аккредитива в валюте РФ.xsd"))
        when 'CreditTranche'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Заявление на транш.xsd"))
        when 'LetterInBank'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Письмо в банк.xsd"))
        when 'BankGuarantee'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Поручение на выдачу банковской гарантии.xsd"))
        when 'DetachmentPayRoll'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Реестр на открепление от зарплатного проекта.xsd"))
        when 'IssueCards'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Реестр на присоединение к зарплатному проекту.xsd"))
        when 'AcceptPayRequest'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Заявление об акцепте, отказе от акцепта.xsd"))
        when 'DealContract181I'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Контракт для постановки на учет.xsd"))
        when 'DealCred181I'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Кредитные договоры для постановки на учет.xsd"))
        when 'ConfDocCertificate138I'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Справка о подтверждающих документах.xsd"))
        when 'CurrDealCertificate181I'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Сведения о валютных операциях.xsd"))
        when 'ContractReissue'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Заявление об изменении сведений о контракте (кредитном договоре).xsd"))
        when 'DeregDP'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Заявление о снятии с учета контракта (кредитного договора).xsd"))
        when 'RegChanDPCC112'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Заявление на оформление справки о подтверждающих документах.xsd"))
        when 'DataRequest'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Запрос о начислениях.xsd"))
        when 'FinalPayment'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Извещение в ГИС ГМП.xsd"))
        when 'SystemDepositsRequest'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Запрос состояния по депозитному продукту.xsd"))
        when 'SystemCreditsRequest'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Запрос состояния по кредитному продукту.xsd"))
        when 'TCNoticeRequest'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Запрос уведомлений о зачислении средств на транзитный валютный счет.xsd"))
        when 'TRNoticeRequest'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Запрос извещений о зачислении средств на рублевый расчетный счет.xsd"))
        when 'SystemPayRequestsIn'
          xsd = Nokogiri::XML::Schema(File.read("C:/correqts_xsd/corporate/integration_gate/Запрос входящих платежных требований.xsd"))
      end
      return xsd
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
                   when 'DataRequest'
                     if status == 'PROCESSED'
                       Xml.find_by_xml_name('DataRequestResponse')
                     else
                       Xml.find_by_xml_name('EGG_Ticket')
                     end
                   when 'FinalPayment'
                     if status == 'PROCESSED'
                       Xml.find_by_xml_name('FinalPaymentResponse')
                     else
                       Xml.find_by_xml_name('EGG_Ticket')
                     end
                   when 'SystemDepositsRequest'
                     Xml.find_by_xml_name('SystemDepositsResponse')
                   when 'SystemCreditsRequest'
                     Xml.find_by_xml_name('SystemCreditsResponse')
                   when 'TCNoticeRequest'
                     Xml.find_by_xml_name('TCNotice')
                   when 'TRNoticeRequest'
                     Xml.find_by_xml_name('TRNotice')
                   when 'SystemPayRequestsIn'
                     Xml.find_by_xml_name('PayRequestIn')
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
          when 'DataRequestResponse'
            xml_rexml.elements['//tns:AnswerMessage'].attributes['processID'] = "ID_#{@xml.elements["//docId"].text}"
            xml_rexml.elements['//tns:Parameter[3]'].attributes['Value'] = "ID_#{@xml.elements["//docId"].text}"
            xml_rexml.elements['//tns:Parameter[4]'].attributes['Value'] = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//tns:Parameter[5]'].attributes['Value'] = "u_#{SecureRandom.uuid}"
            xml_rexml.elements['//tns:Parameter[7]'].attributes['Value'] = "ID_#{@xml.elements["//docId"].text}"
            xml_rexml.elements['//tns:Parameter[8]'].attributes['Value'] = SecureRandom.uuid
            xml_rexml.elements['//tns:Parameter[12]'].attributes['Value'] = @xml.elements["//docId"].text
          when 'EGG_Ticket'
            xml_rexml.elements['//ServiceID'].text = 'GIS_GMP_1.16_Payment' if @xml_doc_type == 'FinalPayment'
            xml_rexml.elements['//RSMEVDocID'].text = "ID_#{@xml.elements["//docId"].text}"
            xml_rexml.elements['//ErrorDescription'].text = message
          when 'FinalPaymentResponse'
            xml_rexml.elements['//tns:AnswerMessage'].attributes['processID'] = "ID_#{@xml.elements["//docId"].text}"
            xml_rexml.elements['//tns:Parameter[2]'].attributes['Value'] = "ID_#{@xml.elements["//docId"].text}"
            xml_rexml.elements['//tns:Parameter[3]'].attributes['Value'] = "ID_#{@xml.elements["//docId"].text}"
            xml_rexml.elements['//tns:Parameter[4]'].attributes['Value'] = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//tns:Parameter[5]'].attributes['Value'] = "u_#{SecureRandom.uuid}"
            xml_rexml.elements['//tns:Parameter[7]'].attributes['Value'] = "ID_#{@xml.elements["//docId"].text}"
            xml_rexml.elements['//tns:Parameter[9]'].attributes['Value'] = SecureRandom.uuid
            answer_decode = Base64.decode64(xml_rexml.elements['//tns:Answer'].text)
            answer_decode = answer_decode.force_encoding("utf-8")
            answer_decode = Document.new(answer_decode)
            answer_decode.elements['//ns2:EntityProcessResult'].attributes['entityId'] = "ID_#{@xml.elements["//docId"].text}"
            answer_encode = Base64.encode64(answer_decode.to_s)
            answer_encode = answer_encode.force_encoding("utf-8")
            xml_rexml.elements['//tns:Answer'].text = answer_encode
          when 'SystemDepositsResponse'
            xml_rexml.elements['//branchId'].text = @xml.elements["//branchId"].text
            xml_rexml.elements['//depoLoadRequestId'].text = @xml.elements["//docId"].text
            xml_rexml.elements['//orgId'].text = @xml.elements["//orgId"].text
            xml_rexml.elements['//depTermFrom'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//depTermTo'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//docDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//lastModifyDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//statementDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
          when 'SystemCreditsResponse'
            xml_rexml.elements['//branchId'].text = @xml.elements["//branchId"].text
            xml_rexml.elements['//creditLoadRequestId'].text = @xml.elements["//docId"].text
            xml_rexml.elements['//orgId'].text = @xml.elements["//orgId"].text
            xml_rexml.elements['//docDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//dataActuality'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//docCloseDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//lastModifyDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//nextPayDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//repaymentDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//statementDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//trancheDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//debtDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
          when 'TCNotice'
            xml_rexml.elements['//docDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//docsFromResidentDate'].text = (Time.now + (60*60*24)).strftime('%Y-%m-%dT%H:%M:%S')
          when 'TRNotice'
            xml_rexml.elements['//docDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
          when 'PayRequestIn'
            xml_rexml.elements['//acceptTermDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//docDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//docDispatchDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//lastModifyDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//operationDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//queueDate'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
            xml_rexml.elements['//receivedPayerBank'].text = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
        end
        xml_rexml.context[:attribute_quote] = :quote
        return xml_rexml.to_s.gsub('\'', '"') # иначе в декларации одинарные ковычки
      rescue Exception => msg
        puts "Error! #{msg.message}\n#{msg.backtrace.join("\n")}"
        CcFormatValidatorLog.create(uuid: @uuid, events: 'Формирование ответа', status: 'FAIL', short_message: msg.message, full_message: msg.backtrace.join("\n"))
        return nil
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
