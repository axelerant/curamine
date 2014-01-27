redmine_daily_status
====================

## About: 

A small project of team  size 2-5 or may be more, where team lead does send daily status email to product manager or other seniors and then it requires to maintain those emails archived in inbox. This daily status can be useful to compile monthly reports or similar use case were each one receiving this daily status email needs to save it,  if found important to him or her. Team using redmine needed a solution here not to consume inbox of everyone involved in all material w.r.t. project tracking. It should be maintained by one tool hence we decided to develop this simple plugin for us one might find this specific to a particular use case, and it is but yes one may find it ready to use and/or fork it to address his/her additional needs .

## Features

* Update today's status.
* View past days status.
* Daily status activity will be logged after daily status email sent.This activity will occured once.
* Watchers support is added.
* Email will send to all watchers or all project members in case of no watchers available to project daily status.


## How to Install:

To install the Daily Status, execute the following commands from the plugin directory of your redmine directory:

    git clone https://github.com/gs-lab/redmine_daily_status
    rake redmine:plugins:migrate NAME=redmine_daily_status

After the plugin is installed and the db migration completed, you will
need to restart redmine for the plugin to be available.

## How to Use:

* Enable the plugin from the settings of the project.

* Assigning permission to users for viewing and updating the status and also for adding and deleting watchers.

* User can only add/update the current date's status. He can only view the past dates project status.

* If user click the "send email to members" check box and then update the status. Email will be send to all project daily status watchers.If
no watchers available then email will send to all project members.

## How to UnInstall:

* rake redmine:plugins:migrate NAME=redmine_daily_status VERSION=0
* Remove the redmine_daily_status directory from the plugin directory and then restart redmine.
