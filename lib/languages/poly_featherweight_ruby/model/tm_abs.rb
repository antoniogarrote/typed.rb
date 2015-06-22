# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Languages
    module PolyFeatherweightRuby
      module Model
        # abstraction
        class TmAbs < Expr
          attr_accessor :args, :term
          def initialize(args, term, type, node)
            super(node, type)
            @args = args
            @term = term
          end

          def to_s
            if type
              "λ#{GenSym.resolve(@args)}:#{type}.#{@term}"
            else
              "λ#{GenSym.resolve(@args)}.#{@term}"
            end
          end

          def rename(from_binding, to_binding)
            unless args.any? { |(_type, arg_value)| arg_value == from_binding }
              term.rename(from_binding,to_binding)
            end
            self
          end

          def check_type(context)
            args.each do |(_arg, var, opt)|
              if opt
                opt_type = opt.check_type(context)
                var.compatible?(opt_type, :gt)
              end
              context = context.add_binding(var.variable, var)
            end

            args_types = args.map { |(_,var, _)| var }
            type_term = term.check_type(context)

            Types::TyFunction.new(args_types, type_term)
          end
        end
      end
    end
  end
end
