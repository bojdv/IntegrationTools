include TirAutotests
class TirAutoTestsController < ApplicationController
  def index
    $log = String.new
  end
  def run
    if tests_params[:tir_version] == 'ТИР 2.2'
      send_to_log("Запустили тесты ТИР 2.2")
      runTest(tests_params[:functional_tir22])
    elsif tests_params[:tir_version] == 'ТИР 2.3'
      send_to_log("Запустили тесты ТИР 2.3")
      runTest(tests_params[:functional_tir23])
    end
    sleep 0.5
    $log.clear
    respond_to do |format|
      format.js { render :js => "kill_listener()" }
    end
  end
  def tester
    response.headers['Content-Type'] = 'text/event-stream'
    sse = SSE.new(response.stream, retry: 300, event: "update_log")
    sse.write "#{$log}"
    $log.clear
  ensure
    sse.close
  end
end

private
  def tests_params
    params.require(:test_data).permit(:tir_version, :functional_tir22 => [], :functional_tir23 => [])
  end