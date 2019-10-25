module TestPlansHelper
  class TestPlanReport
    include TestPlansHelper
    include TestReportsHelper
    def initialize(plan, builds, version, minus, rn, file_info)
      @plan = plan
      @build_links = builds
      @version = version
      @rn = rn
      @file_info = file_info
      @minus = minus
      @qa = Array.new
      if @plan.features.any?
        plan.features.each {|f| @qa << f.qa}
        @qa = @qa.uniq
        @backlog, @labels = get_list_of_value(@plan)
        @report = JIRA_Report.new(@backlog, @labels, $qa) # Общий отчет по тестированию
        unless @report.project_name.nil?
          @backlog_estimate = @report.select_backlog_estimate
          @project_estimate = @report.select_project_estimate
          @testing_worklogtime, @test_tasks = @report.select_test_worklog
          @defect_worklogtime, @consultation_worklogtime, @agreement_worklogtime, @def_tasks, @cons_tasks, @agree_tasks, @open_def, @open_def_bkv = @report.select_inner_tasks_worklog
          @deis_defect_worklogtime = @report.select_deis_worklog
          @deis_def, @deis_defect_true_count = @report.select_deis
          @other_tasks = @report.select_other_task
          @start_test_date, @end_test_date = find_max_test_dates(@plan)
        end
      end
    end
    def make_testplan_reports # Метод формирующий файл отчета
        log_file_name = "Test_Report_#{Time.now.strftime('%Y-%m-%d(%H-%M-%S)')}.html" # формируем имя файла
        file_path = "//vm-itools/test_reports/#{log_file_name}"
        template = File.read("#{Rails.root}/lib/test_plans/report_template.html.erb") # читаем шаблон для лога
        result = ERB.new(template).result(binding)
        # if not Dir.exist?("#{Rails.root}/lib/test_reports/reports/")
        #   Dir.mkdir("#{Rails.root}/lib/test_reports/reports/")
        # end
        File.open(file_path, 'w+') do |f|
          f.write result
        end
        return file_path
    end
  end

  def get_list_of_value(plan)
    backlog = Array.new
    labels = Array.new
    plan.features.each do |b|
      backlog << b.backlog unless b.backlog.nil?
      labels << b.labels
    end
    return backlog.empty? ? nil : backlog.join(','), labels.join(',')
  end

  def find_max_test_dates(plan)
    start_date = Array.new
    end_date = Array.new
    unless plan.features.nil?
      plan.features.each do |f|
        start_date << f.start_date
        end_date << f.end_date
      end
      return start_date.compact.min, end_date.compact.max
    else

    end
  end

  def get_task_list(hash)
    jira_task = Array.new
    hash.each_value do |v|
      jira_task << v[1]
    end
    return jira_task.join(',')
  end
end
