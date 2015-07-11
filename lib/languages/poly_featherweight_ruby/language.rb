require_relative './parser'

module TypedRb
  module Languages
    module PolyFeatherweightRuby
      class Language
        include Model
        include Types

        attr_reader :unification_result

        def check(expr)
          ::BasicObject::TypeRegistry.clear
          $TYPECHECK = true
          eval(expr, TOPLEVEL_BINDING)
          $TYPECHECK = false
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
          parser = Parser.new
          parser.parse(expr)
        end

        def check_type(expr)
          expr.check_type(TypingContext.top_level)
        end

        def run_unification
          constraints = Types::TypingContext.all_constraints
          # puts "CONSTRAINTS"
          # constraints.each do |(l,t,r)|
          #   puts "#{l} -> #{t} -> #{r}"
          # end
          Types::Polymorphism::Unification.new(constraints).run(true)
        end

        def type_variables
          TypingContext.all_variables
        end
      end
    end
  end
end
