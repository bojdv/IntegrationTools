module TestReportsHelper

  def response_ajax_reports(text, time = 3000)
    respond_to do |format|
      format.js {render :js => "open_modal(#{text.inspect}, #{time.inspect});"}
    end
  end

  class JIRA_Report
    def initialize(backlog_keys, labels, worklog_autor)
      @backlog_keys = get_task_key(backlog_keys)
      @backlog_numbers = get_task_number(backlog_keys)
      @labels = get_task_list(labels)
      @project_keys, @project_numbers, @project_name, @project_key = select_prjUrlKeyName
      @worklog_autor = get_task_list(worklog_autor.keys.join(','))
      @projects = split_task(@project_keys.split(','), @project_numbers.split(','))
    end
    attr_accessor :backlog_keys, :backlog_numbers, :project_name, :project_numbers, :project_keys, :projects

    # Функциональные методы

    def get_task_number(value) #Получает строку.
      array = value.scan(/\d+/)
      array.collect! {|elem| "'#{elem.strip}'"}
      array.join(',')
    end

    def get_task_key(value) #Получает строку.
      array = value.scan(/[A-Z]+/)
      array.collect! {|elem| "'#{elem.strip}'"}
      array.join(',')
    end

    def get_task_array(value) # Получает строку. Отдает архив со списком задач
      array = value.split(',')
      array.map!(&:strip)
    end

    def get_task_list(value) # Получает строку. Отдает список через запятую
      array = value.split(',')
      array.collect! {|elem| "'#{elem.strip}'"}
      array.join(',')
    end

    def split_task(keys, numbers) # Получает архив, выдает строку через запятую.
      array = Array.new
      keys.each_index  do |index|
        array << keys[index] + '-' + numbers[index]
      end
      return array.join(',').delete('\'')
    end

    def get_value_from_hash(hash, array) # Принимает хэш и архив и возвращает строку с value хеша, где ключ = элемент массива
      valueArray = Array.new
      hash.map do |key, value|
        array.each do |element|
          valueArray << value if key == element
        end
      end
      return valueArray.join('<br>')
    end


    # СЕЛЕКТЫ!

    def select_all
      select = <<-query
      SELECT summary, issue_type, project_key, issuenum, COALESCE(exptest, 0) as exptest, sum(NVL(prjtest,0)) as prjtest, NVL(O_Estimate,0) as O_Estimate, sum(NVL(worklogtime,0)) as worklogtime, status, reasolution, priority
      FROM view_itools_report
      WHERE
      (project_key in (#{@backlog_keys}, #{@project_keys}) and issuenum in (#{@backlog_numbers}, #{@project_numbers})) or (issue_type in ('Дефект', 'Консультация', 'Согласование', 'Тестирование') and label in (#{@labels}) and (worklogautor in (#{@worklog_autor}) or worklogautor IS NULL))
      GROUP BY summary, issue_type, project_key, issuenum, status, reasolution, priority, O_Estimate, exptest
      ORDER BY issuenum asc
      query
      begin
        url = "jdbc:oracle:thin:@jira-db.bss.lan:1521:JIRACLUSTER"
        connection = java.sql.DriverManager.getConnection(url, "JIRA_GUEST_PROM_PEKAV", "JIRA_GUEST_PROM_PEKAV");
        stmt = connection.create_statement
        #puts "Select:\n" + select
        rs = stmt.execute_query(select)
        backlog_estimate = Array.new
        project_estimate  = Array.new
        testing_worklogtime = Array.new
        defect_worklogtime = Array.new
        consultation_worklogtime = Array.new
        agreement_worklogtime = Array.new
        defect_count = Array.new
        defect_true_count = Array.new
        defect_open_count = Array.new
        defect_bkv_count = Array.new
        test_tasks = Hash.new
        def_tasks = Hash.new
        cons_tasks = Hash.new
        test_count = 1
        def_count = 1
        cons_count = 1
        while (rs.next()) do
          case rs.getString('issue_type')
            when 'Оценка эксперта'
              backlog_estimate << rs.getString('exptest')
            when 'Проект'
              project_estimate << rs.getString('prjtest')
            when 'Дефект'
              def_tasks[def_count] = Array.new
              def_tasks[def_count] = [rs.getString('summary'), "#{rs.getString('project_key')}-#{rs.getString('issuenum')}", rs.getString('worklogtime'), rs.getString('status')]
              def_count+=1
              defect_count << rs.getString('project_key') +'-'+ rs.getString('issuenum')
              defect_true_count << (rs.getString('project_key') +'-'+ rs.getString('issuenum')) if rs.getString('reasolution') == 'Выполнен' || rs.getString('reasolution') == 'Отложен' || rs.getString('reasolution') == 'Невозможно исправить'
              defect_open_count << rs.getString('project_key') +'-'+ rs.getString('issuenum') if rs.getString('status') != 'Закрыт'
              defect_bkv_count << rs.getString('project_key') +'-'+ rs.getString('issuenum') if (rs.getString('priority') == 'Блокирует' || rs.getString('priority') == 'Критический' || rs.getString('priority') == 'Высокий') and rs.getString('status') != 'Закрыт'
              defect_worklogtime << rs.getString('worklogtime')
            when 'Консультация'
              cons_tasks[cons_count] = Array.new
              cons_tasks[cons_count] = [rs.getString('summary'), "#{rs.getString('project_key')}-#{rs.getString('issuenum')}", rs.getString('worklogtime'), rs.getString('status')]
              cons_count+=1
              consultation_worklogtime << rs.getString('worklogtime')
            when 'Согласование'
              agreement_worklogtime << rs.getString('worklogtime')
            when 'Тестирование'
              test_tasks[test_count] = Array.new
              test_tasks[test_count] = [rs.getString('summary'), "#{rs.getString('project_key')}-#{rs.getString('issuenum')}", rs.getString('O_Estimate'), rs.getString('worklogtime'), rs.getString('status')]
              testing_worklogtime << rs.getString('worklogtime')
              test_count+=1
          end
        end
      ensure
        stmt.close
        connection.close
      end
      return backlog_estimate.map(&:to_i).sum,
          project_estimate.map(&:to_i).sum,
          testing_worklogtime.map(&:to_i).sum,
          defect_worklogtime.map(&:to_i).sum,
          consultation_worklogtime.map(&:to_i).sum,
          agreement_worklogtime.map(&:to_i).sum,
          defect_count,
          defect_true_count,
          defect_open_count,
          defect_bkv_count,
          test_tasks,
          def_tasks,
          cons_tasks
    end

    def select_custom
      select = <<-query
      SELECT summary, issue_type, project_key, issuenum, status, label, etap, reporter, worklogdate, worklogautor
      FROM view_itools_report
      WHERE project_name in (#{@project_name}) and (issue_type in ('Дефект', 'Консультация', 'Согласование', 'Тестирование') and (worklogautor in (#{@worklog_autor}) or (reporter in (#{@worklog_autor}))))
      GROUP BY summary, issue_type, project_key, issuenum, status, label, etap, reporter, worklogdate, worklogautor
      ORDER BY issue_type desc
      query
      begin
        url = "jdbc:oracle:thin:@jira-db.bss.lan:1521:JIRACLUSTER"
        connection = java.sql.DriverManager.getConnection(url, "JIRA_GUEST_PROM_PEKAV", "JIRA_GUEST_PROM_PEKAV");
        stmt = connection.create_statement
        rs = stmt.execute_query(select)
        nullable_lebels = Hash.new
        nullable_count = 0
        worklog_time = Array.new
        worklog_autor = Array.new
        while (rs.next()) do
          label = rs.getString('label')
          if label.nil? and rs.getString('etap') != 'Приемка ДЭИС'
            nullable_lebels[nullable_count] = Array.new
            nullable_lebels[nullable_count] = [rs.getString('summary'), "#{rs.getString('project_key')}-#{rs.getString('issuenum')}", rs.getString('issue_type'), rs.getString('status')]
            nullable_count+=1
          end
          worklog_time << rs.getString('worklogdate')
          worklog_autor << rs.getString('worklogautor')
        end
      ensure
        stmt.close
        connection.close
      end
      return nullable_lebels, worklog_time, worklog_autor.uniq
    end

    def select_deis
      select = <<-query
      SELECT summary, issue_type, project_key, issuenum, status, label, etap, reasolution
      FROM view_itools_report
      WHERE project_name in (#{@project_name}) and issue_type in ('Дефект', 'Консультация')
      GROUP BY summary, issue_type, project_key, issuenum, status, label, etap, reasolution
      ORDER BY issue_type desc
      query
      begin
        url = "jdbc:oracle:thin:@jira-db.bss.lan:1521:JIRACLUSTER"
        connection = java.sql.DriverManager.getConnection(url, "JIRA_GUEST_PROM_PEKAV", "JIRA_GUEST_PROM_PEKAV");
        stmt = connection.create_statement
        rs = stmt.execute_query(select)
        deis_def = Hash.new
        deis_def_count = 1
        while (rs.next()) do
              if rs.getString('etap') == 'Приемка ДЭИС'
                deis_def[deis_def_count] = Array.new
                deis_def[deis_def_count] = [rs.getString('summary'), "#{rs.getString('project_key')}-#{rs.getString('issuenum')}", rs.getString('issue_type'), rs.getString('reasolution'),rs.getString('status')]
                deis_def_count+=1
              end
        end
      ensure
        stmt.close
        connection.close
      end
      return deis_def
    end

    def select_prjUrlKeyName
      select = <<-query
      SELECT project_key, project_url, project_name
      FROM view_itools_report
      WHERE issue_type in ('Дефект', 'Консультация', 'Тестирование') and label in (#{@labels})
      query
      begin
        url = "jdbc:oracle:thin:@jira-db.bss.lan:1521:JIRACLUSTER"
        connection = java.sql.DriverManager.getConnection(url, "JIRA_GUEST_PROM_PEKAV", "JIRA_GUEST_PROM_PEKAV");
        stmt = connection.create_statement
        rs = stmt.execute_query(select)
        project_url = Array.new
        project_key = Array.new
        project_name = Array.new
        while (rs.next()) do
          project_url << rs.getString('project_url')
          project_name << rs.getString('project_name')
          project_key << rs.getString('project_key')
        end
      ensure
        stmt.close
        connection.close
      end
      project_url.uniq!
      prj_key = get_task_key(project_url.join(','))
      prj_number = get_task_number(project_url.join(','))
      return prj_key,  prj_number, get_task_list(project_name.uniq.join(',')), get_task_list(project_key.uniq.join(','))
    end
  end

=begin
  def split_tasks(task) # Метод принимает строку со списком задач, например: BSSSNAB-50, BSS-55
    array = task.split(',') # расщепляем строку на элементы массива. Строка разбивается по запятой.
    array.collect! {|element| element.strip.split('-') || element} # Удаляем у каждого элемента пробелы и разбиваем элемент на два, если в нем есть дефис
    Hash[*array.flatten!] # Схлопываем двумерный массив в одномерный и возвращаем хэш, например: {"BSSSNAB"=>"50", "BSS"=>"55"}.
  end
=end
end
