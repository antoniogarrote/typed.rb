#require_relative 'init'
require_relative './ast_parser'

module TypedRb
  class Language
    include Model
    include Types

    attr_reader :unification_result

    def check(expr)
      ::BasicObject::TypeRegistry.clear
      $TYPECHECK = true
      require_relative 'prelude'
      eval(expr, TOPLEVEL_BINDING)
      $TYPECHECK = false
      TypedRb.log(self, :debug, 'Normalize top level')
      ::BasicObject::TypeRegistry.normalize_types!
      TypingContext.clear(:top_level)
      check_result = check_type(parse(expr))
      @unification_result = run_unification
      check_result
    end

    def check_file(path)
      check(File.open(path,'r').read)
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
       TypedRb.log(self, :debug, 'Constraints')
       constraints.each do |(l,t,r)|
         TypedRb.log(self, :debug,  "  #{l} -> #{t} -> #{r}")
       end
      unif = Types::Polymorphism::Unification.new(constraints)
      #unif.print_constraints
      unif.run(true)
    end

    def type_variables
      TypingContext.all_variables
    end
  end
end
