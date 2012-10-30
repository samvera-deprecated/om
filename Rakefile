require 'bundler'
Bundler::GemHelper.install_tasks

# adding tasks defined in lib/tasks
Dir.glob('lib/tasks/*.rake').each { |r| import r }

task :spec => ['om:rspec']
task :rcov => ['om:rcov']

# task :spec => :check_dependencies

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = Om::VERSION 

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "om #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
