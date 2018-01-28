include TirAutoTestsHelper
require 'rexml/document'
include REXML
require 'savon'

module TirAutotests

  def runTest(components)
    # Переменные для всех тестов
    pass_menu_color = '#b3ffcc'
    fail_menu_color = '#ff3333'
    not_find_xml = 'XML не найдена'
    not_receive_answer = 'Не получили ответ от ТИР:('
    send_to_tir_error = 'Ошибка при отправке в ТИР'

    if components.include?('Проверка адаптера Active MQ')
      menu_name = 'Проверка адаптера Active MQ'
      category = Category.find_by_category_name('Адаптер Active MQ')
      xml_name = 'Автотест для адаптера БД'
      manager = QueueManager.find_by_manager_name('TIR (vm-corint)')
      begin
        send_to_log("#{puts_line}", "#{puts_line}")
        send_to_log("Начали проверку: #{menu_name}", "Начали проверку: #{xml_name}")
        send_to_log("Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log("Получили xml: #{xml.xml_name}")
        answer = send_to_amq_and_receive(manager, xml)
        raise not_receive_answer if answer.nil?
        answer = Document.new(answer)
        if answer.elements['//p:Ticket'].attributes['statusStateCode'] == 'ACCEPTED_BY_ABS'
          send_to_log("Проверка пройдена!", "Проверка пройдена!")
          colorize(menu_name, pass_menu_color)
        else
          send_to_log("Проверка не пройдена! Ожидаемый ответ отличается от фактического", "Проверка не пройдена!")
          colorize(menu_name, fail_menu_color)
        end
      rescue Exception => msg
        send_to_log("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
        colorize(menu_name, '#ff3333')
      end
    end

    if components.include?('Проверка компонента БД')
      menu_name = 'Проверка компонента БД'
      category = Category.find_by_category_name('Компонент БД')
      xml_name = 'Автотест для компонента БД'
      manager = QueueManager.find_by_manager_name('TIR (vm-corint)')
      begin
        send_to_log("#{puts_line}", "#{puts_line}")
        send_to_log("Начали проверку: #{menu_name}", "Начали проверку: #{xml_name}")
        send_to_log("Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log("Получили xml: #{xml.xml_name}")
        answer = send_to_amq_and_receive(manager, xml)
        raise not_receive_answer if answer.nil?
        answer = Document.new(answer)
        if answer.elements['//p:Ticket'].attributes['statusStateCode'] == 'ACCEPTED_BY_ABS'
          send_to_log("Проверка пройдена!", "Проверка пройдена!")
          colorize(menu_name, pass_menu_color)
        else
          send_to_log("Проверка не пройдена! Ожидаемый ответ отличается от фактического", "Проверка не пройдена!")
          colorize(menu_name, fail_menu_color)
        end
      rescue Exception => msg
        send_to_log("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
        colorize(menu_name, '#ff3333')
      end
    end

    if components.include?('Проверка компонента трансформации')
      menu_name = 'Проверка компонента трансформации'
      category = Category.find_by_category_name('Компонент трансформации')
      xml_name = 'Проверка трансформации'
      manager = QueueManager.find_by_manager_name('TIR (vm-corint)')
      begin
        send_to_log("#{puts_line}", "#{puts_line}")
        send_to_log("Начали проверку: #{menu_name}", "Начали проверку: #{xml_name}")
        send_to_log("Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log("Получили xml: #{xml.xml_name}")
        answer = send_to_amq_and_receive(manager, xml)
        raise not_receive_answer if answer.nil?
        answer = Document.new(answer)
        if answer.elements['//p:Ticket'].attributes['statusStateCode'] == 'ACCEPTED_BY_ABS'
          send_to_log("Проверка пройдена!", "Проверка пройдена!")
          colorize(menu_name, pass_menu_color)
        else
          send_to_log("Проверка не пройдена! Ожидаемый ответ отличается от фактического", "Проверка не пройдена!")
          colorize(menu_name, fail_menu_color)
        end
      rescue Exception => msg
        send_to_log("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
        colorize(menu_name, '#ff3333')
      end
    end

    if components.include?('Проверка компонента File')
      menu_name = 'Проверка компонента File'
      category = Category.find_by_category_name('Компонент File')
      xml_name_to_ABS = 'Проверка получения файла из каталога. Запрос в АБС'
      xml_name_from_ABS = 'Проверка получения файла из каталога. Ответ от АБС'
      manager = QueueManager.find_by_manager_name('TIR (vm-corint)')
      begin
        send_to_log("#{puts_line}", "#{puts_line}")
        send_to_log("Начали проверку: #{menu_name}", "Начали проверку: #{xml_name}")
        send_to_log("Пытаемся найти XML в БД")
        xml_to_abs = Xml.where(xml_name: xml_name_to_ABS, category_id: category.id).first
        xml_from_abs = Xml.where(xml_name: xml_name_from_ABS, category_id: category.id).first
        raise not_find_xml if xml_to_abs.nil? || xml_from_abs.nil?
        send_to_log("Получили xml для отправки в АБС: #{xml_to_abs.xml_name}")
        send_to_log("Получили xml для ответа от АБС: #{xml_from_abs.xml_name}")
        answer = send_to_amq(manager, xml_to_abs)
        raise send_to_tir_error if answer.nil?
        File.open('\\\\vm-corint\\Gates\\Omega\\in_status_autotest\\STATUS_CURRBUY_160420091010.xml', 'w'){ |file| file.write xml_from_abs.xml_text }
        send_to_log("Подложили ответ от АБС в каталог ТИР:\n#{xml_from_abs.xml_text}", "Подложили ответ от АБС в каталог ТИР")
        answer = receive_from_amq(manager)
        raise not_receive_answer if answer.nil?
        answer = Document.new(answer)
        if answer.elements['//p:Ticket'].attributes['statusStateCode'] == 'PROCESSED'
          send_to_log("Проверка пройдена!", "Проверка пройдена!")
          colorize(menu_name, pass_menu_color)
        else
          send_to_log("Проверка не пройдена! Ожидаемый ответ отличается от фактического", "Проверка не пройдена!")
          colorize(menu_name, fail_menu_color)
        end
      rescue Exception => msg
        send_to_log("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
        colorize(menu_name, '#ff3333')
      end
    end

    if components.include?('Проверка адаптера HTTP')
      menu_name = 'Проверка адаптера HTTP'
      category = Category.find_by_category_name('Адаптер HTTP')
      xml_name = 'Проверка HTTP адаптера'
      manager = QueueManager.find_by_manager_name('TIR (vm-corint)')
      endpoint = 'http://vm-corint:3333/httpadapter'
      begin
        send_to_log("#{puts_line}", "#{puts_line}")
        send_to_log("Начали проверку: #{menu_name}", "Начали проверку: #{xml_name}")
        send_to_log("Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml_name.nil?
        send_to_log("Получили xml для отправки в АБС: #{xml.xml_name}")
        soap_client = Savon.client do
          endpoint endpoint
          namespace 'http://WSCFT_Dispatcher.ws.nordea.ru'
        end
        request = soap_client.call(:do_cft_dispatcher, xml: xml.xml_text) #Кидаем запрос в ТИР
        raise 'Недоступен HTTP адаптер ТИР' if request.nil?
        send_to_log("Отправили HTTP запрос в ТИР по адресу: #{endpoint}:\n#{xml.xml_text}", "Отправили HTTP запрос в ТИР по адресу: #{endpoint}")
        answer = receive_from_amq(manager)
        raise not_receive_answer if answer.nil?
        answer = Document.new(answer)
        if answer.elements['//ShortName'].text == 'ООО "ЛАНТЕР"'
          send_to_log("Проверка пройдена!", "Проверка пройдена!")
          colorize(menu_name, pass_menu_color)
        else
          send_to_log("Проверка не пройдена! Ожидаемый ответ отличается от фактического", "Проверка не пройдена!")
          colorize(menu_name, fail_menu_color)
        end
      rescue Exception => msg
        send_to_log("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
        colorize(menu_name, '#ff3333')
      end
    end

    if components.include?('Проверка компонента Active MQ')
      menu_name = 'Проверка компонента Active MQ'
      category = Category.find_by_category_name('Компонент Active MQ')
      xml_name_to_ABS = 'Проверка компонента Active MQ. Запрос в АБС'
      xml_name_from_ABS = 'Проверка компонента Active MQ. Ответ от АБС'
      abs_queue_in = 'szvABS_out'
      manager = QueueManager.find_by_manager_name('TIR (vm-corint)')
      begin
        send_to_log("#{puts_line}", "#{puts_line}")
        send_to_log("Начали проверку: #{menu_name}", "Начали проверку: #{menu_name}")
        send_to_log("Пытаемся найти XML в БД")
        xml_to_abs = Xml.where(xml_name: xml_name_to_ABS, category_id: category.id).first
        xml_from_abs = Xml.where(xml_name: xml_name_from_ABS, category_id: category.id).first
        raise not_find_xml if xml_to_abs.nil? || xml_from_abs.nil?
        send_to_log("Получили xml для отправки в АБС: #{xml_to_abs.xml_name}")
        send_to_log("Получили xml для ответа от АБС: #{xml_from_abs.xml_name}")
        answer = send_to_amq_and_receive(manager, xml_to_abs)
        raise send_to_tir_error if answer.nil?
        requestFromTIRtoXML = Document.new(answer)
        answer = Document.new(xml_from_abs.xml_text)
        answer.elements['//ns1:BSMessage'].attributes['ID'] = requestFromTIRtoXML.elements['//ns0:BSMessage'].attributes['ID']
        answer_from_abs = send_to_amq(manager, answer.to_s, abs_queue_in)
        raise send_to_tir_error if answer_from_abs.nil?
        send_to_log("Обработали запрос #{requestFromTIRtoXML.elements['//ns0:BSMessage'].attributes['xmlns:ns0']} из очереди szvABS_in с ID = #{requestFromTIRtoXML.elements['//ns0:BSMessage'].attributes['ID']}", "Обработали запрос #{requestFromTIRtoXML.elements['//ns0:BSMessage'].attributes['xmlns:ns0']} из очереди szvABS_in с ID = #{requestFromTIRtoXML.elements['//ns0:BSMessage'].attributes['ID']}")
        answer = receive_from_amq(manager)
        raise not_receive_answer if answer.nil?
        answer = Document.new(answer)
        if answer.elements['//state'].text == 'ACCEPTED_BY_ABS'
          send_to_log("Проверка пройдена!", "Проверка пройдена!")
          colorize(menu_name, pass_menu_color)
        else
          send_to_log("Проверка не пройдена! Ожидаемый ответ отличается от фактического", "Проверка не пройдена!")
          colorize(menu_name, fail_menu_color)
        end
      rescue Exception => msg
        send_to_log("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
        colorize(menu_name, '#ff3333')
      end
    end

    if components.include?('Проверка компонента WebServiceProxy')
      menu_name = 'Проверка компонента WebServiceProxy'
      category = Category.find_by_category_name('Компонент WebServiceProxy')
      xml_name = 'Проверка компонента WebServiceProxy'
      manager = QueueManager.find_by_manager_name('TIR (vm-corint)')
      begin
        send_to_log("#{puts_line}", "#{puts_line}")
        send_to_log("Начали проверку: #{menu_name}", "Начали проверку: #{xml_name}")
        send_to_log("Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log("Получили xml: #{xml.xml_name}")
        answer = send_to_amq_and_receive(manager, xml)
        raise not_receive_answer if answer.nil?
        answer = Document.new(answer)
        if answer.elements['//cqa:data']
          send_to_log("Проверка пройдена!", "Проверка пройдена!")
          colorize(menu_name, pass_menu_color)
        else
          send_to_log("Проверка не пройдена! Ожидаемый ответ отличается от фактического", "Проверка не пройдена!")
          colorize(menu_name, fail_menu_color)
        end
      rescue Exception => msg
        send_to_log("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
        colorize(menu_name, '#ff3333')
      end
    end

    if components.include?('Проверка компонента Base64 (WebServiceProxy)')
      menu_name = 'Проверка компонента Base64 (WebServiceProxy)'
      category = Category.find_by_category_name('Компонент Base64 (WebServiceProxy)')
      xml_name = 'Проверка компонента Base64'
      manager = QueueManager.find_by_manager_name('TIR (vm-corint)')
      begin
        send_to_log("#{puts_line}", "#{puts_line}")
        send_to_log("Начали проверку: #{menu_name}", "Начали проверку: #{xml_name}")
        send_to_log("Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log("Получили xml: #{xml.xml_name}")
        answer = send_to_amq_and_receive(manager, xml)
        raise not_receive_answer if answer.nil?
        answer = Document.new(answer)
        if answer.elements['//cqa:data']
          send_to_log("Проверка пройдена!", "Проверка пройдена!")
          colorize(menu_name, pass_menu_color)
        else
          send_to_log("Проверка не пройдена! Ожидаемый ответ отличается от фактического", "Проверка не пройдена!")
          colorize(menu_name, fail_menu_color)
        end
      rescue Exception => msg
        send_to_log("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
        colorize(menu_name, '#ff3333')
      end
    end
  end
end