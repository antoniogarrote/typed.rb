require_relative './runtime/ast_parser'

module TypedRb
  class Language
    include Model
    include Types

    attr_reader :unification_result

    def check(expr)
      ::BasicObject::TypeRegistry.clear
      $TYPECHECK = true
      load File.join(File.dirname(__FILE__), 'prelude.rb')
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

    def check_files(files)
      ::BasicObject::TypeRegistry.clear
      $TYPECHECK = true
      prelude_path = File.join(File.dirname(__FILE__), 'prelude.rb')
      load prelude_path
      files.each { |file| load file if file != prelude_path }
      $TYPECHECK = false
      TypedRb.log(binding, :debug, 'Normalize top level')
      ::BasicObject::TypeRegistry.normalize_types!
      TypingContext.clear(:top_level)
      check_result = nil
      files.each do |file|
        puts "*** FILE #{file}"
        expr = File.open(file, 'r').read
        begin
          check_result = check_type(parse(expr))
        rescue TypedRb::TypeCheckError => e
          puts e.message
        end
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
