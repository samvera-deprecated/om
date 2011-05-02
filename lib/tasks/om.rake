desc "Task to execute builds on a Hudson Continuous Integration Server."
task :hudson do
  Rake::Task["om:doc"].invoke
  Rake::Task["om:rcov"].invoke
  Rake::Task["om:rspec"].invoke
end

namespace :om do    

  require 'spec/rake/spectask'
  Spec::Rake::SpecTask.new(:rspec) do |spec|
    spec.libs << 'lib' << 'spec'
    spec.spec_files = FileList['spec/**/*_spec.rb']
  end

  require 'rcov/rcovtask'
  Spec::Rake::SpecTask.new(:rcov) do |spec|
    spec.libs << 'lib' << 'spec'
    spec.pattern = 'spec/**/*_spec.rb'
    spec.rcov_opts << "--exclude \"gems/*\" --rails" 
    spec.rcov = true
  end

  # Use yard to build docs
  begin
    require 'yard'
    require 'yard/rake/yardoc_task'
    project_root = File.expand_path("#{File.dirname(__FILE__)}/../../")
    doc_destination = File.join(project_root, 'doc')

    YARD::Rake::YardocTask.new(:doc) do |yt|
      yt.files   = Dir.glob(File.join(project_root, 'lib', '**', '*.rb')) + 
                   [ File.join(project_root, 'README.textile') ]
      yt.options = ['--output-dir', doc_destination, '--readme', 'README.textile']
    end
  rescue LoadError
    desc "Generate YARD Documentation"
    task :doc do
      abort "Please install the YARD gem to generate rdoc."
    end
  end




end

