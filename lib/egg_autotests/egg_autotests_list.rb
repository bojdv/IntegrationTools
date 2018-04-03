include EggAutoTestsHelper
require 'rexml/document'
include REXML
require 'savon'
require_dependency "#{Rails.root}/lib/egg_autotests/ia_ActiveMQ"

class EggAutotestsList

  def initialize(egg_version)
    # Переменные для всех тестов
    @@pass_menu_color = '#b3ffcc'
    @@fail_menu_color = '#ff3333'
    @@not_find_xml = 'XML не найдена'
    @@not_receive_answer = 'Не получили ответ от eGG:('
    @@egg_version = egg_version
  end

  def runTest_egg(components)

    if components.include?('Проверка ИА Active MQ')
      test = IA_ActiveMQ.new
      test.run_RequestMessage
    end

    if components.include?('Проверка ИА УФЭБС (ГИС ГМП)')
      sleep 1.5
      menu_name = 'Проверка ИА УФЭБС (ГИС ГМП)'
      category = Category.find_by_category_name('ИА УФЭБС ГИС ГМП')
      dir_outbound = 'C:/data/inbox/1/outbound'
      dir_inbound = 'C:/data/inbox/1/inbound'
      begin # ed101
        @result = true
        xml_name = 'ed101'
        xml_root_element = 'ED101'
        send_to_log_egg("#{puts_line_egg}", "#{puts_line_egg}")
        send_to_log_egg("Начали проверку: #{menu_name}. #{xml_name}", "Начали проверку: #{menu_name}. #{xml_name}")
        send_to_log_egg("Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log_egg("Получили xml: #{xml.xml_name}\n#{xml.xml_text}")
        xml = Document.new(xml.xml_text)
        xml.elements["//ed:#{xml_root_element}"].attributes['EDNo'] = Random.rand(1000..50000)
        send_to_log_egg("Валидируем XML для запроса...", "Валидируем XML для запроса...")
        validate_egg_xml("#{Rails.root}/lib/egg_autotests/xsd/ufebs_file/cbr_#{xml_name}_v2018.1.1.xsd", xml.to_s)
        FileUtils.rm_r dir_inbound if File.directory?(dir_inbound)# Чистим каталог для получения
        send_to_log_egg("Удалили каталог #{dir_inbound}...")
        File.open("#{dir_outbound}/#{xml_name}.xml", 'w'){ |file| file.write xml.to_s }
        send_to_log_egg("Положили запрос в каталог #{dir_outbound}", "Положили запрос в каталог #{dir_outbound}")
        answer = ufebs_file_count
        puts answer
        if answer.first == 1 and answer.last == 1
          send_to_log_egg("Проверка пройдена!", "Проверка пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, pass_menu_color) if @result
        elsif answer.first == 0 and answer.last == 0
          @result = false
          send_to_log_egg("Проверка не пройдена! Не получили ответ от eGG", "Проверка не пройдена! Не получили ответ от eGG")
          colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
        elsif answer.first == 1 and answer.last == 0
          @result = false
          send_to_log_egg("Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус", "Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус")
          colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
        end
      rescue Exception => msg
        send_to_log_egg("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
        colorize_egg(tests_params_egg[:egg_version] , menu_name, fail_menu_color)
      end

      begin # ed104
        sleep 1.5
        xml_name = 'ed104'
        xml_root_element = 'ED104'
        send_to_log_egg("#{puts_line_egg}", "#{puts_line_egg}")
        send_to_log_egg("Начали проверку: #{menu_name}. #{xml_name}", "Начали проверку: #{menu_name}. #{xml_name}")
        send_to_log_egg("Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log_egg("Получили xml: #{xml.xml_name}\n#{xml.xml_text}")
        xml = Document.new(xml.xml_text)
        xml.elements["//ed:#{xml_root_element}"].attributes['EDNo'] = Random.rand(1000..50000)
        send_to_log_egg("Валидируем XML для запроса...", "Валидируем XML для запроса...")
        validate_egg_xml("#{Rails.root}/lib/egg_autotests/xsd/ufebs_file/cbr_#{xml_name}_v2018.1.1.xsd", xml.to_s)
        FileUtils.rm_r dir_inbound if File.directory?(dir_inbound)# Чистим каталог для получения
        send_to_log_egg("Удалили каталог #{dir_inbound}'...")
        File.open("#{dir_outbound}/#{xml_name}.xml", 'w'){ |file| file.write xml.to_s }
        send_to_log_egg("Положили запрос в каталог #{dir_outbound}", "Положили запрос в каталог #{dir_outbound}")
        answer = ufebs_file_count
        if answer.first == 1 and answer.last == 1
          send_to_log_egg("Проверка пройдена!", "Проверка пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, pass_menu_color) if @result
        elsif answer.first == 0 and answer.last == 0
          @result = false
          send_to_log_egg("Проверка не пройдена! Не получили ответ от eGG", "Проверка не пройдена! Не получили ответ от eGG")
          colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
        elsif answer.first == 1 and answer.last == 0
          @result = false
          send_to_log_egg("Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус", "Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус")
          colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
        end
      rescue Exception => msg
        send_to_log_egg("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
        colorize_egg(tests_params_egg[:egg_version] , menu_name, fail_menu_color)
      end

      begin # ed105
        sleep 1.5
        xml_name = 'ed105'
        xml_root_element = 'ED105'
        send_to_log_egg("#{puts_line_egg}", "#{puts_line_egg}")
        send_to_log_egg("Начали проверку: #{menu_name}. #{xml_name}", "Начали проверку: #{menu_name}. #{xml_name}")
        send_to_log_egg("Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log_egg("Получили xml: #{xml.xml_name}\n#{xml.xml_text}")
        xml = Document.new(xml.xml_text)
        xml.elements["//ed:#{xml_root_element}"].attributes['EDNo'] = Random.rand(1000..50000)
        send_to_log_egg("Валидируем XML для запроса...", "Валидируем XML для запроса...")
        validate_egg_xml("#{Rails.root}/lib/egg_autotests/xsd/ufebs_file/cbr_#{xml_name}_v2018.1.1.xsd", xml.to_s)
        FileUtils.rm_r dir_inbound if File.directory?(dir_inbound)# Чистим каталог для получения
        send_to_log_egg("Удалили каталог #{dir_inbound}'...")
        File.open("#{dir_outbound}/#{xml_name}.xml", 'w'){ |file| file.write xml.to_s }
        send_to_log_egg("Положили запрос в каталог #{dir_outbound}", "Положили запрос в каталог #{dir_outbound}")
        answer = ufebs_file_count
        if answer.first == 1 and answer.last == 1
          send_to_log_egg("Проверка пройдена!", "Проверка пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, pass_menu_color) if @result
        elsif answer.first == 0 and answer.last == 0
          @result = false
          send_to_log_egg("Проверка не пройдена! Не получили ответ от eGG", "Проверка не пройдена! Не получили ответ от eGG")
          colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
        elsif answer.first == 1 and answer.last == 0
          @result = false
          send_to_log_egg("Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус", "Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус")
          colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
        end
      rescue Exception => msg
        send_to_log_egg("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
        colorize_egg(tests_params_egg[:egg_version] , menu_name, fail_menu_color)
      end

      begin # ed108
        sleep 1.5
        xml_name = 'ed108'
        xml_root_element = 'ED108'
        date = Date.parse("#{Random.rand(2010..2017)}-#{Random.rand(1..11)}-#{Random.rand(1..28)}")
        send_to_log_egg("#{puts_line_egg}", "#{puts_line_egg}")
        send_to_log_egg("Начали проверку: #{menu_name}. #{xml_name}", "Начали проверку: #{menu_name}. #{xml_name}")
        send_to_log_egg("Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log_egg("Получили xml: #{xml.xml_name}\n#{xml.xml_text}")
        xml = Document.new(xml.xml_text)

        xml.elements["//ed:#{xml_root_element}"].attributes['EDNo'] = Random.rand(1000..50000)
        xml.elements["//ed:#{xml_root_element}"].attributes['ChargeOffDate'] = date
        xml.elements["//ed:#{xml_root_element}"].attributes['EDDate'] = date
        xml.elements["//ed:#{xml_root_element}"].attributes['FileDate'] = date
        xml.elements["//ed:#{xml_root_element}"].attributes['ReceiptDate'] = date
        xml.elements["//ed:AccDoc"].attributes['AccDocDate'] = date
        xml.elements["//ed:CreditTransferTransactionInfo"].attributes['PayerDocDate'] = date
        xml.elements["//ed:CreditTransferTransactionInfo"].attributes['TransactionDate'] = date

        send_to_log_egg("Валидируем XML для запроса...", "Валидируем XML для запроса...")
        validate_egg_xml("#{Rails.root}/lib/egg_autotests/xsd/ufebs_file/cbr_#{xml_name}_v2018.1.1.xsd", xml.to_s)
        FileUtils.rm_r dir_inbound if File.directory?(dir_inbound)# Чистим каталог для получения
        send_to_log_egg("Удалили каталог #{dir_inbound}'...")
        File.open("#{dir_outbound}/#{xml_name}.xml", 'w'){ |file| file.write xml.to_s }
        send_to_log_egg("Положили запрос в каталог #{dir_outbound}", "Положили запрос в каталог #{dir_outbound}")
        answer = ufebs_file_count
        if answer.first == 1 and answer.last == 1
          send_to_log_egg("Проверка пройдена!", "Проверка пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, pass_menu_color) if @result
        elsif answer.first == 0 and answer.last == 0
          @result = false
          send_to_log_egg("Проверка не пройдена! Не получили ответ от eGG", "Проверка не пройдена! Не получили ответ от eGG")
          colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
        elsif answer.first == 1 and answer.last == 0
          @result = false
          send_to_log_egg("Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус", "Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус")
          colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
        end
      rescue Exception => msg
        send_to_log_egg("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
        colorize_egg(tests_params_egg[:egg_version] , menu_name, fail_menu_color)
      end

      begin # packetepd
        sleep 1.5
        xml_name = 'packetepd'
        xml_root_element = 'PacketEPD'
        #date = Date.parse("#{Random.rand(2010..2017)}-#{Random.rand(1..11)}-#{Random.rand(1..28)}")
        send_to_log_egg("#{puts_line_egg}", "#{puts_line_egg}")
        send_to_log_egg("Начали проверку: #{menu_name}. #{xml_name}", "Начали проверку: #{menu_name}. #{xml_name}")
        send_to_log_egg("Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log_egg("Получили xml: #{xml.xml_name}\n#{xml.xml_text}")
        xml = Document.new(xml.xml_text)
        xml.elements["//ed:#{xml_root_element}"].attributes['EDNo'] = Random.rand(1000..50000)
        xml.elements["//ed:ED101"].attributes['EDNo'] = Random.rand(1000..50000)
        xml.elements["//ed:ED104"].attributes['EDNo'] = Random.rand(1000..50000)
        xml.elements["//ed:ED105"].attributes['EDNo'] = Random.rand(1000..50000)
        send_to_log_egg("Валидируем XML для запроса...", "Валидируем XML для запроса...")
        validate_egg_xml("#{Rails.root}/lib/egg_autotests/xsd/ufebs_file/cbr_#{xml_name}_v2018.1.1.xsd", xml.to_s)
        FileUtils.rm_r dir_inbound if File.directory?(dir_inbound)# Чистим каталог для получения
        send_to_log_egg("Удалили каталог #{dir_inbound}'...")
        File.open("#{dir_outbound}/#{xml_name}.xml", 'w'){ |file| file.write xml.to_s }
        send_to_log_egg("Положили запрос в каталог #{dir_outbound}", "Положили запрос в каталог #{dir_outbound}")
        answer = ufebs_file_count(true)
        if answer.first == 3 and answer.last == 3
          send_to_log_egg("Проверка пройдена!", "Проверка пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, pass_menu_color) if @result
        elsif answer.first == 0 and answer.last == 0
          @result = false
          send_to_log_egg("Проверка не пройдена! Не получили ответ от eGG", "Проверка не пройдена! Не получили ответ от eGG")
          colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
        elsif answer.first == 1 and answer.last == 0
          @result = false
          send_to_log_egg("Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус", "Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус")
          colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
        else
          @result = false
          send_to_log_egg("Проверка не пройдена!", "Проверка не пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
        end
      rescue Exception => msg
        send_to_log_egg("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
        colorize_egg(tests_params_egg[:egg_version] , menu_name, fail_menu_color)
      end
    end

    if components.include?('Проверка СА ГИС ГМП')
      sleep 0.5
      menu_name = 'Проверка СА ГИС ГМП'
      category = Category.find_by_category_name('СА ГИС ГМП')
      manager = QueueManager.find_by_manager_name('iTools[EGG]')
      # begin
      #   sleep 1.5
      #   @result = true
      #   xml_name = 'RequestMessage_1.16.5'
      #   send_to_log_egg("#{puts_line_egg}", "#{puts_line_egg}")
      #   send_to_log_egg("Начали проверку: #{menu_name}. Негативный кейс", "Начали проверку: #{menu_name}. Негативный кейс #{xml_name}")
      #   send_to_log_egg("Пытаемся найти XML в БД")
      #   xml = Xml.where(xml_name: xml_name, category_id: category.id).first
      #   raise not_find_xml if xml.nil?
      #   send_to_log_egg("Получили xml: #{xml.xml_name}\n#{xml.xml_text}")
      #   send_to_log_egg("Валидируем XML для запроса...", "Валидируем XML для запроса...")
      #   validate_egg_xml("#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd", xml.xml_text)
      #   answer = send_to_amq_and_receive_egg(manager, xml, true)
      #   raise not_receive_answer if answer.nil?
      #   send_to_log_egg("Валидируем ответную XML...", "Валидируем ответную XML...")
      #   validate_egg_xml("#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd", answer)
      #   answer_decode = get_decode_answer(answer)
      #   if answer_decode.include?('успешно')
      #     send_to_log_egg("Проверка пройдена!", "Проверка пройдена!")
      #     colorize_egg(tests_params_egg[:egg_version], menu_name, pass_menu_color) if @result
      #   else
      #     @result = false
      #     send_to_log_egg("Проверка не пройдена! Ожидаемый ответ отличается от фактического", "Проверка не пройдена!")
      #     colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
      #   end
      # rescue Exception => msg
      #   @result = false
      #   send_to_log_egg("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
      #   colorize_egg(tests_params_egg[:egg_version] , menu_name, fail_menu_color)
      # end

      begin
        sleep 1.5
        xml_name = 'RequestMessage'
        send_to_log_egg("#{puts_line_egg}", "#{puts_line_egg}")
        send_to_log_egg("Начали проверку: #{menu_name}. Позитивный кейс", "Начали проверку: #{menu_name}. Позитивный кейс #{xml_name}")
        send_to_log_egg("Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log_egg("Получили xml: #{xml.xml_name}\n#{xml.xml_text}")
        send_to_log_egg("Валидируем XML для запроса...", "Валидируем XML для запроса...")
        validate_egg_xml("#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd", xml.xml_text)
        answer = send_to_amq_and_receive_egg(manager, xml, true)
        raise not_receive_answer if answer.nil?
        send_to_log_egg("Валидируем ответную XML...", "Валидируем ответную XML...")
        validate_egg_xml("#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd", answer)
        answer_decode = get_decode_answer(answer)
        if answer_decode.include?('успешно')
          send_to_log_egg("Проверка пройдена!", "Проверка пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, pass_menu_color) if @result
        else
          @result = false
          send_to_log_egg("Проверка не пройдена! Ожидаемый ответ отличается от фактического", "Проверка не пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
        end
      rescue Exception => msg
        @result = false
        send_to_log_egg("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
        colorize_egg(tests_params_egg[:egg_version] , menu_name, fail_menu_color)
      end

      begin
        sleep 1.5
        xml_name = 'Charges'
        send_to_log_egg("#{puts_line_egg}", "#{puts_line_egg}")
        send_to_log_egg("Начали проверку: #{menu_name}. Запрос #{xml_name}", "Начали проверку: #{menu_name}. Запрос #{xml_name}")
        send_to_log_egg("Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log_egg("Получили xml: #{xml.xml_name}\n#{xml.xml_text}")
        send_to_log_egg("Валидируем XML для запроса...", "Валидируем XML для запроса...")
        validate_egg_xml("#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd", xml.xml_text)
        answer = send_to_amq_and_receive_egg(manager, xml)
        raise not_receive_answer if answer.nil?
        send_to_log_egg("Валидируем ответную XML...", "Валидируем ответную XML...")
        validate_egg_xml("#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd", answer)
        answer_decode = get_decode_answer(answer)
        answer = Document.new(answer_decode)
        if answer.elements['//pgu:ChargeData']
          send_to_log_egg("Проверка пройдена!", "Проверка пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, pass_menu_color) if @result
        else
          @result = false
          send_to_log_egg("Проверка не пройдена! Ожидаемый ответ отличается от фактического", "Проверка не пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
        end
      rescue Exception => msg
        @result = false
        send_to_log_egg("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
        colorize_egg(tests_params_egg[:egg_version] , menu_name, fail_menu_color)
      end
    end

    if components.include?('Проверка СА ГИС ЖКХ')
      menu_name = 'Проверка СА ГИС ЖКХ'
      category = Category.find_by_category_name('СА ГИС ЖКХ')
      manager = QueueManager.find_by_manager_name('iTools[EGG]')
      begin
        sleep 2
        @result = true
        xml_name = 'Payment_request'
        send_to_log_egg("#{puts_line_egg}", "#{puts_line_egg}")
        send_to_log_egg("Начали проверку: #{menu_name}. Позитивный кейс", "Начали проверку: #{menu_name}. Позитивный кейс")
        send_to_log_egg("Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log_egg("Получили xml: #{xml.xml_name}\n#{xml.xml_text}")
        decode_request = get_decode_request(xml.xml_text)
        decode_request = Document.new(decode_request)
        decode_request.elements['//tns:OrderID'].text = "1044583104000000150602900000#{Random.rand(1000...10000)}"
        xml = Document.new(xml.xml_text)
        xml.elements["//mq:Request"].text = Base64.encode64(decode_request.to_s)
        xml.elements["//mq:RequestMessage"].attributes['processID'] = SecureRandom.uuid
        send_to_log_egg("Добавили в запрос случайные ID:\n#{xml}", "Добавили в запрос случайные ID")
        send_to_log_egg("Валидируем XML для запроса...", "Валидируем XML для запроса...")
        validate_egg_xml("#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd", xml.to_s)
        answer = send_to_amq_and_receive_egg(manager, xml.to_s)
        raise not_receive_answer if answer.nil?
        send_to_log_egg("Валидируем ответную XML...", "Валидируем ответную XML...")
        validate_egg_xml("#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd", answer)
        answer_decode = get_decode_answer(answer)
        answer = Document.new(answer_decode)
        if answer.elements['//ns3:TransportID'] && answer.elements['//ns3:UpdateDate']
          send_to_log_egg("Проверка пройдена!", "Проверка пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, pass_menu_color) if @result
        else
          @result = false
          send_to_log_egg("Проверка не пройдена! Ожидаемый ответ отличается от фактического", "Проверка не пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
        end
      rescue Exception => msg
        @result = false
        send_to_log_egg("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
        colorize_egg(tests_params_egg[:egg_version] , menu_name, fail_menu_color)
      end

      begin
        sleep 2
        @result = true
        xml_name = 'Payment_Cancellation_request'
        send_to_log_egg("#{puts_line_egg}", "#{puts_line_egg}")
        send_to_log_egg("Начали проверку: #{menu_name}. Запрос отмены", "Начали проверку: #{menu_name}. Запрос отмены")
        send_to_log_egg("Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log_egg("Получили xml: #{xml.xml_name}\n#{xml.xml_text}")
        xml = Document.new(xml.xml_text)
        xml.elements["//RequestMessage"].attributes['processID'] = SecureRandom.uuid
        send_to_log_egg("Добавили в запрос случайные ID:\n#{xml}", "Добавили в запрос случайные ID")
        send_to_log_egg("Валидируем XML для запроса...", "Валидируем XML для запроса...")
        validate_egg_xml("#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd", xml.to_s)
        answer = send_to_amq_and_receive_egg(manager, xml.to_s)
        raise not_receive_answer if answer.nil?
        send_to_log_egg("Валидируем ответную XML...", "Валидируем ответную XML...")
        validate_egg_xml("#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd", answer)
        answer_decode = get_decode_answer(answer)
        answer = Document.new(answer_decode)
        if answer.elements['//ns3:TransportID']
          send_to_log_egg("Проверка пройдена!", "Проверка пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, pass_menu_color) if @result
        else
          @result = false
          send_to_log_egg("Проверка не пройдена! Ожидаемый ответ отличается от фактического", "Проверка не пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
        end
      rescue Exception => msg
        @result = false
        send_to_log_egg("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
        colorize_egg(tests_params_egg[:egg_version] , menu_name, fail_menu_color)
      end

      begin
        sleep 2
        @result = true
        xml_name = 'Payment_Details_request'
        send_to_log_egg("#{puts_line_egg}", "#{puts_line_egg}")
        send_to_log_egg("Начали проверку: #{menu_name}. Платеж с доп. атрибутами", "Начали проверку: #{menu_name}. Платеж с доп. атрибутами")
        send_to_log_egg("Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log_egg("Получили xml: #{xml.xml_name}\n#{xml.xml_text}")
        xml = Document.new(xml.xml_text)
        xml.elements["//RequestMessage"].attributes['processID'] = SecureRandom.uuid
        send_to_log_egg("Добавили в запрос случайные ID:\n#{xml}", "Добавили в запрос случайные ID")
        send_to_log_egg("Валидируем XML для запроса...", "Валидируем XML для запроса...")
        validate_egg_xml("#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd", xml.to_s)
        answer = send_to_amq_and_receive_egg(manager, xml.to_s)
        raise not_receive_answer if answer.nil?
        send_to_log_egg("Валидируем ответную XML...", "Валидируем ответную XML...")
        validate_egg_xml("#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd", answer)
        answer_decode = get_decode_answer(answer)
        answer = Document.new(answer_decode)
        if answer.elements['//ns3:Charge/ns3:PaymentDocument']
          send_to_log_egg("Проверка пройдена!", "Проверка пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, pass_menu_color) if @result
        else
          @result = false
          send_to_log_egg("Проверка не пройдена! Ожидаемый ответ отличается от фактического", "Проверка не пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
        end
      rescue Exception => msg
        @result = false
        send_to_log_egg("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
        colorize_egg(tests_params_egg[:egg_version] , menu_name, fail_menu_color)
      end
    end

    if components.include?('Проверка ИА УФЭБС (ГИС ЖКХ)')
      sleep 1.5
      menu_name = 'Проверка ИА УФЭБС (ГИС ЖКХ)'
      category = Category.find_by_category_name('ИА УФЭБС ГИС ЖКХ')
      dir_outbound = 'C:/data/inbox/GIS_ZKH/outbound'
      dir_inbound = 'C:/data/inbox/GIS_ZKH/inbound'
      begin # Справочник поставщиков
        @result = true
        send_to_log_egg("#{puts_line_egg}", "#{puts_line_egg}")
        send_to_log_egg("Начали проверку: Импорт справочника поставщиков", "Начали проверку: Импорт справочника поставщиков")
        FileUtils.cp("#{Rails.root}\\lib\\egg_autotests\\provider_catalog.csv", "C:/tmp/files/in")
        url = "jdbc:oracle:thin:@vm-corint:1521:corint"
        connection = java.sql.DriverManager.getConnection(url, "egg_autotest", "egg_autotest");
        stmt = connection.create_statement
        inn = String.new
        count = 30
        until inn == '5406562465' or count < 0
          org = stmt.execute_query("select * from zkh_inn")
          while (org.next()) do
            inn << org.getString('inn')
            puts inn
          end
          count -= 1
          sleep 1
        end
        if inn == '5406562465'
          send_to_log_egg("Проверка пройдена!", "Проверка пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, pass_menu_color) if @result
        else
          @result = false
          send_to_log_egg("Проверка не пройдена!", "Проверка не пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
        end
      rescue Exception => msg
        @result = false
        send_to_log_egg("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
        colorize_egg(tests_params_egg[:egg_version] , menu_name, fail_menu_color)
      ensure
        stmt.close
        connection.close
      end

      begin # ed101
        sleep 1.5
        @result = true
        xml_name = 'ed101'
        xml_root_element = 'ED101'
        date = Date.parse("#{Random.rand(2010..2017)}-#{Random.rand(1..11)}-#{Random.rand(1..28)}")
        send_to_log_egg("#{puts_line_egg}", "#{puts_line_egg}")
        send_to_log_egg("Начали проверку: #{menu_name}. #{xml_name}", "Начали проверку: #{menu_name}. #{xml_name}")
        send_to_log_egg("Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log_egg("Получили xml: #{xml.xml_name}\n#{xml.xml_text}")
        xml = Document.new(xml.xml_text)
        xml.elements["//#{xml_root_element}"].attributes['EDNo'] = Random.rand(1000..50000)
        xml.elements["//#{xml_root_element}"].attributes['EDDate'] = date
        send_to_log_egg("Валидируем XML для запроса...", "Валидируем XML для запроса...")
        validate_egg_xml("#{Rails.root}/lib/egg_autotests/xsd/ufebs_file/cbr_#{xml_name}_v2018.1.1.xsd", xml.to_s)
        FileUtils.rm_r dir_inbound if File.directory?(dir_inbound)# Чистим каталог для получения
        send_to_log_egg("Удалили каталог #{dir_inbound}...")
        File.open("#{dir_outbound}/#{xml_name}.xml", 'w'){ |file| file.write xml.to_s }
        send_to_log_egg("Положили запрос в каталог #{dir_outbound}", "Положили запрос в каталог #{dir_outbound}")
        answer = ufebs_file_count(false, 'gis_zkh')
        if answer.first == 1 and answer.last == 1
          send_to_log_egg("Проверка пройдена!", "Проверка пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, pass_menu_color) if @result
        elsif answer.first == 0 and answer.last == 0
          @result = false
          send_to_log_egg("Проверка не пройдена! Не получили ответ от eGG", "Проверка не пройдена! Не получили ответ от eGG")
          colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
        elsif answer.first == 1 and answer.last == 0
          @result = false
          send_to_log_egg("Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус", "Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус")
          colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
        end
      rescue Exception => msg
        @result = false
        send_to_log_egg("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
        colorize_egg(tests_params_egg[:egg_version] , menu_name, fail_menu_color)
      end

      begin # ed108
        sleep 1.5
        xml_name = 'ed108'
        xml_root_element = 'ED108'
        date = Date.parse("#{Random.rand(2010..2017)}-#{Random.rand(1..11)}-#{Random.rand(1..28)}")
        send_to_log_egg("#{puts_line_egg}", "#{puts_line_egg}")
        send_to_log_egg("Начали проверку: #{menu_name}. #{xml_name}", "Начали проверку: #{menu_name}. #{xml_name}")
        send_to_log_egg("Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log_egg("Получили xml: #{xml.xml_name}\n#{xml.xml_text}")
        xml = Document.new(xml.xml_text)

        xml.elements["//#{xml_root_element}"].attributes['EDNo'] = Random.rand(1000..50000)
        xml.elements["//#{xml_root_element}"].attributes['ChargeOffDate'] = date
        xml.elements["//#{xml_root_element}"].attributes['EDDate'] = date
        #xml.elements["//#{xml_root_element}"].attributes['FileDate'] = date
        xml.elements["//#{xml_root_element}"].attributes['ReceiptDate'] = date
        xml.elements["//AccDoc"].attributes['AccDocDate'] = date
        xml.elements["//CreditTransferTransactionInfo"].attributes['PayerDocDate'] = date
        xml.elements["//CreditTransferTransactionInfo"].attributes['TransactionDate'] = date

        send_to_log_egg("Валидируем XML для запроса...", "Валидируем XML для запроса...")
        validate_egg_xml("#{Rails.root}/lib/egg_autotests/xsd/ufebs_file/cbr_#{xml_name}_v2018.1.1.xsd", xml.to_s)
        FileUtils.rm_r dir_inbound if File.directory?(dir_inbound)# Чистим каталог для получения
        send_to_log_egg("Удалили каталог #{dir_inbound}'...")
        File.open("#{dir_outbound}/#{xml_name}.xml", 'w'){ |file| file.write xml.to_s }
        send_to_log_egg("Положили запрос в каталог #{dir_outbound}", "Положили запрос в каталог #{dir_outbound}")
        answer = ufebs_file_count(false, 'gis_zkh')
        if answer.first == 1 and answer.last == 1
          send_to_log_egg("Проверка пройдена!", "Проверка пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, pass_menu_color) if @result
        elsif answer.first == 0 and answer.last == 0
          @result = false
          send_to_log_egg("Проверка не пройдена! Не получили ответ от eGG", "Проверка не пройдена! Не получили ответ от eGG")
          colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
        elsif answer.first == 1 and answer.last == 0
          @result = false
          send_to_log_egg("Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус", "Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус")
          colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
        end
      rescue Exception => msg
        @result = false
        send_to_log_egg("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
        colorize_egg(tests_params_egg[:egg_version] , menu_name, fail_menu_color)
      end

      begin # packetepd
        sleep 1.5
        xml_name = 'packetepd'
        xml_root_element = 'PacketEPD'
        #date = Date.parse("#{Random.rand(2010..2017)}-#{Random.rand(1..11)}-#{Random.rand(1..28)}")
        send_to_log_egg("#{puts_line_egg}", "#{puts_line_egg}")
        send_to_log_egg("Начали проверку: #{menu_name}. #{xml_name}", "Начали проверку: #{menu_name}. #{xml_name}")
        send_to_log_egg("Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log_egg("Получили xml: #{xml.xml_name}\n#{xml.xml_text}")
        xml = Document.new(xml.xml_text)
        xml.elements["//#{xml_root_element}"].attributes['EDNo'] = Random.rand(1000..50000)
        xml.elements["//ED101"].attributes['EDNo'] = Random.rand(1000..50000)
        xml.elements["//ED108"].attributes['EDNo'] = Random.rand(1000..50000)

        xml.elements["//ED108"].attributes['ChargeOffDate'] = date
        xml.elements["//ED108"].attributes['EDDate'] = date
        #xml.elements["//#{xml_root_element}"].attributes['FileDate'] = date
        xml.elements["//ED108"].attributes['ReceiptDate'] = date
        xml.elements["//AccDoc"].attributes['AccDocDate'] = date
        xml.elements["//CreditTransferTransactionInfo"].attributes['PayerDocDate'] = date
        xml.elements["//CreditTransferTransactionInfo"].attributes['TransactionDate'] = date
        send_to_log_egg("Валидируем XML для запроса...", "Валидируем XML для запроса...")
        validate_egg_xml("#{Rails.root}/lib/egg_autotests/xsd/ufebs_file/cbr_#{xml_name}_v2018.1.1.xsd", xml.to_s)
        FileUtils.rm_r dir_inbound if File.directory?(dir_inbound)# Чистим каталог для получения
        send_to_log_egg("Удалили каталог #{dir_inbound}'...")
        File.open("#{dir_outbound}/#{xml_name}.xml", 'w'){ |file| file.write xml.to_s }
        send_to_log_egg("Положили запрос в каталог #{dir_outbound}", "Положили запрос в каталог #{dir_outbound}")
        answer = ufebs_file_count(true, 'gis_zkh')
        if answer.first == 2 and answer.last == 2
          send_to_log_egg("Проверка пройдена!", "Проверка пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, pass_menu_color) if @result
        elsif answer.first == 0 and answer.last == 0
          @result = false
          send_to_log_egg("Проверка не пройдена! Не получили ответ от eGG", "Проверка не пройдена! Не получили ответ от eGG")
          colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
        elsif answer.first == 1 and answer.last == 0
          @result = false
          send_to_log_egg("Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус", "Проверка не пройдена! Получили квиток от eGG, но не получили финальный статус")
          colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
        else
          @result = false
          send_to_log_egg("Проверка не пройдена!", "Проверка не пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
        end
      rescue Exception => msg
        @result = false
        send_to_log_egg("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
        colorize_egg(tests_params_egg[:egg_version] , menu_name, fail_menu_color)
      end
    end
  end
end