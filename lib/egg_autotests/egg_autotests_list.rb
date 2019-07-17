include EggAutoTestsHelper
require 'rexml/document'
include REXML
require 'savon'
# Подключаем классы автотестов
require_dependency "#{Rails.root}/lib/egg_autotests/ia_ActiveMQ"
require_dependency "#{Rails.root}/lib/egg_autotests/ia_UFEBS_GIS_GMP"
require_dependency "#{Rails.root}/lib/egg_autotests/sa_GIS_GMP"
require_dependency "#{Rails.root}/lib/egg_autotests/sa_GIS_ZKH"
require_dependency "#{Rails.root}/lib/egg_autotests/ia_UFEBS_GIS_ZKH"
require_dependency "#{Rails.root}/lib/egg_autotests/ia_ZKH_Loader"
require_dependency "#{Rails.root}/lib/egg_autotests/ia_JPMorgan_GIS_GMP"
require_dependency "#{Rails.root}/lib/egg_autotests/ia_JPMorgan_GIS_ZKH"
require_dependency "#{Rails.root}/lib/egg_autotests/sa_SPEP"
require_dependency "#{Rails.root}/lib/egg_autotests/sa_FNS_EGRIP"
require_dependency "#{Rails.root}/lib/egg_autotests/SA_FNS_EGRUL"
require_dependency "#{Rails.root}/lib/egg_autotests/SA_EFRSB"
require_dependency "#{Rails.root}/lib/egg_autotests/SA_ESIA_SMEV3"
require_dependency "#{Rails.root}/lib/egg_autotests/SA_GIS_GMP_SMEV3"
require_dependency "#{Rails.root}/lib/egg_autotests/IA_UFEBS_GIS_GMP_SMEV3"
require_dependency "#{Rails.root}/lib/egg_autotests/SA_GIS_ZKH_SMEV3"
require_dependency "#{Rails.root}/lib/egg_autotests/IA_UFEBS_GIS_ZKH_SMEV3"

