node[:deploy].each do |application, deploy|
  rails_env = deploy[:rails_env]
  current_path = deploy[:current_path]
  current_assets_path = "#{current_path}/public/assets"
  shared_assets_path = "#{deploy[:deploy_to]}/shared/assets"
  
  Chef::Log.info("Deleting shared assets path: #{shared_assets_path}")
  directory "#{shared_assets_path}" do
    action :delete
    recursive true
    only_if "test -D #{shared_assets_path}"
  end
  
  Chef::Log.info("Create empty shared assets path: #{shared_assets_path}")
  directory "#{shared_assets_path}" do
    action :create
    owner 'deploy'
    only_if "test ! -D #{shared_assets_path}"
  end
  
   Chef::Log.info("Removing current assets path, if it exists : #{current_assets_path}")
  directory "#{current_assets_path}" do
    action :delete
    only_if "test -D #{current_assets_path}"
  end
  
  Chef::Log.info("Creating link from #{current_assets_path} to #{shared_assets_path}")
  link "#{current_assets_path}" do
    to "#{shared_assets_path}"
  end

  Chef::Log.info("Precompiling Rails assets with environment #{rails_env}")

  execute 'rake assets:precompile' do
    cwd current_path
    user 'deploy'
    command 'bundle exec rake assets:precompile'
    environment 'RAILS_ENV' => rails_env
  end
end
