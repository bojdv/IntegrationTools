include TirAutoTestsHelper
require 'rexml/document'
include REXML

module TirAutotests

  def runTest(components)
    # Переменные для всех тестов
    pass_menu_color = '#b3ffcc'
    fail_menu_color = '#ff3333'
    not_find_xml = 'XML не найдена'
    not_reseive_answer = 'Не получили ответ от ТИР:('
    category_id = '10008'

    if components.include?('Проверка адаптера БД')
      menu_name = 'Проверка адаптера БД'
      xml_name = 'Автотест для адаптера БД'
      manager_id = 10042
      begin
        send_to_log("Начали проверку: #{menu_name}")
        $log.info("Пытаемся получить XML")
        xml = Xml.where(xml_name: xml_name, category_id: category_id).first
        raise not_find_xml if xml.nil?
        $log.info("Получили xml: #{xml.xml_name}")
        manager = QueueManager.find(manager_id)
        $log.info("Получили менеджера очередей: #{manager.manager_name}")
        answer = send_to_amq(manager, xml)
        raise not_reseive_answer if answer.nil?
        answer = Document.new(answer)
        if answer.elements['//p:Ticket'].attributes['statusStateCode'] == 'ACCEPTED_BY_ABS'
          send_to_log("Проверка пройдена!")
          colorize(menu_name, pass_menu_color)
        else
          send_to_log("Проверка не пройдена!")
          colorize(menu_name, fail_menu_color)
        end
      rescue Exception => msg
        #send_to_log("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}")
        send_to_log("Ошибка! #{msg}")
        $log.error(msg)
        colorize(menu_name, '#ff3333')
      end
    end
    if components.include?('Проверка адаптера Active MQ')
      menu_name = 'Проверка адаптера Active MQ'
      xml_name = 'Автотест для адаптера БД'
      manager_id = 10042
      begin
        send_to_log("#{puts_line}")
        send_to_log("Начали проверку: #{menu_name}")
        xml = Xml.where(xml_name: xml_name, category_id: category_id).first
        raise not_find_xml if xml.nil?
        manager = QueueManager.find(manager_id)
        answer = send_to_amq(manager, xml)
        raise not_reseive_answer if answer.nil?
        answer = Document.new(answer)
        if answer.elements['//p:Ticket'].attributes['statusStateCode'] == 'ACCEPTED_BY_ABS'
          send_to_log("Проверка пройдена!")
          colorize(menu_name, pass_menu_color)
        else
          send_to_log("Проверка не пройдена!")
          colorize(menu_name, fail_menu_color)
        end
      rescue Exception => msg
        #send_to_log("Ошибка! #{msg}\n#{msg.backtrace.join("\n")}")
        send_to_log("Ошибка! #{msg}")
        colorize(menu_name, '#ff3333')
        send_to_log("#{puts_line}")
      end
    end
  end
end