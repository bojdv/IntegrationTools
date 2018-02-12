include EggAutotests
require 'open3'
require 'net/http'
require 'net/ftp'
require 'zip'

class EggAutoTestsController < ApplicationController
  def index
    @egg67_components= ['Проверка ИА Active MQ',
                        'Проверка ИА УФЭБС (File)',
                        'Проверка СА ГИС ГМП']
    @egg68_components = Array.new(@egg67_components)
    @egg68_components.push('Проверка СА ГИС ЖКХ')
  end

  def run
    $browser_egg = Hash.new
    $browser_egg[:event] = ''
    $browser_egg[:message] = ''
    response_ajax_auto("Не выбран функционал для проверки") and return if tests_params[:egg_version] == 'eGG 6.7' and tests_params[:functional_egg67].nil?
    response_ajax_auto("Не выбран функционал для проверки") and return if tests_params[:egg_version] == 'eGG 6.8' and tests_params[:functional_egg68].nil?
    begin
      Dir.chdir "#{Rails.root}"
      log_file_name = "log_egg_autotests_#{Time.now.strftime('%H-%M-%S')}.txt"
      $log_egg = Logger.new(File.open("log\\#{log_file_name}", 'w'))
      startTime = Time.now
      return if dir_empty?(tests_params[:egg_dir])
      send_to_log("#{puts_line}", "#{puts_line}")
      sleep 1
      start_servicemix(tests_params[:egg_dir])
      n = 0
      until ping_server("http://localhost:8181")
        sleep 1
        n += 1
        return if n > 90
      end
      send_to_log("Done! Запустили eGG", "Done! Запустили eGG")
      sleep 3
      send_to_log("#{puts_line}", "#{puts_line}")
      if tests_params[:egg_version] == 'eGG 6.7'
        send_to_log("Запустили тесты eGG 6.7", "Запустили тесты eGG 6.7")
        runTest(tests_params[:functional_egg67])
      elsif tests_params[:egg_version] == 'eGG 6.8'
        send_to_log("Запустили тесты eGG 6.8", "Запустили тесты eGG 6.8")
        runTest(tests_params[:functional_egg68])
      end
      send_to_log("#{puts_line}", "#{puts_line}")
      sleep 20
      stop_servicemix(tests_params[:egg_dir]) if tests_params[:dont_stop_egg] == 'false'
      delete_db if tests_params[:dont_drop_db] == 'false'
      send_to_log("#{puts_line}", "#{puts_line}")
    ensure
      end_test(log_file_name, startTime)
    end
  end

  def live_stream
    response.headers['Content-Type'] = 'text/event-stream'
    sse = SSE.new(response.stream, retry: 300)
    sse.write "#{$browser_egg[:message]}", event: "update_log"
    if $browser_egg[:event] == 'colorize'
      sse.write "#{$browser_egg[:egg_version]},#{$browser_egg[:functional]},#{$browser_egg[:color]}", event: "#{$browser_egg[:event]}"
      $browser_egg[:event] = ''
    end
    $browser_egg[:message] =''
  ensure
    sse.close
  end
  def download_log
    Dir.chdir "#{Rails.root}"
    send_file "log\\#{params[:filename]}"
  end
  def tester
    puts File.directory?('C:/EGG')
  end
end

private
def tests_params
  params.require(:test_data).permit(:egg_version, :egg_dir, :dont_drop_db, :dont_stop_egg, :functional_egg67 => [], :functional_egg68 => [])
end
