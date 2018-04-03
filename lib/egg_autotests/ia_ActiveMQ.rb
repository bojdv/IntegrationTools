require "#{Rails.root}/lib/egg_autotests/egg_autotests_list.rb"

class IA_ActiveMQ < EggAutotestsList

  def initialize
  end

  def run_RequestMessage
    sleep 1.5
    menu_name = 'Проверка ИА Active MQ'
    category = Category.find_by_category_name('ИА Active MQ')
    xml_name = 'RequestMessage'
    manager = QueueManager.find_by_manager_name('iTools[EGG]')
    functional = "Проверка адаптера Active MQ"
    begin
      $log_egg.write_to_log(functional, "Начали проверку в #{Time.now.strftime('%H-%M-%S')}", "#{menu_name}")
      $log_egg.write_to_browser("#{puts_line_egg}")
      $log_egg.write_to_browser("Начали проверку: #{menu_name}")
      $log_egg.write_to_browser("Пытаемся найти XML в БД")
      $log_egg.write_to_log(functional, "Пытаемся найти XML в БД")
      xml = Xml.where(xml_name: xml_name, category_id: category.id).first
      raise @@not_find_xml if xml.nil?
      $log_egg.write_to_log(functional, "Получили xml", "#{xml.xml_name}\n#{xml.xml_text}")
      xsd = "#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd"
      $log_egg.write_to_browser("Валидируем XML для запроса...")
      $log_egg.write_to_log(functional, "Валидация исходящей XML", "Валидируем XML для запроса:\n#{xml.xml_name}\nПо XSD:\n #{xsd}")
      validate_egg_xml(xsd, xml.xml_text, functional)
      answer = send_to_amq_and_receive_egg(manager, xml, functional, true)
      raise @@not_receive_answer if answer.nil?
      $log_egg.write_to_browser("Валидируем ответную XML...")
      $log_egg.write_to_log(functional, "Валидируем ответную XML", "Валидируем ответную XML:\n#{answer}\nПо XSD:\n #{xsd}")
      validate_egg_xml(xsd, answer, functional)
      answer_decode = get_decode_answer(answer)
      $log_egg.write_to_browser("Раскодировали ответ!")
      $log_egg.write_to_log(functional, "Раскодированный тег Answer", "#{answer_decode}")
      expected_result = 'Импортируемые данные уже присутствуют в Системе'
      if answer_decode.include?(expected_result)
        $log_egg.write_to_browser("Проверка пройдена!")
        $log_egg.write_to_log(functional, "Проверка пройдена!", "Done! Ответ содержит в себе значение: #{expected_result}")
        colorize_egg(@@egg_version, menu_name, @@pass_menu_color)
      else
        $log_egg.write_to_browser("Проверка не пройдена!")
        $log_egg.write_to_log(functional, "Проверка не пройдена!", "Ответ не содержит в себе значение: #{expected_result}")
        colorize_egg(@@egg_version, menu_name, @@fail_menu_color)
      end
    rescue Exception => msg
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log(functional, "Ошибка при выполнении проверки!", "#{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@@egg_version , menu_name, @@fail_menu_color)
    ensure
    end
  end
end