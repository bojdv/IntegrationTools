class TestReportsController < ApplicationController
  def index

  end

  def run
    #response_ajax_reports("Не заполнены метки") and return if report_params[:labels].empty? # добавить все условия
    backlog_keys = report_params[:backlog_keys].split('-')
    #a = Hash[*backlog_keys]
    p backlog_keys
    #data = JIRA_Report.new(label)
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