class EggAutotestsList

  def initialize(egg_version, try_count, egg_dir, db_username, build_version) # Передаем переменные класса
    # Переменные для всех тестов
    @pass_menu_color = '#b3ffcc' # цвет пункта меню при успешном выполнении (зеленый)
    @fail_menu_color = '#ff3333' # цвет пункта менюпри неуспешном выполнении (красный)
    @not_find_xml = 'XML не найдена' # сообщение об ошибке, если не нашли XML в БД
    @not_receive_answer = 'Не получили ответ от eGG:(' # сообщение оь ошибке, если не получили ответ от еГГ
    @egg_version = egg_version # версия инсталлируемого продукта
    @try_count = try_count.to_i # количество попыток достучаться до СМЭВ, заполняется в UI
    @egg_dir = egg_dir # каталог установки ЕГГ
    @db_username = db_username # имя схемы Oracle на которую ставится БД еГГ
    @build_version = build_version
    case # Определяем версию форматов по версии сборки
      when build_version.include?('6.11')
        @ufebs_version = '2019.1.1' #\app\smx\resourceapp.war\wsdl\XSD\CBR\х\ed\cbr_ed101_vх.xsd
      else
        @ufebs_version = '2019.3.1'
    end
  end

  def runTest_egg(components) # Запуск автотестов

    if components.include?('ИА УФЭБС (ГИС ЖКХ)') # Проверяем содержит ли переданный массив нужный пункт меню
      ia_ufebs_gis_gkh = IA_UFEBS_GIS_ZKH.new(@pass_menu_color, @fail_menu_color, @not_find_xml, @not_receive_answer, @egg_version, @try_count, @ufebs_version, @db_username)
      ia_ufebs_gis_gkh.ed101_test
      ia_ufebs_gis_gkh.ed108_test
      ia_ufebs_gis_gkh.packetepd_test
    end
    if components.include?('СА ГИС ЖКХ')
      sa_gis_zkh = SA_GIS_ZKH.new(@pass_menu_color, @fail_menu_color, @not_find_xml, @not_receive_answer, @egg_version, @try_count, @db_username)
      sa_gis_zkh.paymentRequest_test
      sa_gis_zkh.paymentCancellation_test
      sa_gis_zkh.paymentDetails_test
    end
    if components.include?('ИА УФЭБС (ГИС ГМП)')
      ia_ufebs_gis_gmp = IA_UFEBS_GIS_GMP.new(@pass_menu_color, @fail_menu_color, @not_find_xml, @not_receive_answer, @egg_version, @try_count, @ufebs_version)
      ia_ufebs_gis_gmp.ed101_test
      ia_ufebs_gis_gmp.ed104_test
      ia_ufebs_gis_gmp.ed105_test
      ia_ufebs_gis_gmp.ed108_test
      ia_ufebs_gis_gmp.packetepd_test
      ia_ufebs_gis_gmp.ed101_change
      ia_ufebs_gis_gmp.ed101_delete
    end
    if components.include?('ИА Active MQ')
      ia_amq = IA_ActiveMQ.new(@pass_menu_color, @fail_menu_color, @not_find_xml, @not_receive_answer, @egg_version, @try_count)
      ia_amq.run_RequestMessage
    end
    if components.include?('СА ГИС ГМП')
      sa_gis_gmp = SA_GIS_GMP.new(@pass_menu_color, @fail_menu_color, @not_find_xml, @not_receive_answer, @egg_version, @try_count)
      sa_gis_gmp.run_RequestMessage
      sa_gis_gmp.run_Payment_refinement
      sa_gis_gmp.run_Payment_cancellation
      sa_gis_gmp.run_Charges
    end
    if components.include?('ИА JPMorgan (ГИС ГМП)')
      ia_jpmorgan_gis_gmp = IA_JPMorgan_GIS_GMP.new(@pass_menu_color, @fail_menu_color, @not_find_xml, @not_receive_answer, @egg_version, @try_count)
      ia_jpmorgan_gis_gmp.payment
    end
    if components.include?('ИА JPMorgan (ГИС ЖКХ)')
      ia_jpmorgan_gis_zkh = IA_JPMorgan_GIS_ZKH.new(@pass_menu_color, @fail_menu_color, @not_find_xml, @not_receive_answer, @egg_version, @try_count)
      ia_jpmorgan_gis_zkh.payment
      ia_jpmorgan_gis_zkh.payment_cancellation
    end
    if components.include?('ИА ZKH-Loader/СА ZkhPayees')
      ia_zkh_loader = IA_ZKH_Loader.new(@pass_menu_color, @fail_menu_color, @egg_version, @egg_dir, @db_username)
      ia_zkh_loader.providerCatalogFile_test
      ia_zkh_loader.providerCatalogMQ_test
    end
    if components.include?('СА SPEP')
      sa_spep = SA_SPEP.new(@pass_menu_color, @fail_menu_color, @not_find_xml, @not_receive_answer, @egg_version, @try_count)
      sa_spep.verifycertificate_ok
      sa_spep.verifycertificatewithreport
      sa_spep.verifycertificate_crl
      sa_spep.verifycertificate_nocert
    end
    if components.include?('СА ФНС ЕГРИП')
      sa_gis_gmp = SA_FNS_EGRIP.new(@pass_menu_color, @fail_menu_color, @not_find_xml, @not_receive_answer, @egg_version, @try_count)
      sa_gis_gmp.request_EGRIP_v405
    end
    if components.include?('СА ФНС ЕГРЮЛ')
      sa_gis_gmp = SA_FNS_EGRUL.new(@pass_menu_color, @fail_menu_color, @not_find_xml, @not_receive_answer, @egg_version, @try_count)
      sa_gis_gmp.request_EGRUL_v405
    end
    if components.include?('СА EFRSB (Банкроты)')
      sa_efrsb = SA_EFRSB.new(@pass_menu_color, @fail_menu_color, @not_find_xml, @not_receive_answer, @egg_version, @try_count)
      sa_efrsb.searchByCode
      sa_efrsb.searchCompany
      sa_efrsb.searchCompanyByInn
      sa_efrsb.searchCompanyByOgrn
      sa_efrsb.searchDebtorByOgrnip
      sa_efrsb.searchPerson
      sa_efrsb.searchPersonByInn
      sa_efrsb.searchPersonBySnils
    end
    if components.include?('СА ЕСИА СМЭВ3')
      sa_esia_smev3 = SA_ESIA_SMEV3.new(@pass_menu_color, @fail_menu_color, @not_find_xml, @not_receive_answer, @egg_version, @try_count)
      sa_esia_smev3.request_Confirm
      sa_esia_smev3.request_DELETE_ACCOUNT
      sa_esia_smev3.request_FIND_ACCOUNT
      sa_esia_smev3.request_RECOVER
      sa_esia_smev3.request_REGISTER
      sa_esia_smev3.request_REGISTER_BY_SIMPLIFIED
      sa_esia_smev3.request_REGISTER_CERTIFICATE
      sa_esia_smev3.request_REGISTER_CHILD
      sa_esia_smev3.request_UPRID
    end
    if components.include?('СА ГИС ГМП СМЭВ3')
      sa_gis_gmp_smev3 = SA_GIS_GMP_SMEV3.new(@pass_menu_color, @fail_menu_color, @not_find_xml, @not_receive_answer, @egg_version, @try_count)
      sa_gis_gmp_smev3.payment_new
      sa_gis_gmp_smev3.payment_refinement
      sa_gis_gmp_smev3.payment_cancellation
      sa_gis_gmp_smev3.payment_change_delete
      sa_gis_gmp_smev3.charges
    end
    if components.include?('ИА УФЭБС (ГИС ГМП СМЭВ3)')
      ia_ufebs_gis_gmp_smev3 = IA_UFEBS_GIS_GMP_SMEV3.new(@pass_menu_color, @fail_menu_color, @not_find_xml, @not_receive_answer, @egg_version, @try_count, @ufebs_version)
      ia_ufebs_gis_gmp_smev3.ed101_test
      ia_ufebs_gis_gmp_smev3.ed104_test
      ia_ufebs_gis_gmp_smev3.ed105_test
      ia_ufebs_gis_gmp_smev3.ed108_test
      ia_ufebs_gis_gmp_smev3.packetepd_test
      ia_ufebs_gis_gmp_smev3.ed101_change
      ia_ufebs_gis_gmp_smev3.ed101_delete
      ia_ufebs_gis_gmp_smev3.ed101_change_delete
    end
    if components.include?('СА ГИС ЖКХ СМЭВ3')
      sa_gis_zkh_smev3 = SA_GIS_ZKH_SMEV3.new(@pass_menu_color, @fail_menu_color, @not_find_xml, @not_receive_answer, @egg_version, @try_count)
      sa_gis_zkh_smev3.payment
      sa_gis_zkh_smev3.payment_cancellation
      sa_gis_zkh_smev3.payment_details
    end
    if components.include?('ИА УФЭБС (ГИС ЖКХ СМЭВ3)')
      ia_ufebs_gis_zkh_smev3 = IA_UFEBS_GIS_ZKH_SMEV3.new(@pass_menu_color, @fail_menu_color, @not_find_xml, @not_receive_answer, @egg_version, @try_count, @ufebs_version)
      ia_ufebs_gis_zkh_smev3.ed101_test
      ia_ufebs_gis_zkh_smev3.ed104_test
      ia_ufebs_gis_zkh_smev3.ed105_test
      ia_ufebs_gis_zkh_smev3.ed108_test
      ia_ufebs_gis_zkh_smev3.ed101_delete
      ia_ufebs_gis_zkh_smev3.packetepd_test
    end
  end
end
