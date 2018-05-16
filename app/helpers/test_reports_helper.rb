module TestReportsHelper

  def response_ajax_reports(text, time = 3000)
    respond_to do |format|
      format.js {render :js => "open_modal(#{text.inspect}, #{time.inspect});"}
    end
  end

  class JIRA_Report
    def initialize(label, key, project_name)
      @labels = label
    end

    def select_data
      select = <<-query
SELECT * 
FROM view_itools_report
WHERE 
label in ('sn_activemq_2.12', 'sn_fcm_2.12')
or
(project_key in ('BACKLOG', 'PRJ') and issuenum in ('16836', '18509', '25150'))
or
project_name in ('25150_BSS_2_STDv2.12')

      query
    end
  end

  def select_data1
    url = "jdbc:oracle:thin:@vm-jiratest-db.bss.lan:1521:JIRATEST"
    connection = java.sql.DriverManager.getConnection(url, "JIRA_PekAV", "JIRA_PekAV");
    stmt = connection.create_statement
    select  = <<-eos
    select
-- JIRAISSUE
ji.id,
ji.issuenum,
ji.reporter, 
ji.assignee, 
ji.creator, 
ji.summary, 
ji.description, 
ji.created, 
ji.updated, 
ji.duedate, 
ji.timeoriginalestimate/60 as O_Estimate, --Оценка (минуты)
ji.timeestimate/60 as T_Estimate, --Осталось времени (минуты)
ROUND(ji.timespent/60, 3) as Timespent,  --Списано времени (минуты)
-- PROJECT
proj.pname as Project_name, -- Название проекта
proj.pkey as Project_key, -- Код проекта
-- ISSUETYPE
it.pname as Issue_type, -- Тип задачи
-- PRIORITY
pri.pname as Priority, -- Приоритет
-- Reasolution
pri.pname as Reasolution, -- Резолюция
-- ISSUESTATUS
stat.pname as Status,
-- LABEL
label.label as Label,
-- WORKLOG
worklog.author as WorklogAutor,
ROUND(worklog.timeworked/60, 3) as WorklogTime,
--USERNAME
cwd_user.display_name

from  jiratest1.jiraissue ji

join jiratest1.project proj
on ji.project = proj.id
join jiratest1.issuetype it
on ji.issuetype = it.id
join jiratest1.priority pri
on ji.priority = pri.id
left join jiratest1.resolution res
on ji.resolution = res.id
join jiratest1.issuestatus stat
on ji.issuestatus = stat.id
left join jiratest1.label label
on ji.id = label.issue
left join jiratest1.worklog worklog
on ji.id = worklog.issueid
left join jiratest1.cwd_user cwd_user
on ji.reporter = cwd_user.lower_user_name and cwd_user.directory_id = '10101'

where ((ji.issuetype in ('10402' , '10307', '10318', '10306', '10700', '12201', '12200', '12100', '12300') and ji.created > '01.06.2017')
or
(ji.issuetype in ('10300', '10304') and ji.created > ADD_MONTHS(SYSDATE, -4)))

-- where (ji.issuetype in ('Заявка', 'Согласование', 'Заявка на бронирование', 'Тестирование', 'Доработка', 'Заявка на оценку', 'Оценка эксперта', 'Проект', 'ЗНИ') and ji.created > '01.01.2017')
-- or
-- (ji.issuetype in ('Дефект', 'Консультация') and ji.created > '01.01.2017')
    eos

    rs = stmt.execute_query(select)
    while (rs.next()) do
      reporter = rs.getString('reporter')
      summary = rs.getString('summary')
      puts "Reporter: " + reporter.to_s + ",Summary: " + summary.to_s
    end
    stmt.close
    connection.close
  end
end
