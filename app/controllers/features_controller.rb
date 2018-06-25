class FeaturesController < ApplicationController

  before_action :share_var

  def index

  end

  def new
    @plan = TestPlan.find(params[:test_plan_id])
    @new_feature = Feature.new
  end

  def create
    response_ajax("<h5>Не заполнены параметры:</h5>#{@empty_filds.join}", 4000) and return unless get_empty_fields(feature_params).empty?
    @plan = TestPlan.find(params[:test_plan_id])
    @feature = @plan.features.create(feature_params)
    if @feature.save
      respond_to do |format|
        format.js { render :js => "window.location= '#{url_for(@plan)}'" }
      end
    else
      puts @feature.errors.full_messages.inspect
    end
  end

  def edit
    @con = FeaturesController.new
    @plan = TestPlan.find(params[:test_plan_id])
    @feature = @plan.features.find(params[:id])
  end

  def update
    response_ajax("<h5>Не заполнены параметры:</h5>#{@empty_filds.join}", 4000) and return unless get_empty_fields(feature_params).empty?
    @update_feature = Feature.find(params[:id])
    @plan = TestPlan.find(@update_feature.test_plan_id)
    if @update_feature.update(feature_params)
      respond_to do |format|
        format.js { render :js => "window.location= '#{url_for(@plan)}'" }
      end
    else
      puts @update_feature.errors.full_messages.inspect
      render 'edit'
    end
  end

  def show

  end

  def destroy
    @test_plan = TestPlan.find(params[:test_plan_id])
    @feature = @test_plan.features.find(params[:feature_id])
    @feature.destroy
    redirect_to test_plan_path(@test_plan)
  end


  private
  def feature_params
    params.require(:feature).permit(:name, :labels, :project_name, :backlog, :feature_url, :test_scope, :tz, :milestone, :testcases, :analytic => [], :developer => [], :manager => [], :qa => [])
  end

  def share_var
    @developer = {'isa' => 'Ильин Сергей',
                   'BerRM' => 'Беркович Роман',
                   'ByrAY' => 'Бырков Андрей',
                   'UsoAV' => 'Усольцев Андрей',
                   'GriGV' => 'Григорьев Георгий',
                   'LukAS' => 'Луковников Александр',
                   'ldi' => 'Ляпин Дмитрий' }
    @analytic = {'ZakDA' => 'Захарченко Дмитрий',
                  'BalYV' => 'Балакин Юрий',
                  's.ledentsov' => 'Леденцов Сергей',
                  'ldi' => 'Ляпин Дмитрий'}
    @manager = {'KosAS' => 'Космин Александр',
                 'KhmVM' => 'Хмельницкий Валерий',
                 'GolAV' => 'Головченко Андрей',
                 'ldi' => 'Ляпин Дмитрий'}
  end
end
