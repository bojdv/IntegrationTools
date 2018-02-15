include EggAutoTestsHelper
require 'rexml/document'
include REXML
require 'savon'

module EggAutotests

  def runTest_egg(components)
    # Переменные для всех тестов
    pass_menu_color = '#b3ffcc'
    fail_menu_color = '#ff3333'
    not_find_xml = 'XML не найдена'
    not_receive_answer = 'Не получили ответ от eGG:('

    if components.include?('Проверка ИА Active MQ')
      sleep 0.5
      menu_name = 'Проверка ИА Active MQ'
      category = Category.find_by_category_name('ИА Active MQ')
      xml_name = 'RequestMessage'
      manager = QueueManager.find_by_manager_name('iTools[EGG]')
      begin
        send_to_log_egg("#{puts_line_egg}", "#{puts_line_egg}")
        send_to_log_egg("Начали проверку: #{menu_name}", "Начали проверку: #{menu_name}")
        send_to_log_egg("Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log_egg("Получили xml: #{xml.xml_name}")
        send_to_log_egg("Валидируем XML для запроса...", "Валидируем XML для запроса...")
        validate_egg_xml("#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd", xml.xml_text)
        answer = send_to_amq_and_receive_egg(manager, xml, true)
        raise not_receive_answer if answer.nil?
        send_to_log_egg("Валидируем ответную XML...", "Валидируем ответную XML...")
        validate_egg_xml("#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd", answer)
        answer_decode = get_decode_answer(answer)
        if answer_decode.include?('Импортируемые данные уже присутствуют в Системе')
          send_to_log_egg("Проверка пройдена!", "Проверка пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, pass_menu_color)
        else
          send_to_log_egg("Проверка не пройдена! Ожидаемый ответ отличается от фактического", "Проверка не пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
        end
      rescue Exception => msg
        send_to_log_egg("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
        colorize_egg(tests_params_egg[:egg_version] , menu_name, fail_menu_color)
      end
    end

    if components.include?('Проверка ИА УФЭБС (File)')
      sleep 0.5
      menu_name = 'Проверка ИА УФЭБС (File)'
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
        send_to_log_egg("Получили xml: #{xml.xml_name}")
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
        xml_name = 'ed104'
        xml_root_element = 'ED104'
        send_to_log_egg("#{puts_line_egg}", "#{puts_line_egg}")
        send_to_log_egg("Начали проверку: #{menu_name}. #{xml_name}", "Начали проверку: #{menu_name}. #{xml_name}")
        send_to_log_egg("Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log_egg("Получили xml: #{xml.xml_name}")
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
        xml_name = 'ed105'
        xml_root_element = 'ED105'
        send_to_log_egg("#{puts_line_egg}", "#{puts_line_egg}")
        send_to_log_egg("Начали проверку: #{menu_name}. #{xml_name}", "Начали проверку: #{menu_name}. #{xml_name}")
        send_to_log_egg("Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log_egg("Получили xml: #{xml.xml_name}")
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
        xml_name = 'ed108'
        xml_root_element = 'ED108'
        date = Date.parse("#{Random.rand(2010..2017)}-#{Random.rand(1..11)}-#{Random.rand(1..28)}")
        send_to_log_egg("#{puts_line_egg}", "#{puts_line_egg}")
        send_to_log_egg("Начали проверку: #{menu_name}. #{xml_name}", "Начали проверку: #{menu_name}. #{xml_name}")
        send_to_log_egg("Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log_egg("Получили xml: #{xml.xml_name}")
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
        xml_name = 'packetepd'
        xml_root_element = 'PacketEPD'
        date = Date.parse("#{Random.rand(2010..2017)}-#{Random.rand(1..11)}-#{Random.rand(1..28)}")
        send_to_log_egg("#{puts_line_egg}", "#{puts_line_egg}")
        send_to_log_egg("Начали проверку: #{menu_name}. #{xml_name}", "Начали проверку: #{menu_name}. #{xml_name}")
        send_to_log_egg("Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log_egg("Получили xml: #{xml.xml_name}")
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
      begin
        @result = true
        xml_name = 'RequestMessage_1.16.5'
        send_to_log_egg("#{puts_line_egg}", "#{puts_line_egg}")
        send_to_log_egg("Начали проверку: #{menu_name}. Негативный кейс", "Начали проверку: #{menu_name}. Негативный кейс")
        send_to_log_egg("Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log_egg("Получили xml: #{xml.xml_name}")
        send_to_log_egg("Валидируем XML для запроса...", "Валидируем XML для запроса...")
        validate_egg_xml("#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd", xml.xml_text)
        answer = send_to_amq_and_receive_egg(manager, xml, true)
        raise not_receive_answer if answer.nil?
        send_to_log_egg("Валидируем ответную XML...", "Валидируем ответную XML...")
        validate_egg_xml("#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd", answer)
        answer_decode = get_decode_answer(answer)
        if answer_decode.include?('Не указано основание уточнения')
          send_to_log_egg("Проверка пройдена!", "Проверка пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, pass_menu_color) if @result
        else
          @result = false
          send_to_log_egg("Проверка не пройдена! Ожидаемый ответ отличается от фактического", "Проверка не пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
        end
      rescue Exception => msg
        send_to_log_egg("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
        colorize_egg(tests_params_egg[:egg_version] , menu_name, fail_menu_color)
      end

      begin
        xml_name = 'RequestMessage'
        send_to_log_egg("#{puts_line_egg}", "#{puts_line_egg}")
        send_to_log_egg("Начали проверку: #{menu_name}. Позитивный кейс", "Начали проверку: #{menu_name}. Позитивный кейс")
        send_to_log_egg("Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log_egg("Получили xml: #{xml.xml_name}")
        send_to_log_egg("Валидируем XML для запроса...", "Валидируем XML для запроса...")
        validate_egg_xml("#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd", xml.xml_text)
        answer = send_to_amq_and_receive_egg(manager, xml, true)
        raise not_receive_answer if answer.nil?
        send_to_log_egg("Валидируем ответную XML...", "Валидируем ответную XML...")
        validate_egg_xml("#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd", answer)
        answer_decode = get_decode_answer(answer)
        if answer_decode.include?('Импортируемые данные уже присутствуют в Системе')
          send_to_log_egg("Проверка пройдена!", "Проверка пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, pass_menu_color) if @result
        else
          @result = false
          send_to_log_egg("Проверка не пройдена! Ожидаемый ответ отличается от фактического", "Проверка не пройдена!")
          colorize_egg(tests_params_egg[:egg_version], menu_name, fail_menu_color)
        end
      rescue Exception => msg
        send_to_log_egg("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
        colorize_egg(tests_params_egg[:egg_version] , menu_name, fail_menu_color)
      end

      begin
        xml_name = 'Charges'
        send_to_log_egg("#{puts_line_egg}", "#{puts_line_egg}")
        send_to_log_egg("Начали проверку: #{menu_name}. Запрос #{xml_name}", "Начали проверку: #{menu_name}. Запрос #{xml_name}")
        send_to_log_egg("Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log_egg("Получили xml: #{xml.xml_name}")
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
        send_to_log_egg("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
        colorize_egg(tests_params_egg[:egg_version] , menu_name, fail_menu_color)
      end
    end
  end
end