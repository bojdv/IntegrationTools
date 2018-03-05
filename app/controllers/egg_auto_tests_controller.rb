include EggAutotests
require 'open3'
require 'net/http'
require 'net/ftp'
require 'zip'
require 'nokogiri'

class EggAutoTestsController < ApplicationController
  helper :egg_auto_tests
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
  end

  def run_egg
    $browser_egg[:event] = ''
    $browser_egg[:message] = ''
    response_ajax_auto_egg("Не выбран функционал для проверки") and return if tests_params_egg[:egg_version] == 'eGG 6.7' and tests_params_egg[:functional_egg67].nil?
    response_ajax_auto_egg("Не выбран функционал для проверки") and return if tests_params_egg[:egg_version] == 'eGG 6.8' and tests_params_egg[:functional_egg68].nil?
    begin
      Dir.chdir "#{Rails.root}"
      log_file_name = "log_egg_autotests_#{Time.now.strftime('%H-%M-%S')}.txt"
      $log_egg = Logger.new(File.open("log\\#{log_file_name}", 'w'))
      startTime = Time.now
      return if dir_empty_egg?(tests_params_egg[:egg_dir])
      send_to_log_egg("#{puts_line_egg}", "#{puts_line_egg}")
      sleep 1
      start_servicemix_egg(tests_params_egg[:egg_dir])
      n = 0
      until ping_server_egg("http://localhost:8181")
        sleep 1
        n += 1
        return if n > 90
      end
      send_to_log_egg("Done! Запустили eGG", "Done! Запустили eGG")
      sleep 20
      send_to_log_egg("#{puts_line_egg}", "#{puts_line_egg}")
      if tests_params_egg[:egg_version] == 'eGG 6.7'
        send_to_log_egg("Запустили тесты eGG 6.7", "Запустили тесты eGG 6.7")
        runTest_egg(tests_params_egg[:functional_egg67])
      elsif tests_params_egg[:egg_version] == 'eGG 6.8'
        send_to_log_egg("Запустили тесты eGG 6.8", "Запустили тесты eGG 6.8")
        runTest_egg(tests_params_egg[:functional_egg68])
      end
      send_to_log_egg("#{puts_line_egg}", "#{puts_line_egg}")
      sleep 2
      stop_servicemix_egg(tests_params_egg[:egg_dir]) if tests_params_egg[:dont_stop_egg] == 'false'
      delete_db_egg if tests_params_egg[:dont_drop_db] == 'false'
      send_to_log_egg("#{puts_line_egg}", "#{puts_line_egg}")
    ensure
      if File.directory?('C:/EGG') && tests_params_egg[:dont_drop_db] == 'false' # Удаляем каталог eGG
        FileUtils.rm_r "C:/EGG/."
        send_to_log_egg("Удалили eGG", "Удалили eGG")
      end
      end_test_egg(log_file_name, startTime)
    end
  end

  def live_stream_egg
    sleep 0.1
    response.headers['Content-Type'] = 'text/event-stream'
    sse = SSE.new(response.stream, retry: 500)
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
    Dir.chdir "#{Rails.root}"
    send_file "log\\#{params[:filename]}"
  end
  def tester
    puts Date.parse("2017-#{Random.rand(1..11)}-#{Random.rand(1..28)}")
  end
end

private
def tests_params_egg
  params.require(:test_data).permit(:egg_version, :egg_dir, :dont_drop_db, :dont_stop_egg, :functional_egg67 => [], :functional_egg68 => [])
end
