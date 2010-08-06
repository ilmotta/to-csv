#encoding: utf-8

require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
load 'test/tasks.rake'

TO_CSV_VERSION = '1.0.3'
CLEAN.include('pkg')

spec = Gem::Specification.new do |s|
  s.author = "Ícaro Leopoldino da Motta"
  s.email = "icaro.ldm@gmail.com"
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 1.8.7'
  s.name = "to-csv"
  s.summary = s.description = "Convert arrays to CSV (array of hashes, matrixes, ActiveRecord objects etc)."
  s.homepage = "http://github.com/ilmotta/to-csv"
  s.version = TO_CSV_VERSION

  s.add_dependency 'activesupport', '>= 2.3.5'
  s.add_development_dependency 'activerecord', '>= 2.3.5'
  s.add_development_dependency 'sqlite3-ruby', '>= 1.2.5'

  s.has_rdoc = true
  s.require_path = "lib"
  s.extra_rdoc_files = FileList['*.rdoc']
  s.files = FileList['init.rb', 'MIT-LICENSE', 'Rakefile', 'lib/**/*', 'test/**/*']

  s.post_install_message = %q{
========================================================================

  Thanks for installing ToCSV.

  If your Ruby version is lower than 1.9 you need to install fastercsv.

    $ sudo gem install fastercsv

========================================================================

}
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.define
end

task :build => [:clean, :repackage]

task :default => :test

