node[:deploy].each do |application, deploy|

  if deploy[:application_type] != 'rails'
    Chef::Log.info("Skipping as it is not a rails app")
    next
  end
   
  rails_env = deploy[:rails_env]
  current_path = deploy[:current_path]
  current_assets_path = "#{current_path}/public/assets"
  shared_assets_path = "#{deploy[:deploy_to]}/shared/assets"
  
  source_assets = "#{current_path}/app/assets"
  precompile_hash = "#{deploy[:deploy_to]}/shared/config/precompile.md5"
  
  #Ignore precompile if the source assets did not change
  next if !PrecompileHelper.directory_changed?({
    directory_path: source_assets,
    md5_file: precompile_hash,
    user: deploy[:user]
  })
  
  
  
  #Cleanup first
  Chef::Log.info("Deleting shared assets path: #{shared_assets_path}")
  directory "#{shared_assets_path}" do
    action :delete
    recursive true
    only_if {Dir.exists?(shared_assets_path)}
  end
  
  
  Chef::Log.info("Removing current assets path, if it exists : #{current_assets_path}")
  directory "#{current_assets_path}" do
    action :delete
    only_if {Dir.exists?(current_assets_path)}
  end
  
  file "#{current_assets_path}" do
    action :delete
    only_if {File.exists?(current_assets_path)}
  end
  
  link "#{current_assets_path}" do
    action :delete
    only_if {File.exists?(current_assets_path)}
  end  
  

  Chef::Log.info("Precompiling Rails assets with environment #{rails_env}")

  # public/assets folder should not exist for the rake task to execute properly
  execute 'rake assets:precompile' do
    cwd current_path
    user deploy[:user]
    group deploy[:group]    
    command 'bundle exec rake assets:precompile'
    environment 'RAILS_ENV' => rails_env
  end
  
  Chef::Log.info("Moving precompiled assets to #{shared_assets_path}")
  execute "move_precompiled_assets" do
    cwd current_path
    user deploy[:user]
    group deploy[:group] 
    command "mv #{current_assets_path} #{shared_assets_path}"
  end

  Chef::Log.info("Creating link from #{current_assets_path} to #{shared_assets_path}")
  link "#{current_assets_path}" do
    owner deploy[:user]
    group deploy[:group]
    to "#{shared_assets_path}"
  end  
  
  
end
