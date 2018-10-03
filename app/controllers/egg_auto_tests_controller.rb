require_dependency "#{Rails.root}/lib/egg_autotests/egg_autotests_list"
require 'open3'
require 'net/http'
require 'net/ftp'
require 'zip'
require 'nokogiri'
require_dependency "#{Rails.root}/lib/egg_autotests/installer/installer_options"

#Test commit

class EggAutoTestsController < ApplicationController
  
  def initialize
    super
    @db_username = "egg_autotest"
  end
  # helper :egg_auto_tests
  def index
    $browser_egg = Hash.new
    $browser_egg[:event] = ''
    $browser_egg[:message] = ''
    @egg67_components= ['ИА Active MQ',
                        'ИА УФЭБС (ГИС ГМП)',
                        'ИА УФЭБС (ГИС ЖКХ)',
                        'ИА JPMorgan (ГИС ГМП)',
                        'ИА JPMorgan (ГИС ЖКХ)',
                        'ИА ZKH-Loader/СА ZkhPayees',
                        'СА ГИС ГМП',
                        'СА ГИС ЖКХ',
                        'СА SPEP',
                        'СА ФНС ЕГРИП',
                        'СА ФНС ЕГРЮЛ',
                        'СА EFRSB (Банкроты)',
                        'СА ЕСИА СМЭВ3',
                        'СА ГИС ГМП СМЭВ3',
                        'ИА УФЭБС (ГИС ГМП СМЭВ3)']
    @egg68_components = Array.new(@egg67_components)
    @egg68_components.push('ЕСИА')
    regex = /\A[6]{,1}[.](9|10|11|12|13){,2}[.][\d]{,3}[-][\w]{,8}\Z/
    
    ftp = Net::FTP.new('10.1.1.163')
    ftp.login
    @dir = []
    ftp.chdir('build-release/egg-installer/')
    ftp.nlst.each do |line|
      if line.match(regex)
        @dir << line
      end
    end
    ftp.quit
  end
  
  def run_egg
    $status_egg_tests = true
    $browser_egg[:event] = ''
    $browser_egg[:message] = ''
    response_ajax_auto_egg("Не выбран функционал для проверки") and return if tests_params_egg[:egg_version] == 'eGG 6.7' and tests_params_egg[:functional_egg67].nil?
    response_ajax_auto_egg("Не выбрана сборка") and return if tests_params_egg[:build_version].empty?
    begin
      # Формируем файл с параметрами инсталлятора
      option_file = InstallerOptions.new(tests_params_egg[:build_version])
      option_file.make_oracle_options(@db_username)
      file_path = option_file.write_file
      
      @build_file_egg = "#{Rails.root}/egg-#{tests_params_egg[:build_version]}-installer-windows.exe"
      @installer_path_egg = "C:/EGG_Installer/egg-#{tests_params_egg[:build_version]}-installer-windows.exe"
      @run_test_message = "Установка/запуск eGG #{tests_params_egg[:build_version]}"
      @end_test_message = "Завершение тестов"
      Dir.chdir "#{Rails.root}"
      $log_egg = Logger_egg.new
      startTime = Time.now
      delete_db_egg(@run_test_message) if tests_params_egg[:drop_db] == 'true'
      if tests_params_egg[:dont_install_egg] == 'false'
        download_installer_egg(tests_params_egg[:build_version])
        copy_installer_egg
        $log_egg.write_to_browser("Устанавливаем EGG #{tests_params_egg[:build_version]}...")
        $log_egg.write_to_log(@run_test_message, "Устанавливаем EGG #{tests_params_egg[:build_version]}...", "Запустили задачу в #{Time.now.strftime('%H-%M-%S')}")
        system("#{@installer_path_egg} --optionfile #{file_path}")
      end
      return if dir_empty_egg?(tests_params_egg[:egg_dir])
      $log_egg.write_to_browser("#{puts_line_egg}")
      copy_core_config
      sleep 1
      start_servicemix_egg(tests_params_egg[:egg_dir])
      count = 400
      until egg_log_include?(tests_params_egg[:egg_dir],'Successfully')
        count -=1
        puts "Wait egg starting..#{count}"
        return if count == 0
        sleep 1
      end
      $log_egg.write_to_browser("Done! Запустили eGG")
      $log_egg.write_to_log(@run_test_message, "Запускаем Servicemix...", "Done! Запустили eGG")
      sleep 2
      $egg_integrator = EggCoreIntegrator.new
      $egg_integrator.start_core_in_listener
      $log_egg.write_to_browser("#{puts_line_egg}")
      if tests_params_egg[:egg_version] == 'eGG 6.7'
        $log_egg.write_to_browser("Запустили тесты eGG #{tests_params_egg[:build_version]}")
        $log_egg.write_to_log(@run_test_message, "Запустили тесты eGG #{tests_params_egg[:build_version]}", "Done!")
        testlist = EggAutotestsList.new(tests_params_egg[:egg_version], tests_params_egg[:try_count], tests_params_egg[:egg_dir], @db_username, tests_params_egg[:build_version])
        testlist.runTest_egg(tests_params_egg[:functional_egg67])
      elsif tests_params_egg[:egg_version] == 'eGG 6.8'
        $log_egg.write_to_browser("Запустили тесты eGG #{tests_params_egg[:build_version]}")
        $log_egg.write_to_log(@run_test_message, "Запустили тесты eGG #{tests_params_egg[:build_version]}", "Done!")
        testlist = EggAutotestsList.new(tests_params_egg[:egg_version], tests_params_egg[:try_count], tests_params_egg[:egg_dir], @db_username, tests_params_egg[:build_version])
        testlist.runTest_egg(tests_params_egg[:functional_egg68])
      end
      $log_egg.write_to_browser("#{puts_line_egg}")
      sleep 2
    rescue Exception => msg
      puts "Ошибка! #{msg} #{msg.backtrace.join("\n")}"
    ensure
      begin
        begin
          $egg_integrator.stop_core_in_listener if $egg_integrator.core_in_listener_live?
          stop_servicemix_egg(tests_params_egg[:egg_dir]) if tests_params_egg[:dont_stop_egg] == 'false'
          delete_db_egg(@end_test_message) if tests_params_egg[:dont_drop_db] == 'false'
        ensure
          $log_egg.write_to_browser("#{puts_line_egg}")
          if File.directory?(tests_params_egg[:egg_dir]) # Копируем логи из каталога ЕГГ
            copy_egg_files
          end
          if File.directory?(tests_params_egg[:egg_dir]) && tests_params_egg[:dont_drop_db] == 'false' # Удаляем каталог eGG
            FileUtils.rm_r "#{tests_params_egg[:egg_dir]}/."
            $log_egg.write_to_browser("Удалили каталог с eGG")
            $log_egg.write_to_log(@end_test_message, "Удалили каталог с eGG", "Done!")
          end
          if File.exist?(@installer_path_egg) # Удаляем инсталлятор
            File.delete(@installer_path_egg)
            option_file.move_options_file($log_egg.log_dir)
            $log_egg.write_to_browser("Удалили инсталлятор")
            $log_egg.write_to_log(@end_test_message, "Удалили инсталлятор", "Done!")
          end
        end
      ensure
        end_test_egg(startTime)
      end
    end
  end
  
  def run_automate
    $browser_egg[:event] = ''
    $browser_egg[:message] = ''
    regex = /\A[6]{,1}[.](9|10|11|12|13){,2}[.][\d]{,3}[-][\w]{,8}\Z/
    ftp = Net::FTP.new('10.1.1.163')
    ftp.login
    etalon_dir = []
    ftp.chdir('build-release/egg-installer/')
    ftp.nlst.each do |line|
      if line.match(regex)
        etalon_dir << line
      end
    end
    ftp.quit
    $check_new_egg_version = Thread.new do
      loop do
        begin
          #puts "Checking new EGG version in ftp..."
          ftp = Net::FTP.new('10.1.1.163')
          ftp.login
          current_dir = Array.new
          ftp.chdir('build-release/egg-installer/')
          ftp.nlst.each do |line|
            if line.match(regex)
              current_dir << line
            end
          end
          ftp.quit
          new_dir = current_dir - etalon_dir
          unless new_dir.empty?
            etalon_dir = current_dir
            puts "New EGG dir detected! #{new_dir}"
            build_version = new_dir.join
            components = if build_version.include?("6.11") or build_version.include?("6.12")
                           ['ИА Active MQ',
                            'ИА УФЭБС (ГИС ГМП)',
                            'ИА УФЭБС (ГИС ЖКХ)',
                            'ИА JPMorgan (ГИС ГМП)',
                            'ИА JPMorgan (ГИС ЖКХ)',
                            'ИА ZKH-Loader/СА ZkhPayees',
                            'СА ГИС ГМП',
                            'СА ГИС ЖКХ',
                            'СА SPEP',
                            'СА ФНС ЕГРИП',
                            'СА ФНС ЕГРЮЛ',
                            'СА EFRSB (Банкроты)',
                            'СА ЕСИА СМЭВ3',
                            'СА ГИС ГМП СМЭВ3',
                            'ИА УФЭБС (ГИС ГМП СМЭВ3)']
                         else
                           ['ИА Active MQ',
                            'ИА УФЭБС (ГИС ГМП)',
                            'ИА УФЭБС (ГИС ЖКХ)',
                            'ИА JPMorgan (ГИС ГМП)',
                            'ИА JPMorgan (ГИС ЖКХ)',
                            'ИА ZKH-Loader/СА ZkhPayees',
                            'СА ГИС ГМП',
                            'СА ГИС ЖКХ',
                            'СА SPEP',
                            'СА ФНС ЕГРИП',
                            'СА ФНС ЕГРЮЛ']
                         end
            begin
              $status_egg_tests = true
              sleep 20
              # Формируем файл с параметрами инсталлятора
              option_file = InstallerOptions.new(build_version)
              option_file.make_oracle_options(@db_username)
              file_path = option_file.write_file
              @build_file_egg = "#{Rails.root}/egg-#{build_version}-installer-windows.exe"
              @installer_path_egg = "C:/EGG_Installer/egg-#{build_version}-installer-windows.exe"
              @run_test_message = "Установка/запуск eGG #{build_version}"
              @end_test_message = "Завершение тестов"
              Dir.chdir "#{Rails.root}"
              $log_egg = Logger_egg.new
              startTime = Time.now
              delete_db_egg(@run_test_message)
              puts "Download EGG"
              download_installer_egg(build_version)
              puts "Copy Installer..."
              copy_installer_egg
              puts("Installing EGG #{build_version}...")
              $log_egg.write_to_log(@run_test_message, "Устанавливаем EGG #{build_version}...", "Запустили задачу в #{Time.now.strftime('%H-%M-%S')}")
              system("#{@installer_path_egg} --optionfile #{file_path}")
              #return if dir_empty_egg?('C:\EGG')
              puts "Copy config file"
              copy_core_config
              sleep 1
              puts "Starting EGG..."
              start_servicemix_egg('C:\EGG')
              count = 400
              until egg_log_include?('C:\EGG','Successfully')
                count -=1
                puts "Wait egg starting..#{count}"
                return if count == 0
                sleep 1
              end
              $log_egg.write_to_log(@run_test_message, "Запускаем Servicemix...", "Done! Запустили eGG")
              sleep 2
              $egg_integrator = EggCoreIntegrator.new
              $egg_integrator.start_core_in_listener
              $log_egg.write_to_log(@run_test_message, "Запустили тесты eGG #{build_version}", "Done!")
              testlist = EggAutotestsList.new('eGG 6.7', '1', 'C:\EGG', @db_username, build_version)
              testlist.runTest_egg(components)
              sleep 2
            rescue Exception => msg
              puts "Ошибка! #{msg} #{msg.backtrace.join("\n")}"
            ensure
              begin
                begin
                  $egg_integrator.stop_core_in_listener if $egg_integrator.core_in_listener_live?
                  stop_servicemix_egg('C:\EGG')
                  delete_db_egg(@end_test_message)
                ensure
                  $log_egg.write_to_browser("#{puts_line_egg}")
                  if File.directory?('C:\EGG') # Копируем логи из каталога ЕГГ
                    copy_egg_files
                    option_file.move_options_file($log_egg.log_dir)
                  end
                  if File.directory?('C:\EGG')
                    FileUtils.rm_r 'C:\EGG/.'
                    puts "Delete EGG dir"
                    $log_egg.write_to_log(@end_test_message, "Удалили каталог с eGG", "Done!")
                  end
                  if File.exist?(@installer_path_egg) # Удаляем инсталлятор
                    File.delete(@installer_path_egg)
                    puts "Delete EGG installer"
                    $log_egg.write_to_log(@end_test_message, "Удалили инсталлятор", "Done!")
                  end
                end
              rescue Exception => msg
                puts "Ошибка! #{msg} #{msg.backtrace.join("\n")}"
              ensure
                end_auto_test_egg(startTime, build_version)
              end
            end
          end
        ensure
          sleep 180
          next
        end
      end
    end
  end

  # def run_automate
  #   $browser_egg[:event] = ''
  #   $browser_egg[:message] = ''
  #   regex = /\A[6]{,1}[.](9|10|11|12|13){,2}[.][\d]{,3}[-][\w]{,8}\Z/
  #   ftp = Net::FTP.new('localhost')
  #   ftp.login
  #   etalon_dir = []
  #   #ftp.chdir('build-release/egg-installer/')
  #   ftp.nlst.each do |line|
  #     if line.match(regex)
  #       etalon_dir << line
  #     end
  #   end
  #   ftp.quit
  #   $check_new_egg_version = Thread.new do
  #     loop do
  #       begin
  #         #puts "Checking new EGG version in ftp..."
  #         ftp = Net::FTP.new('localhost')
  #         ftp.login
  #         current_dir = Array.new
  #         #ftp.chdir('build-release/egg-installer/')
  #         ftp.nlst.each do |line|
  #           if line.match(regex)
  #             current_dir << line
  #           end
  #         end
  #         ftp.quit
  #         new_dir = current_dir - etalon_dir
  #         unless new_dir.empty?
  #           etalon_dir = current_dir
  #           puts "New EGG dir detected! #{new_dir}"
  #           build_version = new_dir.join
  #           components = if build_version.include?("6.11") or build_version.include?("6.12")
  #                          ['ИА Active MQ',
  #                           'СА ГИС ГМП',
  #                           'СА ГИС ЖКХ',
  #                           'СА SPEP',
  #                           'СА ФНС ЕГРИП']
  #                        else
  #                          ['ИА Active MQ',
  #                           'ИА УФЭБС (ГИС ГМП)',
  #                           'ИА УФЭБС (ГИС ЖКХ)',
  #                           'ИА JPMorgan (ГИС ГМП)',
  #                           'ИА JPMorgan (ГИС ЖКХ)',
  #                           'ИА ZKH-Loader/СА ZkhPayees',
  #                           'СА ГИС ГМП',
  #                           'СА ГИС ЖКХ',
  #                           'СА SPEP',
  #                           'СА ФНС ЕГРИП',
  #                           'СА ФНС ЕГРЮЛ']
  #                        end
  #           begin
  #             $status_egg_tests = true
  #             sleep 20
  #             # Формируем файл с параметрами инсталлятора
  #             option_file = InstallerOptions.new(build_version)
  #             option_file.make_oracle_options(@db_username)
  #             file_path = option_file.write_file
  #             @build_file_egg = "#{Rails.root}/egg-#{build_version}-installer-windows.exe"
  #             @installer_path_egg = "C:/EGG_Installer/egg-#{build_version}-installer-windows.exe"
  #             @run_test_message = "Установка/запуск eGG #{build_version}"
  #             @end_test_message = "Завершение тестов"
  #             Dir.chdir "#{Rails.root}"
  #             $log_egg = Logger_egg.new
  #             startTime = Time.now
  #             #delete_db_egg(@run_test_message)
  #             puts "Download EGG"
  #             #download_installer_egg(build_version)
  #             puts "Copy Installer..."
  #             copy_installer_egg
  #             puts("Installing EGG #{build_version}...")
  #             $log_egg.write_to_log(@run_test_message, "Устанавливаем EGG #{build_version}...", "Запустили задачу в #{Time.now.strftime('%H-%M-%S')}")
  #             #system("#{@installer_path_egg} --optionfile #{file_path}")
  #             #return if dir_empty_egg?('C:\EGG')
  #             puts "Copy config file"
  #             copy_core_config
  #             sleep 1
  #             puts "Starting EGG..."
  #             start_servicemix_egg('C:\EGG')
  #             count = 400
  #             until egg_log_include?('C:\EGG','Successfully')
  #               count -=1
  #               puts "Wait egg starting..#{count}"
  #               return if count == 0
  #               sleep 1
  #             end
  #             $log_egg.write_to_log(@run_test_message, "Запускаем Servicemix...", "Done! Запустили eGG")
  #             sleep 2
  #             $egg_integrator = EggCoreIntegrator.new
  #             $egg_integrator.start_core_in_listener
  #             $log_egg.write_to_log(@run_test_message, "Запустили тесты eGG #{build_version}", "Done!")
  #             testlist = EggAutotestsList.new('eGG 6.7', '1', 'C:\EGG', @db_username, build_version)
  #             testlist.runTest_egg(components)
  #             sleep 2
  #           rescue Exception => msg
  #             puts "Ошибка! #{msg} #{msg.backtrace.join("\n")}"
  #           ensure
  #             begin
  #               begin
  #                 $egg_integrator.stop_core_in_listener if $egg_integrator.core_in_listener_live?
  #                 stop_servicemix_egg('C:\EGG')
  #                 #delete_db_egg(@end_test_message)
  #               ensure
  #                 $log_egg.write_to_browser("#{puts_line_egg}")
  #                 if File.directory?('C:\EGG') # Копируем логи из каталога ЕГГ
  #                   copy_egg_files
  #                   option_file.move_options_file($log_egg.log_dir)
  #                 end
  #                 if File.directory?('C:\EGG')
  #                   #FileUtils.rm_r 'C:\EGG/.'
  #                   puts "Delete EGG dir"
  #                   $log_egg.write_to_log(@end_test_message, "Удалили каталог с eGG", "Done!")
  #                 end
  #                 if File.exist?(@installer_path_egg) # Удаляем инсталлятор
  #                   File.delete(@installer_path_egg)
  #                   puts "Delete EGG installer"
  #                   $log_egg.write_to_log(@end_test_message, "Удалили инсталлятор", "Done!")
  #                 end
  #               end
  #             rescue Exception => msg
  #               puts "Ошибка! #{msg} #{msg.backtrace.join("\n")}"
  #             ensure
  #               puts $log_egg.inspect
  #               end_auto_test_egg(startTime, build_version)
  #             end
  #           end
  #         end
  #       ensure
  #         sleep 15
  #         next
  #       end
  #     end
  #   end
  # end
  
  def stop_autotests
    $check_new_egg_version.kill
    $status_egg_tests = false
  end
  
  def live_stream_egg
    sleep 0.1
    response.headers['Content-Type'] = 'text/event-stream'
    sse = SSE.new(response.stream, retry: 1400)
    sse.write "#{$browser_egg[:message]}", event: "update_log"
    if $browser_egg[:event] == 'colorize_egg'
      sse.write "#{$browser_egg[:egg_version]},#{$browser_egg[:functional]},#{$browser_egg[:color]}", event: "#{$browser_egg[:event]}"
      $browser_egg[:event] = ''
    end
    $browser_egg[:message] = ''
  ensure
    sse.close
  end
  
  def download_log_egg
    #Dir.chdir "#{Rails.root}"
    send_file "#{$log_egg.log_dir}/#{params[:filename]}"
  end
  
  def tester
    $log_egg = {"Проверка ActiveMQ. Payment_новый. Попытка 1" => {"проверки Active MQ" => "Текст ошибки"}, "Проверка WMQ. Payment_новый. Попытка 1" => {"Ошибка WMQ" => "Текст ошибки"}}
    send_email('C:\Users\Pekav\Downloads\amqrecipient.xml', '6.11.105-RELEASE1')
    # require "sqljdbc4-4.1.jar"
    # java_import 'oracle.jdbc.OracleDriver'
    # java_import 'java.sql.DriverManager'
    # java_import 'java.sql.DriverManager'
    # java_import 'com.microsoft.sqlserver.jdbc.SQLServerDriver'
    #
    # begin
    #   url = "jdbc:sqlserver://vm-corint:1433"
    #   connection = java.sql.DriverManager.getConnection(url, 'root', '12345');
    #   stmt = connection.create_statement
    #   stmt.executeUpdate("insert into zkh_inn (inn, kpp, name, account, bank_name, bank_bik) values (9909400765, 774763002, 'ООО Межгосударственный банк', 30301810000006000001, 'ПАО СБЕРБАНК', '044525225')")
    # rescue Exception => msg
    #   puts msg
    #   puts msg.backtrace.join("\n")
    # ensure
    #   stmt.close if stmt
    #   connection.close if connection
    # end
  end
end

private
def tests_params_egg
  params.require(:test_data).permit(:egg_version, :egg_dir, :dont_drop_db, :dont_stop_egg, :build_version, :try_count, :drop_db, :dont_install_egg, :functional_egg67 => [], :functional_egg68 => [])
end
