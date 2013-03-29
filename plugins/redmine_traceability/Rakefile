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
  filename = File.join(File.dirname(__FILE__), "redmine_traceability-#{version}.tar.gz")
  system "git archive --prefix=redmine_traceability/ --format=tar HEAD | gzip > #{filename}"
end
