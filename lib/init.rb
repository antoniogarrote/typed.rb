Dir[File.join(File.dirname(__FILE__), '**/*.rb')].each do |file|
  load(file) if file != __FILE__
end
