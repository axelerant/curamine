redmine = File.join(File.dirname(__FILE__), 'redmine')

desc 'Run tests'
task :test do
  Dir.chdir(redmine) do
    exit false unless system %q{rake test:plugins PLUGIN=redmine_allocation RAILS_ENV=test}
  end
end

namespace :test do
  desc 'Run functional tests'
  task :functionals do
    Dir.chdir(redmine) do
      exit false unless system %q{rake test:plugins:functionals PLUGIN=redmine_allocation RAILS_ENV=test}
    end
  end

  desc 'Run unit tests'
  task :units do
    Dir.chdir(redmine) do
      exit false unless system %q{rake test:plugins:units PLUGIN=redmine_allocation RAILS_ENV=test}
    end
  end

  desc 'Drop and recreate the test database'
  task :prepare do
    databaseyml = File.join(redmine, "config", "database.yml")
    unless File.exists? databaseyml
      File.open("redmine/config/database.yml", "w") do |f|
        f.write "test:\n  adapter: mysql\n  database: redmine_test\n  username: root\n  encoding: utf8\n"
      end
    end

    Dir.chdir(redmine) do
      exit false unless system %q{rake db:drop db:create db:migrate db:migrate_plugins RAILS_ENV=test}
      exit false unless system %q{rake db:fixtures:load RAILS_ENV=test}
    end
  end
end

desc 'Add a tag in git'
task :tag, :version do |t, args|
  tagname = args.version
  raise 'Please, specify a tagname' unless tagname
  puts "Adding tag #{tagname}..."
  system "git tag #{tagname}"
end

desc "Update plugin version info in init.rb"
task :update_version, :version do |t, args|
  version = args.version
  raise 'Please, specify a version number' unless version
  puts "Changing plugin version to #{version}..."
  text = File.open(File.join(File.dirname(__FILE__), 'init.rb'), 'r') { |file| file.read }
  File.open(File.join(File.dirname(__FILE__), 'init.rb'), 'w') { |file|
    file.write(text)
  } if text.gsub!(/\bversion\b.*$/, "version '#{version}'")
end

desc 'Release a new version'
task :release, [:version] => :update_version do |t, args|
  version = args.version
  puts 'Committing...'
  system "git commit -m 'release: #{args.version}' init.rb"
  Rake::Task[:tag].invoke args.version
  puts 'Archiving...'
  filename = File.join(File.dirname(__FILE__), "redmine_allocation-#{version}.tar.gz")
  system "git archive --prefix=redmine_allocation/ --format=tar HEAD | gzip > #{filename}"
end
