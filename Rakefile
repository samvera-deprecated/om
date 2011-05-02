require 'rubygems'
require 'rake'

# adding tasks defined in lib/tasks
Dir.glob('lib/tasks/*.rake').each { |r| import r }

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "om"
    gem.summary = %Q{OM (Opinionated Metadata): A library to help you tame sprawling XML schemas like MODS.}
    gem.description = %Q{OM (Opinionated Metadata): A library to help you tame sprawling XML schemas like MODS.  Wraps Nokogiri documents in objects with miscellaneous helper methods for doing things like retrieve generated xpath queries or look up properties based on a simplified DSL}
    gem.email = "matt.zumwalt@yourmediashelf.com"
    gem.homepage = "http://github.com/mediashelf/om"
    gem.authors = ["Matt Zumwalt"]
    
    gem.add_dependency('nokogiri', ">= 1.4.2")
    
    gem.add_development_dependency "rspec", "<2.0.0"
    gem.add_development_dependency "mocha", ">= 0.9.8"
    gem.add_development_dependency "ruby-debug"
    gem.add_development_dependency "jeweler"
    gem.add_development_dependency "equivalent-xml", ">= 0.2.4"
    
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

# task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "om #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
