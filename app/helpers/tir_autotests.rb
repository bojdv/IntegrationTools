include TirAutoTestsHelper
require 'rexml/document'
include REXML

module TirAutotests

  def runTest(components)
    # Переменные для всех тестов
    pass_menu_color = '#b3ffcc'
    fail_menu_color = '#ff3333'
    not_find_xml = 'XML не найдена'
    not_receive_answer = 'Не получили ответ от ТИР:('

    if components.include?('Проверка адаптера Active MQ')
      menu_name = 'Проверка адаптера Active MQ'
      category = Category.find_by_category_name('Адаптер Active MQ')
      xml_name = 'Автотест для адаптера БД'
      manager = QueueManager.find_by_manager_name('TIR (vm-corint)')
      begin
        send_to_log("#{puts_line}", "#{puts_line}")
        send_to_log("Начали проверку: #{menu_name}", "Начали проверку: #{xml_name}")
        send_to_log("Пытаемся получить XML")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log("Получили xml: #{xml.xml_name}")
        answer = send_to_amq(manager, xml)
        raise not_receive_answer if answer.nil?
        answer = Document.new(answer)
        if answer.elements['//p:Ticket'].attributes['statusStateCode'] == 'ACCEPTED_BY_ABS'
          send_to_log("Проверка пройдена!", "Проверка пройдена!")
          colorize(menu_name, pass_menu_color)
        else
          send_to_log("Проверка не пройдена! Ожидаемый статус отличается от фактического", "Проверка не пройдена!")
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
        send_to_log("Пытаемся получить XML")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise not_find_xml if xml.nil?
        send_to_log("Получили xml: #{xml.xml_name}")
        answer = send_to_amq(manager, xml)
        raise not_receive_answer if answer.nil?
        answer = Document.new(answer)
        if answer.elements['//p:Ticket'].attributes['statusStateCode'] == 'ACCEPTED_BY_ABS'
          send_to_log("Проверка пройдена!", "Проверка пройдена!")
          colorize(menu_name, pass_menu_color)
        else
          send_to_log("Проверка не пройдена! Ожидаемый статус отличается от фактического", "Проверка не пройдена!")
          colorize(menu_name, fail_menu_color)
        end
      rescue Exception => msg
        send_to_log("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}", "Ошибка! #{msg}")
        colorize(menu_name, '#ff3333')
      end
    end
  end
end