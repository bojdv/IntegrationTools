include EggAutoTestsHelper
require 'rexml/document'
include REXML
require 'savon'
require_dependency "#{Rails.root}/lib/egg_autotests/ia_ActiveMQ"
require_dependency "#{Rails.root}/lib/egg_autotests/ia_UFEBS_GIS_GMP"
require_dependency "#{Rails.root}/lib/egg_autotests/sa_GIS_GMP"
require_dependency "#{Rails.root}/lib/egg_autotests/sa_GIS_GKH"
require_dependency "#{Rails.root}/lib/egg_autotests/ia_UFEBS_GIS_GKH"

class EggAutotestsList

  def initialize(egg_version, try_count)
    # Переменные для всех тестов
    @pass_menu_color = '#b3ffcc'
    @fail_menu_color = '#ff3333'
    @not_find_xml = 'XML не найдена'
    @not_receive_answer = 'Не получили ответ от eGG:('
    @egg_version = egg_version
    @try_count = try_count.to_i
  end

  def runTest_egg(components)

    if components.include?('Проверка ИА Active MQ')
      ia_amq = IA_ActiveMQ.new(@pass_menu_color, @fail_menu_color, @not_find_xml, @not_receive_answer, @egg_version, @try_count)
      ia_amq.run_RequestMessage
    end

    if components.include?('Проверка ИА УФЭБС (ГИС ГМП)')
      ia_ufebs_gis_gmp = IA_UFEBS_GIS_GMP.new(@pass_menu_color, @fail_menu_color, @not_find_xml, @not_receive_answer, @egg_version, @try_count)
      ia_ufebs_gis_gmp.ed101_test
      ia_ufebs_gis_gmp.ed104_test
      ia_ufebs_gis_gmp.ed105_test
      ia_ufebs_gis_gmp.ed108_test
      ia_ufebs_gis_gmp.packetepd_test
    end

    if components.include?('Проверка СА ГИС ГМП')
      sa_gis_gmp = SA_GIS_GMP.new(@pass_menu_color, @fail_menu_color, @not_find_xml, @not_receive_answer, @egg_version, @try_count)
      sa_gis_gmp.run_RequestMessage
      sa_gis_gmp.run_Charges
    end

    if components.include?('Проверка СА ГИС ЖКХ')
      sa_gis_zkh = SA_GIS_ZKH.new(@pass_menu_color, @fail_menu_color, @not_find_xml, @not_receive_answer, @egg_version, @try_count)
      sa_gis_zkh.paymentRequest_test
      sa_gis_zkh.paymentCancellation_test
      sa_gis_zkh.paymentDetails_test
    end

    if components.include?('Проверка ИА УФЭБС (ГИС ЖКХ)')
      ia_ufebs_gis_gkh = IA_UFEBS_GIS_GKH.new(@pass_menu_color, @fail_menu_color, @not_find_xml, @not_receive_answer, @egg_version, @try_count)
      ia_ufebs_gis_gkh.providerCatalog_test
      ia_ufebs_gis_gkh.ed101_test
      ia_ufebs_gis_gkh.ed108_test
      ia_ufebs_gis_gkh.packetepd_test
    end
  end
end