# frozen_string_literal: true
module RakefileDefinitions
  include FileUtils

  def rakefile_access
    rakefile <<~ACCESS
      TOP_LEVEL_CONSTANT = 0

      def a_top_level_function
      end

      task :default => [:work, :obj, :const]

      task :work do
        begin
          a_top_level_function
          puts "GOOD:M Top level methods can be called in tasks"
        rescue NameError => ex
          puts "BAD:M  Top level methods can not be called in tasks"
        end
      end

      task :obj do
        begin
          Object.new.instance_eval { task :xyzzy }
          puts "BAD:D  Rake DSL are polluting objects"
        rescue StandardError => ex
          puts "GOOD:D Rake DSL are not polluting objects"
        end
      end

      task :const do
        begin
          TOP_LEVEL_CONSTANT
          puts "GOOD:C Top level constants are available in tasks"
        rescue StandardError => ex
          puts "BAD:C  Top level constants are NOT available in tasks"
        end
      end
    ACCESS
  end

  def rakefile_test_task
    rakefile <<~RAKEFILE
      require "rake/testtask"

      Rake::TestTask.new(:unit) do |t|
        t.description = "custom test task description"
      end
    RAKEFILE
  end

  def rakefile_test_task_verbose
    rakefile <<~RAKEFILE
      require "rake/testtask"

      Rake::TestTask.new(:unit) do |t|
        t.verbose = true
      end
    RAKEFILE
  end

  def rakefile_chains
    rakefile <<~DEFAULT
      task :default => "play.app"

      file "play.scpt" => "base" do |t|
        cp t.prerequisites.first, t.name
      end

      rule ".app" => ".scpt" do |t|
        cp t.source, t.name
      end

      file 'base' do
        touch 'base'
      end
    DEFAULT
  end

  def rakefile_file_chains
    rakefile <<~RAKEFILE
      file "fileA" do |t|
        sh "echo contentA >\#{t.name}"
      end

      file "fileB" => "fileA" do |t|
        sh "(cat fileA; echo transformationB) >\#{t.name}"
      end

      file "fileC" => "fileB" do |t|
        sh "(cat fileB; echo transformationC) >\#{t.name}"
      end

      task default: "fileC"
    RAKEFILE
  end

  def rakefile_comments
    rakefile <<~COMMENTS
      # comment for t1
      task :t1 do
      end

      # no comment or task because there's a blank line

      task :t2 do
      end

      desc "override comment for t3"
      # this is not the description
      multitask :t3 do
      end

      # this is not the description
      desc "override comment for t4"
      file :t4 do
      end
    COMMENTS
  end

  def rakefile_override
    rakefile <<~OVERRIDE
      task :t1 do
        puts :foo
      end

      task :t1 do
        puts :bar
      end
    OVERRIDE
  end

  def rakefile_default
    rakefile <<~DEFAULT
      if ENV['TESTTOPSCOPE']
        puts "TOPSCOPE"
      end

      task :default do
        puts "DEFAULT"
      end

      task :other => [:default] do
        puts "OTHER"
      end

      task :task_scope do
        if ENV['TESTTASKSCOPE']
          puts "TASKSCOPE"
        end
      end
    DEFAULT
  end

  def rakefile_dryrun
    rakefile <<~DRYRUN
      task :default => ["temp_main"]

      file "temp_main" => [:all_apps]  do touch "temp_main" end

      task :all_apps => [:one, :two]
      task :one => ["temp_one"]
      task :two => ["temp_two"]

      file "temp_one" do |t|
        touch "temp_one"
      end
      file "temp_two" do |t|
        touch "temp_two"
      end

      task :clean do
        ["temp_one", "temp_two", "temp_main"].each do |file|
          rm_f file
        end
      end
    DRYRUN

    FileUtils.touch "temp_main"
    FileUtils.touch "temp_two"
  end

  def rakefile_extra
    rakefile "task :default"

    FileUtils.mkdir_p "rakelib"

    File.write File.join("rakelib", "extra.rake"), <<~EXTRA_RAKE
      # Added for testing

      namespace :extra do
        desc "An Extra Task"
        task :extra do
          puts "Read all about it"
        end
      end
    EXTRA_RAKE
  end

  def rakefile_file_creation
    rakefile <<~'FILE_CREATION'
      N = 2

      task :default => :run

      BUILD_DIR = 'build'
      task :clean do
        rm_rf 'build'
        rm_rf 'src'
      end

      task :run

      TARGET_DIR = 'build/copies'

      FileList['src/*'].each do |src|
        directory TARGET_DIR
        target = File.join TARGET_DIR, File.basename(src)
        file target => [src, TARGET_DIR] do
          cp src, target
        end
        task :run => target
      end

      task :prep => :clean do
        mkdir_p 'src'
        N.times do |n|
          touch "src/foo#{n}"
        end
      end
    FILE_CREATION
  end

  def rakefile_imports
    rakefile <<~IMPORTS
      require 'rake/loaders/makefile'

      task :default

      task :other do
        puts "OTHER"
      end

      file "dynamic_deps" do |t|
        File.write t.name, "puts 'DYNAMIC'\n"
      end

      import "dynamic_deps"
      import "static_deps"
      import "static_deps"
      import "deps.mf"
      puts "FIRST"
    IMPORTS

    File.write "deps.mf", <<~DEPS
      default: other
    DEPS

    File.write "static_deps", "puts 'STATIC'\n"
  end

  def rakefile_regenerate_imports
    rakefile <<~REGENERATE_IMPORTS
      task :default

      task :regenerate do
        File.write "deps", <<~CONTENT
          file "deps" => :regenerate
          puts "REGENERATED"
        CONTENT
      end

      import "deps"
    REGENERATE_IMPORTS

    File.write "deps", <<~CONTENT
      file "deps" => :regenerate
      puts "INITIAL"
    CONTENT
  end

  def rakefile_multidesc
    rakefile <<~MULTIDESC
      task :b

      desc "A"
      task :a

      desc "B"
      task :b

      desc "A2"
      task :a

      task :c

      desc "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
      task :d
    MULTIDESC
  end

  def rakefile_namespace
    rakefile <<~NAMESPACE
      desc "copy"
      task :copy do
        puts "COPY"
      end

      namespace "nest" do
        desc "nest copy"
        task :copy do
          puts "NEST COPY"
        end
        task :xx => :copy
      end

      anon_ns = namespace do
        desc "anonymous copy task"
        task :copy do
          puts "ANON COPY"
        end
      end

      desc "Top level task to run the anonymous version of copy"
      task :anon => anon_ns[:copy]

      namespace "very" do
        namespace "nested" do
          task "run" => "rake:copy"
        end
      end

      namespace "a" do
        desc "Run task in the 'a' namespace"
        task "run" do
          puts "IN A"
        end
      end

      namespace "b" do
        desc "Run task in the 'b' namespace"
        task "run" => "a:run" do
          puts "IN B"
        end
      end

      namespace "file1" do
        file "xyz.rb" do
          puts "XYZ1"
        end
      end

      namespace "file2" do
        file "xyz.rb" do
          puts "XYZ2"
        end
      end

      namespace "scopedep" do
        task :prepare do
          touch "scopedep.rb"
          puts "PREPARE"
        end
        file "scopedep.rb" => [:prepare] do
          puts "SCOPEDEP"
        end
      end
    NAMESPACE
  end

  def rakefile_nosearch
    FileUtils.touch "dummy"
  end

  def rakefile_rakelib
    FileUtils.mkdir_p "rakelib"

    Dir.chdir "rakelib" do
      File.write "test1.rb", <<~TEST1
        task :default do
          puts "TEST1"
        end
      TEST1

      File.write "test2.rake", <<~TEST2
        task :default do
          puts "TEST2"
        end
      TEST2
    end
  end

  def rakefile_rbext
    File.write "rakefile.rb", 'task :default do puts "OK" end'
  end

  def rakefile_unittest
    rakefile "# Empty Rakefile for Unit Test"

    readme = File.join "subdir", "README"
    FileUtils.mkdir_p File.dirname readme

    FileUtils.touch readme
  end

  def rakefile_verbose
    rakefile <<~VERBOSE
      task :standalone_verbose_true do
        verbose true
        sh "#{RUBY} -e '0'"
      end

      task :standalone_verbose_false do
        verbose false
        sh "#{RUBY} -e '0'"
      end

      task :inline_verbose_default do
        sh "#{RUBY} -e '0'"
      end

      task :inline_verbose_false do
        sh "#{RUBY} -e '0'", :verbose => false
      end

      task :inline_verbose_true do
        sh "#{RUBY} -e '0'", :verbose => true
      end

      task :block_verbose_true do
        verbose(true) do
          sh "#{RUBY} -e '0'"
        end
      end

      task :block_verbose_false do
        verbose(false) do
          sh "#{RUBY} -e '0'"
        end
      end
    VERBOSE
  end

  def rakefile_test_signal
    rakefile <<~TEST_SIGNAL
      require 'rake/testtask'

      Rake::TestTask.new(:a) do |t|
        t.test_files = ['a_test.rb']
      end

      Rake::TestTask.new(:b) do |t|
        t.test_files = ['b_test.rb']
      end

      task :test do
        Rake::Task[:a].invoke
        Rake::Task[:b].invoke
      end

      task :default => :test
    TEST_SIGNAL
    File.write "a_test.rb", <<~A_TEST
      puts "ATEST"
      $stdout.flush
      Process.kill("TERM", $$)
    A_TEST
    File.write "b_test.rb", <<~B_TEST
      puts "BTEST"
      $stdout.flush
    B_TEST
  end

  def rakefile_failing_test_task
    rakefile <<~TEST_TASK
      require 'rake/testtask'

      task :default => :test
      Rake::TestTask.new(:test) do |t|
        t.test_files = ['a_test.rb']
      end
    TEST_TASK
    File.write "a_test.rb", <<~A_TEST
      require 'minitest/autorun'
      class ExitTaskTest < Minitest::Test
        def test_exit
          assert false, 'this should fail'
        end
      end
    A_TEST
  end

  def rakefile_stand_alone_filelist
    File.write "stand_alone_filelist.rb", <<~STAND_ALONE
      require 'rake/file_list'
      FL = Rake::FileList['*.rb']
      puts FL
    STAND_ALONE
  end
end
