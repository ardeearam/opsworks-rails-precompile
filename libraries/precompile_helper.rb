module PrecompileHelper
  def self.directory_changed?(params)
    directory_path = params[:directory_path]
    md5_file = params[:md5_file]
    user = params[:user]
    
    begin
      old_md5sum = ::File.read(md5_file)
    rescue Errno::ENOENT
      #If the md5 file does not exist yet, assume precompile has not yet taken place, and
      #we force precompilation
      Chef::Log.info("File #{md5_file} does not exist. Precompiling...")
      does_md5sum_exist = false
    end
    

    #Actual md5 starts here.
    shell = %Q(find #{directory_path} -type f -exec md5sum {} + | awk '{print $1}' | sort | md5sum)
    cmd = Mixlib::ShellOut.new(shell, :user => user)
    cmd.run_command
    new_md5sum = cmd.stdout
    
    directory_changed = (old_md5sum != new_md5sum)
    
    if (!does_md5sum_exist || directory_changed)
      ::File.open(md5_file, "w") do |f|
        f.write new_md5sum.chomp
      end
    end

    
    !does_md5sum_exist || directory_changed 
        
  end
end