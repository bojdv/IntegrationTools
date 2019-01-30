class ExternalDefectListController < ApplicationController
  include ExternalDefectListHelper

  def index
    update_external_defects
    @defects_sn = ExternalDefectList.where(labels: :ExternalDefectsAnalize_SN).order(created_at: :desc)
    @defects_egg = ExternalDefectList.where(labels: :ExternalDefectsAnalize_EGG).order(created_at: :desc)
    @defects_fa = ExternalDefectList.where(labels: :ExternalDefectsAnalize_FA).order(created_at: :desc)
    @defects_tir = ExternalDefectList.where(labels: :ExternalDefectsAnalize_TIR).order(created_at: :desc)
    @defects_mt = ExternalDefectList.where(labels: :ExternalDefectsAnalize_MT).order(created_at: :desc)
    @defects_epos = ExternalDefectList.where(labels: :ExternalDefectsAnalize_EPOS).order(created_at: :desc)
  end

  def update
    @defect = ExternalDefectList.find params[:id]

    respond_to do |format|
      if @defect.update_attributes(defect_params)
        format.json { respond_with_bip(@defect) }
      else
        format.json { respond_with_bip(@defect) }
      end
    end
  end

  private

  def defect_params
    params.require(:external_defect_list).permit(:reason)
  end
end
