class TestPlansController < ApplicationController

  helper TestReportsHelper
  $qa = {'bojdv' => 'Бойко Дина',
         'pekav' => 'Пехов Алексей',
         'kotvv' => 'Коцупенко Владимир',
         'shpae' => 'Шпинько Александр',
         'tkans'=>'Ткаченко Никита',
         'pasap'=>'Пащенко Анастасия',
         'e.vasilyeva'=>'Васильева Елена'}

  def index
    @egg_plans = TestPlan.where(:product_id => '10002')
    @fraud_plans = TestPlan.where(:product_id => '10006')
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
        @backlog_estimate, @project_estimate = @report.select_backlog_project_estimate
        @testing_worklogtime, @test_tasks = @report.select_test_worklog
        @defect_worklogtime, @consultation_worklogtime, @agreement_worklogtime, @def_tasks, @cons_tasks, @agree_tasks, @open_def, @open_def_bkv = @report.select_inner_tasks_worklog
        @deis_defect_worklogtime = @report.select_deis_worklog
        @deis_def, @deis_defect_true_count = @report.select_deis
        @other_tasks = @report.select_other_task
        @worklog_per_date, worklog_sum_per_date = @report.select_worklog_per_date
        start_test_date, end_test_date = find_max_test_dates(@show_plan)
        @worklog_sum_per_date = [worklog_sum_per_date,[{date: start_test_date, value: 0}, {date: end_test_date, value: @project_estimate}]]


        @report_feature = Array.new
        @show_plan.features.each_with_index do |f, i|
          @report_feature[i] = JIRA_Report.new(f.backlog, f.labels, $qa)
        end
      end
    end
    # @data = MG.data_graphic({
    #                     title: "Downloads",
    #                     description: "This graphic shows a time-series of downloads.",
    #                     data: [{date: Date('2014-11-02'), value: 12},
    #                            {date:  Date('2014-11-02'),value: 18}],
    #                     width: 600,
    #                     height: 250,
    #                     target: '#downloads',
    #                     x_accessor: 'date',
    #                     y_accessor: 'value'
    #                 })
  end

  def edit
    @edit_plan = TestPlan.find(params[:id])
  end

  def update
    response_ajax("<h5>Не заполнены параметры:</h5>#{@empty_filds.join}", 4000) and return unless get_empty_fields(new_plan_params).empty?
    @update_plan = TestPlan.find(params[:id])
    if @update_plan.update(new_plan_params)
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
    puts test_plans_path
    @test_plan.destroy
    redirect_to test_plans_path
  end


  def tester
    @show_plan = TestPlan.find(10041)
    puts @show_plan.features.any?
  end

  private

  def new_plan_params
    params.require(:test_plan).permit(:name, :product_id, :finish_date, :status, :comment).merge(:user_id => current_user.id.inspect)
  end
end
