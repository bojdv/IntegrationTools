class TestPlansController < ApplicationController

  helper TestReportsHelper
  helper XmlSenderHelper
  $qa = {'bojdv' => 'Бойко Дина',
         'pekav' => 'Пехов Алексей',
         'kotvv' => 'Коцупенко Владимир',
         'shpae' => 'Шпинько Александр',
         'tkans' => 'Ткаченко Никита',
         'pasap' => 'Пащенко Анастасия',
         'e.vasilyeva' => 'Васильева Елена',
         'chivs' => 'Чиркова Вера',
         'uboav' => 'Уборский Алексей',
         'povao' => 'Пономарева Анжелика'}

  def index
    @egg_plans = TestPlan.where(:product_id => '10002')
    @fraud_plans = TestPlan.where(:product_id => '10006')
    @mt_plans = TestPlan.where(:product_id => '10007')
    @sn_plans = TestPlan.where(:product_id => '10003')
    @tir_plans = TestPlan.where(:product_id => '10001')
    @epos_plans = TestPlan.where(:product_id => '10008')
  end

  def new
    @new_plan = TestPlan.new
  end

  def create
    response_ajax("<h5>Не заполнены параметры:</h5>#{@empty_filds.join}", 4000) and return unless get_empty_fields(new_plan_params).empty?
    @create_plan = TestPlan.new(new_plan_params)
    if @create_plan.save
      respond_to do |format|
        format.js { render :js => "window.location= '#{url_for(test_plans_url)}'" }
      end
    else
      puts @create_plan.errors.full_messages.inspect
    end
  end

  def show
    @show_plan = TestPlan.find(params[:id])
    @new_feature = Feature.new
    if @show_plan.features.any?
      @backlog, @labels = get_list_of_value(@show_plan)
      @report = JIRA_Report.new(@backlog, @labels, $qa) # Общий отчет по тестированию
      unless @report.project_name.nil?
        @backlog_estimate = @report.select_backlog_estimate
        @project_estimate = @report.select_project_estimate
        @testing_worklogtime, @test_tasks = @report.select_test_worklog
        @defect_worklogtime, @consultation_worklogtime, @agreement_worklogtime, @def_tasks, @cons_tasks, @agree_tasks, @open_def, @open_def_bkv = @report.select_inner_tasks_worklog
        @deis_defect_worklogtime = @report.select_deis_worklog
        @deis_def, @deis_defect_true_count = @report.select_deis
        @other_tasks = @report.select_other_task
        @worklog_per_date, worklog_sum_per_date = @report.select_worklog_per_date
        start_test_date, end_test_date = find_max_test_dates(@show_plan)
        @worklog_sum_per_date = [worklog_sum_per_date,[{date: start_test_date, value: 0}, {date: end_test_date, value: @project_estimate}], [{date: start_test_date, value: 0}, {date: end_test_date, value: @backlog_estimate}]]
        if @backlog_estimate == 0
          @use_tester_estimate = false
        else if @backlog_estimate && @project_estimate == 0
               @use_tester_estimate = true
             else
               @project_estimate/@backlog_estimate >= 2.5 ? @use_tester_estimate = true : @use_tester_estimate = false
             end
        end
        @report_feature = Array.new
        @show_plan.features.each_with_index do |f, i|
          @report_feature[i] = JIRA_Report.new(f.backlog, f.labels, $qa)
        end
      end
    end
  end

  def edit
    @edit_plan = TestPlan.find(params[:id])
  end

  def update
    response_ajax("<h5>Не заполнены параметры:</h5>#{@empty_filds.join}", 4000) and return unless get_empty_fields(update_plan_params).empty?
    @update_plan = TestPlan.find(params[:id])
    if @update_plan.update(update_plan_params)
      respond_to do |format|
        format.js { render :js => "window.location= '#{url_for(test_plans_url)}'" }
      end
    else
      puts @update_plan.errors.full_messages.inspect
      render 'edit'
    end
  end

  def destroy
    @test_plan = TestPlan.find(params[:id])
    @test_plan.destroy
    redirect_to test_plans_path
  end

  def make_report
    begin
      @plan = TestPlan.find(report_params[:plan_id])
      testplan_report = TestPlanReport.new(@plan, report_params[:builds], report_params[:version], report_params[:minus], report_params[:rn])
      filepath = testplan_report.make_testplan_reports
      @plan.update_attributes(:report_url => filepath)
    rescue Exception => msg
      response_ajax("Ошибка! #{msg} #{msg.backtrace.join("\n")}", 10000) and return
    end
    link = "<a href=\"/test_plans/download_test_report?url=#{filepath}\">Скачать отчет</a>"
    response_ajax("Отчет успешно сформирован и доступен в списке планов тестирования!<br>#{link}", 10000)
  end

  def download_test_report
    #Dir.chdir "#{Rails.root}"
    send_file params[:url]
  end

  def safe_comment
    feature = Feature.find(params[:featureId])
    feature.update_attributes(:comment => params[:comment])
  end


  def tester
    a = rand(100000)
    puts a
  end

  private

  def new_plan_params
    params.require(:test_plan).permit(:name, :product_id, :finish_date, :status, :comment).merge(:user_id => current_user.id.inspect)
  end
  def update_plan_params
    params.require(:test_plan).permit(:name, :product_id, :finish_date, :status, :comment)
  end
  def report_params
    params.require(:report_params).permit(:plan_id, :builds, :version, :minus, :rn)
  end
end
