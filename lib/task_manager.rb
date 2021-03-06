require 'omnifocus'

class TaskManager

  attr_reader :omnifocus, :all_tasks

  def initialize()
    @omnifocus = OmniFocus.new
    @all_tasks = @omnifocus.all_tasks
  end

  def flagged_tasks()
    tasks = []

    @all_tasks.each { |task|
      # next if task.completed.get || task.containing_project.get.status.get != :active
      next if task.completed.get || !containing_project_active?(task.containing_project)

      # puts "Checking #{task.name.get} (#{task.id_.get})"

      if task.flagged.get
        tasks << to_hash(task)
      end
    }

    tasks
  end

  def tasks_due_by(horizon)
    tasks = []
    @all_tasks.each { |task|
      next if (task.completed.get)

      due_date = ofdate_to_date(task.due_date)

      if due_date != nil
        comparison = horizon <=> due_date
        # puts "comparison = horizon <=> due_date:  #{comparison} = #{horizon} <=> #{due_date}"
        if horizon == nil || comparison > -1
          # puts "comparison = horizon <=> due_date:           #{comparison} = #{horizon} <=> #{due_date}"
          tasks << to_hash(task)
        end
      end
    }
    tasks
  end

  def close_tasks(ids)
    @to_close = @all_tasks.select { |task|
      ids.include?(task.id_.get) && !task.completed.get
    }

    closable = @to_close.size

    if closable > 0
      puts "Closing #{closable.to_s} cards"
      @to_close.each { |task|
        id = task.id_.get
        name = task.name.get
        puts "Closing task #{id}::#{name}"
        task.completed.set true
      }
    end
  end

  def projects
    @omnifocus.all_projects.select { |project|
      !project.singleton_action_holder.get
    }
  end

  def single_action_lists
    @omnifocus.all_projects.select { |project|
      status = project.status.get
      project.singleton_action_holder.get == true && status != :done && status != :dropped
    }
  end

  def remaining_projects
    @omnifocus.all_projects.select { |project|
      status = project.status.get
      project.singleton_action_holder.get == false && status != :done && status != :dropped
    }
  end

  def to_hash(task)
    name = get_text(task.name)
    note = get_text(task.note)
    due_date = ofdate_to_string(task.due_date)
    start_date = ofdate_to_string(task.defer_date)

    {:name => name, :external_id => task.id_.get, :context => task.context.name.get, :due_date => due_date, :start_date => start_date,
     :note => note}
  end

  def get_text(item)
    t = item.get
    t.force_encoding("UTF-8").encode("UTF-8")
  end

  def ofdate_to_string(d)
    date = nil
    if d.get != :missing_value
      date = Date.parse(d.get.to_s).strftime("%d/%m/%Y")
    end
    date
  end

  def ofdate_to_date(d)
    date = nil
    if d.get != :missing_value
      date = Date.parse(d.get.to_s)
    end
    date
  end

  def parse_date(date)
    if date != :missing_value && date != nil
      val = Date.parse(date.strftime('%Y/%m/%d'))
    else
      val = nil
    end
    val
  end

  def containing_project_active?(project)
    is_active = project.get.status.get == :active

    # puts "Project #{project.name.get} is active? #{is_active}"

    if is_active
      now = Date.today
      # puts "Checking if project #{project.name.get} is deferred beyond #{now}"
      defer_date = ofdate_to_date(project.get.defer_date)

      if defer_date != nil
        comp = now <=> defer_date
        # puts "#{now.to_s} > #{defer_date.to_s} (#{comp})"
        is_active = now >= defer_date
      end
    end

    is_active
  end
end