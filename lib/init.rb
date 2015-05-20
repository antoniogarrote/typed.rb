Dir[File.join(File.dirname(__FILE__), 'languages/**/*.rb')].each do |file|
  load(file)
end

class Object
  def typesig(signature)
    # noop
  end
end