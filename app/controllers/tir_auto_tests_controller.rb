include TirAutotests
class TirAutoTestsController < ApplicationController
  def index

  end
  def run
    @message = String.new
    @message << "WAAAAAAAAAAAAAAAAAAA"
    response.headers["Content-Type"] = "text/event-stream"
    response.stream.write "data: WA \n\n"
    response.stream.close
    # if tests_params[:tir_version] == 'ТИР 2.2'
    #   runTest(tests_params[:functional_tir22])
    # elsif tests_params[:tir_version] == 'ТИР 2.3'
    #   runTest(tests_params[:functional_tir23])
    #   tester
    # end
  end
  def tester
    puts @message if !@message.nil?
    response.headers["Content-Type"] = "text/event-stream"
    response.stream.write "data: #{@message} \n\n"
    response.stream.close
    sleep 5
  end
end

private
  def tests_params
    params.require(:test_data).permit(:tir_version, :functional_tir22 => [], :functional_tir23 => [])
  end