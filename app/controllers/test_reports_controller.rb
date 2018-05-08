class TestReportsController < ApplicationController
  def index

  end

  def run
    response_ajax_reports("Не заполнены метки") and return if report_params[:labels].empty?
  end

  def tester
  end

  private
  def report_params
    params.require(:report_params).permit(:labels,
                                          :backlog_keys,
                                          :project_keys,
                                          :project_codes,
                                          :start_test,
                                          :end_test,
                                          :test_plan,
                                          :test_rail,
                                          :build_link,
                                          :testing,
                                          :not_testing,
                                          :build_quality,
                                          :build_intention,
                                          :limitation)
  end
end
