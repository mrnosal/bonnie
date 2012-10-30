require File.expand_path('../../../config/environment',  __FILE__)
require 'pathname'
require 'fileutils'
require './lib/measures/database_access'
require './lib/measures/exporter'

namespace :measures do
  desc 'Load a directory of measures and value sets into the DB'
  task :load, [:measures_dir, :username, :delete_existing] do |t, args|
    raise "The path the the measure definitions must be specified" unless args.measures_dir
    raise "The username to load the measures for must be specified" unless args.username

    user = User.by_username args.username
    raise "The user #{args.username} could not be found." unless user

    # Delete all of this user's measures out of the DB and remove any lingering files saved from the last load
    if args.delete_existing
      user.measures.each {|measure| measure.value_sets.destroy_all}
      count = user.measures.destroy_all
      
      source_dir = File.join(".", "db", "measures")
      FileUtils.rm_r Dir.glob(source_dir)
      
      puts "Deleted #{count} measures assigned to #{user.username}"
    end
    
    # Load each measure from the measures directory
    Dir.foreach(args.measures_dir) do |entry|
      next if entry.starts_with? '.'

      measure_dir = File.join(args.measures_dir,entry)
      hqmf_path = Dir.glob(File.join(measure_dir,'*.xml')).first
      codes_path = Dir.glob(File.join(measure_dir,'*.xls')).first
      html_path = Dir.glob(File.join(measure_dir,'*.html')).first
      begin
        measure = Measures::Loader.load(hqmf_path, codes_path, user, nil, true, html_path)
        puts "Measure #{measure.measure_id} (#{measure.title}) successfully loaded.\n"
      rescue Exception => e
        puts "Loading Measure #{entry} failed: #{e.message}: [#{hqmf_path},#{codes_path}] \n"
      end
    end

    Measures::Calculator.refresh_js_libraries
  end

  desc 'Drop all measure defintions from the DB'
  task :drop, [:username] do |t, args|
    measures = args.username ? User.by_username(args.username).measures : Measure.all
    count = measures.destroy_all
    puts "Deleted #{count} measures assigned to #{user.username}"
  end

  desc 'Export definitions for all measures'
  task :export, [:username, :delete_existing] do |t, args|
    delete_existing = args.delete_existing != 'false'
    measures = args.username ? User.by_username(args.username).measures.to_a : Measure.all.to_a

    zip = Measures::Exporter.export_bundle(measures, delete_existing)
    version = APP_CONFIG["measures"]["version"]
    bundle_path = File.join(".", "tmp", "bundles")
    date_string = Time.now.strftime("%Y-%m-%d")
    
    FileUtils.mkdir_p bundle_path
    FileUtils.mv(zip.path, File.join(bundle_path, "bundle-#{date_string}-#{version}.zip"))
    puts "Exported #{measures.size} measures to #{File.join(bundle_path, "bundle-#{date_string}-#{version}.zip")}"
  end
end