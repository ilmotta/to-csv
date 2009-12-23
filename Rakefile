#encoding: utf-8
require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
load 'test/tasks.rake'

TO_CSV_VERSION = '1.0.0'
CLEAN.include('pkg')

spec = Gem::Specification.new do |s|
  s.author = "Ícaro Leopoldino da Motta"
  s.email = "icaro.ldm@gmail.com"
  s.platform = Gem::Platform::RUBY
  s.name = "to-csv"
  s.summary = s.description = "Convert arrays to CSV (array of hashes, matrixes, ActiveRecord objects etc)."
  s.version = TO_CSV_VERSION

  s.add_dependency 'fastercsv'

  s.has_rdoc = true
  s.require_path = "lib"
  s.extra_rdoc_files = FileList['*.rdoc']
  s.files = FileList['init.rb', 'MIT-LICENSE', 'Rakefile', 'lib/**/*', 'test/**/*']
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.define
end

task :build => [:clean, :repackage]

task :default => :test

