require_relative './parser'

module TypedRb
  module Languages
    module PolyFeatherweightRuby
      class Language
        include Model
        include Types

        def check(expr)
          ::BasicObject::TypeRegistry.registry.clear
          eval(expr)
          ::BasicObject::TypeRegistry.normalize_types!
          TypingContext.type_variables_register.clear
          check_type(parse(expr))
        end

        def parse(expr)
          Model::GenSym.reset
          parser = Parser.new
          parser.parse(expr)
        end

        def check_type(expr)
          expr.check_type(TypingContext.toplevel_binding)
        end
      end
    end
  end
end
