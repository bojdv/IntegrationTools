require_dependency "#{Rails.root}/lib/egg_autotests/egg_autotests_list"
require 'open3'
require 'net/http'
require 'net/ftp'
require 'zip'
require 'nokogiri'

class EggAutoTestsController < ApplicationController
  # helper :egg_auto_tests
  def index
    $browser_egg = Hash.new
    $browser_egg[:event] = ''
    $browser_egg[:message] = ''
    @egg67_components= ['Проверка ИА Active MQ',
                        'Проверка ИА УФЭБС (ГИС ГМП)',
                        'Проверка ИА УФЭБС (ГИС ЖКХ)',
                        'Проверка СА ГИС ГМП',
                        'Проверка СА ГИС ЖКХ']
    @egg68_components = Array.new(@egg67_components)
    @egg68_components.push('ЕСИА')
    regex = /\A[6]{,1}[.](9|10|11){,2}[.][\d]{,3}\Z/
    ftp = Net::FTP.new('server-ora-bssi')
    ftp.login
    @dir = []
    ftp.chdir('build-release/egg/')
    ftp.nlst.each do |line|
      if line.match(regex)
        @dir << line
      end
    end
  end

  def run_egg
    $browser_egg[:event] = ''
    $browser_egg[:message] = ''
    response_ajax_auto_egg("Не выбран функционал для проверки") and return if tests_params_egg[:egg_version] == 'eGG 6.7' and tests_params_egg[:functional_egg67].nil?
    response_ajax_auto_egg("Не выбран функционал для проверки") and return if tests_params_egg[:egg_version] == 'eGG 6.8' and tests_params_egg[:functional_egg68].nil?
    begin
      @build_file_egg = "#{Rails.root}/egg-#{tests_params_egg[:build_version]}-installer-windows.exe"
      @installer_path_egg = "C:/EGG_Installer/egg-#{tests_params_egg[:build_version]}-installer-windows.exe"
      Dir.chdir "#{Rails.root}"
      $log_egg = Logger_egg.new
      startTime = Time.now
      if !tests_params_egg[:build_version].empty?
        download_installer_egg
        copy_installer_egg
        $log_egg.write_to_browser("Устанавливаем EGG #{tests_params_egg[:build_version]}...")
        $log_egg.write_to_log("Установка/запуск eGG", "Устанавливаем EGG #{tests_params_egg[:build_version]}...", "Запустили задачу в #{Time.now.strftime('%H-%M-%S')}")
        system("#{@installer_path_egg} --optionfile #{Rails.root}/lib/egg_autotests/installer/optionsEgg67.txt")
      end
      return if dir_empty_egg?(tests_params_egg[:egg_dir])
      $log_egg.write_to_browser("#{puts_line_egg}")
      sleep 1
      start_servicemix_egg(tests_params_egg[:egg_dir])
      count = 400
      until egg_run?
        count -=1
        puts "Wait egg starting..#{count}"
        return if count == 0
        sleep 1
      end
      $log_egg.write_to_browser("Done! Запустили eGG")
      $log_egg.write_to_log("Установка/запуск eGG", "Запускаем Servicemix...", "Done! Запустили eGG")
      sleep 2
      $log_egg.write_to_browser("#{puts_line_egg}")
      if tests_params_egg[:egg_version] == 'eGG 6.7'
        $log_egg.write_to_browser("Запустили тесты eGG #{tests_params_egg[:build_version]}")
        $log_egg.write_to_log("Установка/запуск eGG", "Запустили тесты eGG #{tests_params_egg[:build_version]}", "Done!")
        testlist = EggAutotestsList.new(tests_params_egg[:egg_version], tests_params_egg[:try_count])
        testlist.runTest_egg(tests_params_egg[:functional_egg67])
      elsif tests_params_egg[:egg_version] == 'eGG 6.8'
        $log_egg.write_to_browser("Запустили тесты eGG #{tests_params_egg[:build_version]}")
        $log_egg.write_to_log("Установка/запуск eGG", "Запустили тесты eGG #{tests_params_egg[:build_version]}", "Done!")
        testlist = EggAutotestsList.new(tests_params_egg[:egg_version], tests_params_egg[:try_count])
        testlist.runTest_egg(tests_params_egg[:functional_egg68])
      end
      $log_egg.write_to_browser("#{puts_line_egg}")
      sleep 2
    rescue Exception => msg
      puts "Ошибка! #{msg} #{msg.backtrace.join("\n")}"
    ensure
      begin
        begin
          stop_servicemix_egg(tests_params_egg[:egg_dir]) if tests_params_egg[:dont_stop_egg] == 'false'
          delete_db_egg if tests_params_egg[:dont_drop_db] == 'false'
        ensure
          $log_egg.write_to_browser("#{puts_line_egg}")
          if File.directory?(tests_params_egg[:egg_dir]) # Копируем логи из каталога ЕГГ
            copy_egg_files
          end
          if File.directory?(tests_params_egg[:egg_dir]) && tests_params_egg[:dont_drop_db] == 'false' # Удаляем каталог eGG
            FileUtils.rm_r "#{tests_params_egg[:egg_dir]}/."
            $log_egg.write_to_browser("Удалили каталог с eGG")
            $log_egg.write_to_log("Завершение тестов", "Удалили каталог с eGG", "Done!")
          end
          if File.exist?(@installer_path_egg) # Удаляем инсталлятор
            File.delete(@installer_path_egg)
            $log_egg.write_to_browser("Удалили инсталлятор")
            $log_egg.write_to_log("Завершение тестов", "Удалили инсталлятор", "Done!")
          end
        end
      ensure
        end_test_egg(startTime)
      end
    end
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
    count = tests_params_egg[:try_count]
    until count > 3
      count +=1
      puts count
      next count +=1 if count < 10
    end
  end
end

private
def tests_params_egg
  params.require(:test_data).permit(:egg_version, :egg_dir, :dont_drop_db, :dont_stop_egg, :build_version, :try_count, :functional_egg67 => [], :functional_egg68 => [])
end
