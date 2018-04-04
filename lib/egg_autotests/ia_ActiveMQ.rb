#require "#{Rails.root}/lib/egg_autotests/egg_autotests_list.rb"

class IA_ActiveMQ

  def initialize(pass_menu_color, fail_menu_color, not_find_xml, not_receive_answer, egg_version, try_count)
    @pass_menu_color = pass_menu_color
    @fail_menu_color = fail_menu_color
    @not_find_xml = not_find_xml
    @not_receive_answer = not_receive_answer
    @egg_version = egg_version
    @try_count = try_count
    @result = Hash.new
    @functional = "Проверка адаптера СА ГИС ГМП"
  end

  def run_RequestMessage
    sleep 1.5
    menu_name = 'Проверка ИА Active MQ'
    category = Category.find_by_category_name('ИА Active MQ')
    xml_name = 'Payment_новый'
    manager = QueueManager.find_by_manager_name('iTools[EGG]')
    begin
      count = 1
      until @result["run_RequestMessage"] == "true" or count > 3
        functional = "#{@functional}. #{xml_name}. Попытка #{count}"
        $log_egg.write_to_log(functional, "Начали проверку в #{Time.now.strftime('%H-%M-%S')}", "#{menu_name}")
        $log_egg.write_to_browser("#{puts_line_egg}")
        $log_egg.write_to_browser("Начали проверку: #{menu_name}. Попытка #{count}")
        $log_egg.write_to_browser("Пытаемся найти XML в БД")
        $log_egg.write_to_log(functional, "Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first
        raise @not_find_xml if xml.nil?
        $log_egg.write_to_log(functional, "Получили xml", "#{xml.xml_name}\n#{xml.xml_text}")
        xsd = "#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd"
        $log_egg.write_to_browser("Валидируем XML для запроса...")
        $log_egg.write_to_log(functional, "Валидация исходящей XML", "Валидируем XML для запроса:\n#{xml.xml_name}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, xml.xml_text, functional)
        answer = send_to_amq_and_receive_egg(manager, xml, functional, true)
        next count +=1  if answer.nil?
        $log_egg.write_to_browser("Валидируем ответную XML...")
        $log_egg.write_to_log(functional, "Валидируем ответную XML", "Валидируем ответную XML:\n#{answer}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, answer, functional)
        answer_decode = get_decode_answer(answer)
        $log_egg.write_to_browser("Раскодировали ответ!")
        $log_egg.write_to_log(functional, "Раскодированный тег Answer", "#{answer_decode}")
        expected_result = 'Импортируемые данные уже присутствуют в Системе'
        if answer_decode.include?(expected_result)
          @result["run_RequestMessage"] = "true"
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done! Ответ содержит в себе значение: #{expected_result}")
          colorize_egg(@egg_version, menu_name, @pass_menu_color) if !@result.has_value?("false")
        else
          @result["run_RequestMessage"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена!")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Ответ не содержит в себе значение: #{expected_result}")
          colorize_egg(@egg_version, menu_name, @fail_menu_color)
        end
        count +=1
      end
    rescue Exception => msg
      @result["run_RequestMessage"] = "true"
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log(functional, "Ошибка при выполнении проверки!", "#{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version , menu_name, @fail_menu_color)
    end
  end
end