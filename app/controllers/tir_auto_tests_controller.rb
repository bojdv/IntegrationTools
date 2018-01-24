include TirAutotests
class TirAutoTestsController < ApplicationController
  def index

  end
  def run
    puts tests_params
    if tests_params[:tir_version] == 'ТИР 2.2'
      runTest(tests_params[:functional_tir22])
    elsif tests_params[:tir_version] == 'ТИР 2.3'
      runTest(tests_params[:functional_tir23])
    end
  end
end

private
  def tests_params
    params.require(:test_data).permit(:tir_version, :functional_tir22 => [], :functional_tir23 => [])
  end