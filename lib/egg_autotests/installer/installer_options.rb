class InstallerOptions
  def initialize(build_version)
    @build_version = build_version
    @file_path = "#{Rails.root}/lib/egg_autotests/installer/#{@build_version}_installer_options.txt"
    @file_template = File.open("#{Rails.root}/lib/egg_autotests/installer/optionsEgg_template.txt")
    @finish_text = @file_template.read
    make_610 if @build_version.include?('6.10')
  end

  def make_mssql_options(db_name, host, port, user, password)
    find_text = <<EOF
# настройки подключения к СУБД Oracle
dbType=oracle
dbHost1=vm-corint
dbPort1=1521
dbSID1=corint
dbLogin1=egg_autotest_shpae
dbPassword1=egg_autotest_shpae

# настройки автоматического создания пользователя oracle
oracledbaLogin=sys as sysdba
oracledbaPassword=waaaaa
avtocreateoracle=true
EOF
    mssql_text = <<EOF
# настройки подключения к СУБД MSSQL
dbType=mssql
dbHost3=#{host}
dbPort3=#{port}
dbSID3=#{db_name}
dbLogin3=#{user}
dbPassword3=#{password}
mssqlTrustServerCertificate=false
mssqlEncrypt=false
EOF
    @finish_text.gsub!(find_text, mssql_text)
  end

  def make_oracle_options(db_user)
    find_text = <<EOF
dbLogin1=egg_autotest
dbPassword1=egg_autotest
EOF
    replace_text = <<EOF
dbLogin1=#{db_user}
dbPassword1=#{db_user}
EOF
    @finish_text.gsub!(find_text, replace_text)
  end

  def make_610
    components = ''
    @finish_text.each_line.with_index {|line, index| components = line if index == 18}
    @finish_text.gsub!(components, "enable-components=egg,DBcreate,ServiceMix,iaAmqComponent,saSpepComponent,saGmpComponent,iaFileGmpComponent,saZkhComponent,iaFileZkhComponent,saZkhPayeesComponent,iaFileMqGmpComponent,iaFileMqZkhComponent,saFnsEgripComponent,saFnsEgrulComponent\n")
    find_text = 'jvm_MaxMetaspaceSize=512'
    replace_text = <<EOF
jvm_PermSize=256
jvm_MaxPermSize=512
EOF
    @finish_text.gsub!(find_text, replace_text)
    find_text = 'ufebs_file_FormatVersion=2018.4.1'
    replace_text = 'ufebs_file_FormatVersion=2018.3.0'
    @finish_text.gsub!(find_text, replace_text)
    find_text = 'ufebs_file_PaymentVersion=1.16.6'
    replace_text = 'ufebs_file_PaymentVersion=1.16.5'
    @finish_text.gsub!(find_text, replace_text)
    find_text = 'zkh_file_cbr_psystem_url=http://www.cbr.ru/mcirabis/PluginInterface/GetBicCatalog.aspx?type=db'
    replace_text = 'zkh_file_cbr_psystem_url=http://www.cbr.ru/PSystem/system_p/'
    @finish_text.gsub!(find_text, replace_text)
    find_text = 'bik_download_type=zkh_file_cbr_url'
    replace_text = 'bik_download_type=zkh_file_cbr_psystem_url'
    @finish_text.gsub!(find_text, replace_text)
    temp = ''
    @finish_text.each_line.with_index {|line, index| temp <<  line if index < 263}
    @finish_text = temp
  end

  def write_file
    File.open(@file_path, 'w+') {|f| f.write(@finish_text)}
    @file_template.close
    @file_path if File.exist?(@file_path)
  end

  def move_options_file(log_path) # Перемещает файл с опциями в архив с логами
    FileUtils.move(@file_path, log_path) if File.exist?(@file_path)
  end
end
