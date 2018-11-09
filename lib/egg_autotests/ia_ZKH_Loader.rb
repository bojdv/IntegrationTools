
class IA_ZKH_Loader

  def initialize(pass_menu_color, fail_menu_color, egg_version, egg_dir, db_username)
    @pass_menu_color = pass_menu_color
    @fail_menu_color = fail_menu_color
    @egg_version = egg_version
    @egg_dir = egg_dir
    @db_username = db_username

    @menu_name = 'ИА ZKH-Loader/СА ZkhPayees'
    @result = Hash.new
    @functional = "Проверка ИА ZKH-Loader/СА ZkhPayees (Импорт поставщиков)"
  end

  def providerCatalogFile_test # Справочник поставщиков через каталог
    begin
      sleep 1.5
      functional = "#{@functional}. Импорт через каталог."
      $log_egg.write_to_log(functional, "Начали проверку в #{Time.now.strftime('%H-%M-%S')}", "#{@menu_name} #{functional}")
      $log_egg.write_to_browser("#{puts_line_egg}")
      $log_egg.write_to_browser("Начали проверку: #{functional}")
      catalog = "#{Rails.root}\\lib\\egg_autotests\\provider_catalog.csv"
      in_dir = "C:/tmp/files/in"
      FileUtils.cp(catalog, in_dir)
      $log_egg.write_to_browser("Скопировали справочник из каталога: #{catalog}\nВ каталог: #{in_dir}")
      $log_egg.write_to_log(functional, "Копируем справочник", "Скопировали справочник из каталога: #{catalog}\nВ каталог: #{in_dir}")
      check_inn = SQL_query.new
      inn = check_inn.check_provider_file(functional)
      if inn.include?('9999999999')
        @result["providerCatalogFile_test"] = "true"
        $log_egg.write_to_browser("Проверка пройдена! Нашли поставщика с ИНН = 9999999999 в таблице zkh_inn")
        $log_egg.write_to_log(functional, "Проверка пройдена!", "Нашли поставщика с ИНН = 9999999999 в таблице zkh_inn")
        colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
      else
        @result["providerCatalogFile_test"] = "false"
        $log_egg.write_to_browser("Проверка не пройдена! Не нашли поставщика с ИНН = 9999999999 в таблице zkh_inn")
        $log_egg.write_to_log(functional, "Проверка не пройдена!", "Не нашли поставщика с ИНН = 9999999999 в таблице zkh_inn")
        colorize_egg(@egg_version, @menu_name, @fail_menu_color)
      end
    rescue Exception => msg
      @result["providerCatalogFile_test"] = "false"
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log(functional, "Случилось непредвиденное:(", "Ошибка! #{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version, @menu_name, @fail_menu_color)
    end
  end

  def providerCatalogMQ_test # Справочник поставщиков через MQ и СА ZkhPayees
    begin
      sleep 1.5
      functional = "#{@functional}. Импорт через MQ (СА ZkhPayees)."
      $log_egg.write_to_log(functional, "Начали проверку в #{Time.now.strftime('%H-%M-%S')}", "#{@menu_name} #{functional}")
      $log_egg.write_to_browser("#{puts_line_egg}")
      $log_egg.write_to_browser("Начали проверку: #{functional}")
      count = 180
      $log_egg.write_to_browser("Парсим лог eGG на присутствие срабатывания задачи импорта в течении #{count} секунд")
      $log_egg.write_to_log(functional, "Парсим лог", "Парсим лог eGG на присутствие срабатывания задачи импорта в течении #{count} секунд")
      until egg_log_include?(@egg_dir, 'PaymentReceiverJob')
        count -=1
        puts "Wait PaymentReceiverJob..#{count}"
        return if count == 0
        sleep 1
      end
      $log_egg.write_to_browser("Обнаружили срабатывание задачи PaymentReceiverJob")
      $log_egg.write_to_log(functional, "Результат парсинга", "Обнаружили срабатывание задачи PaymentReceiverJob")
      check_inn = SQL_query.new
      inn = check_inn.check_provider_mq(functional)
      if inn.include?('7707083893')
        @result["providerCatalogMQ_test"] = "true"
        $log_egg.write_to_browser("Проверка пройдена! Нашли поставщика с ИНН = 7707083893 в таблице zkh_inn")
        $log_egg.write_to_log(functional, "Проверка пройдена!", "Нашли поставщика с ИНН = 7707083893 в таблице zkh_inn")
        colorize_egg(@egg_version, @menu_name, @pass_menu_color) if !@result.has_value?("false")
      elsif inn.empty?
        if egg_log_include?(@egg_dir, 'SMEV-101005')
          $log_egg.write_to_browser("Проверка не пройдена! СМЭВ недоступен!")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Проверка не пройдена! СМЭВ недоступен!")
        else
          $log_egg.write_to_browser("Проверка не пройдена! Справочник не загрузился!")
          $log_egg.write_to_log(functional, "Проверка не пройдена!", "Справочник не загрузился!")
        end
        @result["providerCatalogMQ_test"] = "false"
        colorize_egg(@egg_version, @menu_name, @fail_menu_color)
      end
    rescue Exception => msg
      @result["providerCatalogMQ_test"] = "false"
      $log_egg.write_to_browser("Ошибка! #{msg}")
      $log_egg.write_to_log(functional, "Случилось непредвиденное:(", "Ошибка! #{msg}\n#{msg.backtrace.join("\n")}")
      colorize_egg(@egg_version, @menu_name, @fail_menu_color)
    end
  end
end
