class IA_ActiveMQ # Класс для тестирования адаптера

  def initialize(pass_menu_color, fail_menu_color, not_find_xml, not_receive_answer, egg_version, try_count) # Инициализируем переменные класса
    @pass_menu_color = pass_menu_color # комментарии смотри в egg_autotests_list.rb
    @fail_menu_color = fail_menu_color
    @not_find_xml = not_find_xml
    @not_receive_answer = not_receive_answer
    @egg_version = egg_version
    @try_count = try_count
    @result = Hash.new # хэш, в который пишутся результаты выполнения теста
    @functional = "Проверка адаптера СА ГИС ГМП" # Имя корневого раздела теста в логе html
  end

  def run_RequestMessage # Запуск теста платежки ГИС ГМП
    sleep 1.5
    menu_name = 'ИА Active MQ' # Имя пункта меню, что бы знать, что покрасить в цвет после выполнения
    category = Category.find_by_category_name('ИА Active MQ') # Создаем переменную, содержащую категорию с нужным имененм из XML Sender
    xml_name = 'Payment_новый' # Переменная XML с имененем из XML Sender
    manager = QueueManager.find_by_manager_name('iTools[EGG]') # Создаем переменную, содержащую менеджер очереди с нужным имененем из XML Sender
    begin # begin означает начало блока, в котором мы хотим отловить исключение, если оно случится, что будет выполнен блок rescue
      count = 1 # Создаем переменную-счетчик
      until @result["run_RequestMessage"] == "true" or count > @try_count # Выполняем цикл, пока результат не будет true или пока счетчик не превысит число попыток
        functional = "#{@functional}. #{xml_name}. Попытка #{count}" # Формируем имя корневого пункта меню
        $log_egg.write_to_log(functional, "Начали проверку в #{Time.now.strftime('%H-%M-%S')}", "#{menu_name}") # Запись в лог html
        $log_egg.write_to_browser("#{puts_line_egg}") # Запись в лог браузера
        $log_egg.write_to_browser("Начали проверку: #{menu_name}. Попытка #{count}")
        $log_egg.write_to_browser("Пытаемся найти XML в БД")
        $log_egg.write_to_log(functional, "Пытаемся найти XML в БД")
        xml = Xml.where(xml_name: xml_name, category_id: category.id).first # Получаем xml по имени XML и имени категории
        raise @not_find_xml if xml.nil? # исключение, если xml не найдена
        $log_egg.write_to_log(functional, "Получили xml", "#{xml.xml_name}\n#{xml.xml_text}")
        xsd = "#{Rails.root}/lib/egg_autotests/xsd/amq_adapter/MQMessages.xsd" # Получаем путь к XSD
        $log_egg.write_to_browser("Валидируем XML для запроса...")
        $log_egg.write_to_log(functional, "Валидация исходящей XML", "Валидируем XML для запроса:\n#{xml.xml_name}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, xml.xml_text, functional) # Вызываем метод валидации
        answer = send_to_amq_and_receive_egg(manager, xml, functional, true) # Вызываем метод отправки в MQ и записываем полученный ответ в answer
        if answer.nil? # Если ответ от ЕГГ пустой, начинаем цикл заново
          @result["run_RequestMessage"] = "false"
          count +=1
          next
        end
        $log_egg.write_to_browser("Валидируем ответную XML...")
        $log_egg.write_to_log(functional, "Валидируем ответную XML", "Валидируем ответную XML:\n#{answer}\nПо XSD:\n #{xsd}")
        validate_egg_xml(xsd, answer, functional) # валидируем ответ
        answer_decode = get_decode_answer(answer) # Вызываем метод декодирования ответа из Base64
        $log_egg.write_to_browser("Раскодировали ответ!")
        $log_egg.write_to_log(functional, "Раскодированный тег Answer", "#{answer_decode}")
        expected_result = 'Импортируемые данные уже присутствуют в Системе' # Текст, который должен быть в XML, если она успешна
        if answer_decode.include?(expected_result) # Проверяем, присутствует ли нужный текст в декодированном ответе
          @result["run_RequestMessage"] = "true" # Записываем в хэш @result ключ run_RequestMessage со значением true
          $log_egg.write_to_browser("Проверка пройдена!")
          $log_egg.write_to_log(functional, "Проверка пройдена!", "Done! Ответ содержит в себе значение: #{expected_result}")
          colorize_egg(@egg_version, menu_name, @pass_menu_color) if !@result.has_value?("false") # Если хэш @result не содержит значение false, то вызываем метод, который красит меню в зеленый цвет
        else
          @result["run_RequestMessage"] = "false"
          $log_egg.write_to_browser("Проверка не пройдена!")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Ответ не содержит в себе значение: #{expected_result}")
          colorize_egg(@egg_version, menu_name, @fail_menu_color)
        end
        count +=1 # Увеличиваем счетчик на +1, иначе говоря count = count + 1
      end
    rescue Exception => msg # Записываем текст исключения в переменную msq
      @result["run_RequestMessage"] = "false"
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log(functional, "Ошибка при выполнении проверки!", "#{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version , menu_name, @fail_menu_color)
    end
  end
end