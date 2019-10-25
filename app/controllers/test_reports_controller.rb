class TestReportsController < ApplicationController

  def index

  end

  def run
    response_ajax_reports("Не заполнены метки") and return if report_params[:labels].empty?
    response_ajax_reports("Не указана задача с оценкой тестирования") and return if report_params[:backlog_keys].empty?
    worklog_autor = {'bojdv' => 'Бойко Дина', 'pekav' => 'Пехов Алексей', 'kotvv' => 'Коцупенко Владимир', 'shpae' => 'Шпинько Александр', 'tkans'=>'Ткаченко Никита', 'pasap'=>'Пащенко Анастасия', 'e.vasilyeva'=>'Васильева Елена', 'uboav' => 'Уборский Алексей', 'povao' => 'Пономарева Анжелика'}
    @report = JIRA_Report.new(report_params[:backlog_keys], report_params[:labels], worklog_autor)
    #@backlog_estimate, @project_estimate = @report.select_backlog_project_estimate
    @backlog_estimate = @report.select_backlog_estimate
    @project_estimate = @report.select_project_estimate
    @testing_worklogtime, @test_tasks = @report.select_test_worklog
    @defect_worklogtime, @consultation_worklogtime, @agreement_worklogtime, @def_tasks, @cons_tasks, @agree_tasks, @open_def, @open_def_bkv = @report.select_inner_tasks_worklog
    @deis_def, @deis_defect_true_count = @report.select_deis
    @deis_defect_worklogtime = @report.select_deis_worklog
    @other_tasks = @report.select_other_task
    @worklog_time, @worklog_autor = @report.select_worklog_date
    @worklog_autor = @report.get_value_from_hash(worklog_autor, @worklog_autor)

    #@defect_count, @defect_true_count, @defect_open_count, @defect_bkv_count,  = @report.select_not_worklogautor
    @build_links = @report.get_task_array(report_params[:build_link])
    @rn = report_params[:release_note]
    make_log_reports

    #@nullable_lebels.delete_if {|key, value| @nullable_lebels.values.count(value) > 1}
  end

  def make_log_reports # Метод формирующий файл отчета
    log_file_name = "Test_Report_#{Time.now.strftime('%Y-%m-%d(%H-%M-%S)')}.html" # формируем имя файла
    template = File.read("#{Rails.root}/lib/test_reports/report_template.html.erb") # читаем шаблон для лога
    result = ERB.new(template).result(binding)
    if not Dir.exist?("#{Rails.root}/lib/test_reports/reports/")
      Dir.mkdir("#{Rails.root}/lib/test_reports/reports/")
    end
    File.open("#{Rails.root}/lib/test_reports/reports/#{log_file_name}", 'w+') do |f|
      f.write result
    end
    respond_to do |format|
      format.js { render :js => "download_link_reports('#{log_file_name}')" }
    end
  end

  def download_log_reports
    #Dir.chdir "#{Rails.root}"
    send_file "#{Rails.root}/lib/test_reports/reports/#{params[:filename]}"
  end

  def tester
    worklog_autor = {0=>["[hi", '0'], 1=>["hi2", '999']}
    worklog_autor.delete_if {|key, value| value.to_s.include?('999')}
    puts worklog_autor

    autor = 'pekav', 'asa'
    autor2 = 'asa'
    puts autor.include?(autor2)
  end

  private
  def report_params
    params.require(:report_params).permit(:product,
                                          :summary,
                                          :labels,
                                          :backlog_keys,
                                          :test_plan,
                                          :test_rail,
                                          :test_data,
                                          :release_note,
                                          :build_link,
                                          :testing,
                                          :not_testing,
                                          :build_quality,
                                          :limitation)
  end
end
