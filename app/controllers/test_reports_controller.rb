class TestReportsController < ApplicationController
  def index

  end

  def run
    response_ajax_reports("Не заполнены метки") and return if report_params[:labels].empty?
    response_ajax_reports("Не указана задача с оценкой тестирования") and return if report_params[:backlog_keys].empty?
    worklog_autor = {'bojdv' => 'Бойко Дина', 'pekav' => 'Пехов Алексей', 'kotvv' => 'Коцупенко Владимир', 'shpae' => 'Шпинько Александр', 'tkans'=>'Ткаченко Никита'}
    @report = JIRA_Report.new(report_params[:backlog_keys], report_params[:labels], worklog_autor)
    @backlog_estimate, @project_estimate, @testing_worklogtime, @defect_worklogtime, @consultation_worklogtime, @agreement_worklogtime, @defect_count, @defect_true_count, @defect_open_count, @defect_bkv_count, @test_tasks, @def_tasks, @cons_tasks = @report.select_all
    @build_links = @report.get_task_array(report_params[:build_link])
    @nullable_lebels, @worklog_time, @worklog_autor = @report.select_custom
    @nullable_lebels
    @worklog_autor = @report.get_value_from_hash(worklog_autor, @worklog_autor)
    @deis_def = @report.select_deis
    make_log_reports
  end

  def make_log_reports # Метод формирующий файл отчета
    log_file_name = "Test_Report_#{Time.now.strftime('%Y-%m-%d(%H-%M-%S)')}.html" # формируем имя файла
    template = File.read("#{Rails.root}/lib/test_reports/report_template.html.erb") # читаем шаблон для лога
    result = ERB.new(template).result(binding)
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
    worklog_autor = {0=>["[eGG ASM 6.10.27] Error resolving artifactcom.oracle:ojdbc7:jar:12.1.0.1.0", "BSSEGGBH-42", "Р”РµС„РµРєС‚", "Р—Р°РєСЂС‹С‚"], 1=>["[eGG ASM 6.10.27] Error resolving artifactcom.oracle:ojdbc7:jar:12.1.0.1.0", "BSSEGGBH-42", "Р”РµС„РµРєС‚", "Р—Р°РєСЂС‹С‚"]}
    puts worklog_autor.to_a.uniq.to_h
  end

  private
  def report_params
    params.require(:report_params).permit(:product,
                                          :summary,
                                          :labels,
                                          :backlog_keys,
                                          :test_plan,
                                          :test_rail,
                                          :build_version,
                                          :build_link,
                                          :testing,
                                          :not_testing,
                                          :build_quality,
                                          :build_intention,
                                          :limitation)
  end
end
