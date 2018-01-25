include TirAutotests
class TirAutoTestsController < ApplicationController
  def index
    $browser = Hash.new
    $browser[:event] = ''
    $browser[:message] = ''
  end
  def run
    if tests_params[:tir_version] == 'ТИР 2.2'
      response_ajax_auto("Не выбран функционал для проверки") and return if tests_params[:functional_tir22].nil?
      send_to_log("Запустили тесты ТИР 2.2")
      runTest(tests_params[:functional_tir22])
    elsif tests_params[:tir_version] == 'ТИР 2.3'
      response_ajax_auto("Не выбран функционал для проверки") and return if tests_params[:functional_tir23].nil?
      send_to_log("Запустили тесты ТИР 2.3")
      runTest(tests_params[:functional_tir23])
    end
    sleep 0.5
    $browser[:message].clear
    respond_to do |format|
      format.js { render :js => "kill_listener()" }
    end
  end
  def tester
    response.headers['Content-Type'] = 'text/event-stream'
    sse = SSE.new(response.stream, retry: 300)
    sse.write "#{$browser[:message]}", event: "update_log"
    if $browser[:event] == 'colorize'
      sse.write "#{$browser[:functional]}, #{$browser[:color]}", event: "#{$browser[:event]}"
      $browser[:event] = ''
    end
    $browser[:message] =''
  ensure
    sse.close
  end
end

private
  def tests_params
    params.require(:test_data).permit(:tir_version, :functional_tir22 => [], :functional_tir23 => [])
  end