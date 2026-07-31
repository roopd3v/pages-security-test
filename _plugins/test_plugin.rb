Jekyll::Hooks.register :site, :post_read do |site|
  File.write(File.join(site.dest, 'plugin_exec_proof.txt'), "PLUGIN_EXECUTED:#{`hostname`.strip}:#{Time.now}")
end
