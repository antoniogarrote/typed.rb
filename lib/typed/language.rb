require_relative './runtime/ast_parser'

module TypedRb
  class Language
    include Model
    include Types

    attr_reader :unification_result

    def check(expr)
      restore_prelude
      $TYPECHECK = true
      eval(expr, TOPLEVEL_BINDING)
      $TYPECHECK = false
      TypedRb.log(binding, :debug, 'Normalize top level')
      ::BasicObject::TypeRegistry.normalize_types!
      TypingContext.clear(:top_level)
      check_result = check_type(parse(expr))
      ::BasicObject::TypeRegistry.check_super_type_annotations
      @unification_result = run_unification
      check_result
    end

    def gen_bin_prelude
      File.open(File.join(File.dirname(__FILE__), 'prelude_registry.bin'), 'w') do |f|
        f.write(Marshal.dump(::BasicObject::TypeRegistry.send(:registry)))
      end
      File.open(File.join(File.dirname(__FILE__), 'prelude_generic_registry.bin'), 'w') do |f|
        f.write(Marshal.dump(::BasicObject::TypeRegistry.send(:generic_types_registry)))
      end
      File.open(File.join(File.dirname(__FILE__), 'prelude_existential_registry.bin'), 'w') do |f|
        f.write(Marshal.dump(::BasicObject::TypeRegistry.send(:existential_types_registry)))
      end
    end

    def load_bin_prelude
      old_value = $TYPECHECK
      $TYPECHECK = false
      require_relative('./prelude')
      $TYPECHECK = old_value
      ::BasicObject::TypeRegistry.clear
      File.open(File.join(File.dirname(__FILE__), 'prelude_registry.bin'), 'r') do |f|
        ::BasicObject::TypeRegistry.registry =  Marshal.load(f.read)
      end
      File.open(File.join(File.dirname(__FILE__), 'prelude_generic_registry.bin'), 'r') do |f|
        ::BasicObject::TypeRegistry.generic_types_registry = Marshal.load(f.read)
      end
      File.open(File.join(File.dirname(__FILE__), 'prelude_existential_registry.bin'), 'r') do |f|
        ::BasicObject::TypeRegistry.existential_types_registry = Marshal.load(f.read)
      end
      ::BasicObject::TypeRegistry.clear_parsing_registries
      true
    rescue
      false
    end

    def restore_prelude
      unless load_bin_prelude
        ::BasicObject::TypeRegistry.clear
        $TYPECHECK = true
        load File.join(File.dirname(__FILE__), 'prelude.rb')
        $TYPECHECK = false
        ::BasicObject::TypeRegistry.normalize_types!
        gen_bin_prelude
        TypingContext.clear(:top_level)
        ::BasicObject::TypeRegistry.clear_parsing_registries
      end
    end

    def check_files(files)
      ::BasicObject::TypeRegistry.clear
      $TYPECHECK = true
      prelude_path = File.join(File.dirname(__FILE__), 'prelude.rb')
      load prelude_path
      Kernel.reset_dependencies
      Kernel.with_dependency_tracking do
        files.each { |file| load file if file != prelude_path }
      end
      ordered_files = Kernel.computed_dependencies.select do |file|
        files.include?(file)
      end
      ordered_files += files.select { |file| !ordered_files.include?(file) }
      $TYPECHECK = false
      TypedRb.log(binding, :debug, 'Normalize top level')
      ::BasicObject::TypeRegistry.normalize_types!
      TypingContext.clear(:top_level)
      check_result = nil
      ordered_files.each do |file|
        puts "*** FILE #{file}"
        $TYPECHECK_FILE = file
        expr = File.open(file, 'r').read
        #begin
          check_result = check_type(parse(expr))
        #rescue TypedRb::Types::UncomparableTypes => e
        #  puts e.backtrace.join("\n")
        #  puts e.message
        #  exit(-1)
        #rescue TypedRb::TypeCheckError => e
        # puts e.message
        #end
      end
      ::BasicObject::TypeRegistry.check_super_type_annotations
      @unification_result = run_unification
      check_result
    end

    def check_file(path)
      check_files([path])
    end

    def parse(expr)
      Model::GenSym.reset
      parser = AstParser.new
      parser.parse(expr)
    end

    def check_type(expr)
      expr.check_type(TypingContext.top_level)
    end

    def run_unification
      constraints = Types::TypingContext.all_constraints
      unif = Types::Polymorphism::Unification.new(constraints)
      unif.run(true)
    end

    def type_variables
      TypingContext.all_variables
    end
  end
end
