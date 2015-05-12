# redmine-plugin-recurring-tasks

Plugin for Redmine project management software to configure recurring tasks. The plugin creates a new issue in Redmine for each recurrence, linking the duplicated issue as a related issue.

Released under GPLv2 in accordance with Redmine licensing.

## Features

* Any Redmine issue can have one or more associated recurrence schedules.
* Supported recurrence schedules are:
  * Every x days/weeks/months/years, e.g. every 1 day or every 3 months
  * The nth day of every x months, e.g. the 3rd of every month
  * The nth-to-last day of every x months, e.g. the 5th-to-last day of every 4 months
  * The nth week day of every x months, e.g. the 3rd Thursday of every 2 months
  * The nth-to-last week day of every x months, e.g. the 2nd-to-last Saturday of every 1 month
* All recurrence schedules can be set to recur on a fixed or flexible schedule.
  * Fixed: recurs whether the previous task completed or not
  * Flexible: recurs only if the previous task was complete
* View/Add/Edit/Delete issue recurrence permissions controlled via Redmine's native Roles and Permissions menu

## Installation

Follow standard Redmine plugin installation -- (barely) modified from http://www.redmine.org/projects/redmine/wiki/Plugins

1. Copy or clone the plugin directory into #{RAILS_ROOT}/plugins/recurring_tasks
   
   e.g. git clone https://github.com/nutso/redmine-plugin-recurring-tasks.git recurring_tasks

2. Rake the database migration (make a db backup before)

   e.g. rake redmine:plugins:migrate RAILS_ENV=production

3. Restart Redmine (or web server)

You should now be able to see the plugin list in Administration -> Plugins.
     
## Configuration
     
1. Set the check for recurrence via Crontab.

   Crontab example (running the check for recurrence every 6 hours):
   ```bash
   * */4 * * * /bin/sh "cd {path_to_redmine} && bundle exec rake RAILS_ENV=production redmine:recur_tasks" >> log/cron_rake.log 2>&1
   ```
   
2. Decide which role(s) should have the ability to view/add/edit/delete issue recurrence and configure accordingly in Redmine's permission manager (Administration > Roles and Permissions) 
   * View issue recurrence
   * Add issue recurrence
   * Edit issue recurrence
   * Delete issue recurrence (additionally requires the user to be a project member or administrator) 

## Upgrade or Migrate Plugin

Please check the Release Notes (ReleaseNotes.md) for substantive or breaking changes.

### Option 1: Git Pull
1. If you installed via git clone, you can just change to 
   the recurring_tasks directory and do a git pull to get the update

2. Run database migrations (make a db backup before)

   bundle exec rake redmine:plugins:migrate RAILS_ENV=production

3. Restart Redmine (or web server)

### Option 2: Remove and Re-install Plugin
1. Follow Remove or Uninstall Plugin instructions below
2. Follow Installation instructions above
   
## Remove or Uninstall Plugin

Follow standard Redmine plugin un-installation -- (barely) modified from http://www.redmine.org/projects/redmine/wiki/Plugins

1. Downgrade the database (make a db backup before)

   rake redmine:plugins:migrate NAME=recurring_tasks VERSION=0 RAILS_ENV=production

2. Remove the plugin from the plugins folder (#{RAILS_ROOT}/plugins)

3. Restart Redmine (or web server)