# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Languages
    module PolyFeatherweightRuby
      module Model
        # abstraction
        class TmAbs < Expr
          attr_accessor :args, :term, :arity
          def initialize(args, term, type, node)
            super(node, type)
            @args  = args
            @term  = term
            @arity = args.select { |(arg_type, _, _)|  arg_type == :arg }.count
            @instantiation_count = 0
          end

          def to_s
            if type
              "λ#{GenSym.resolve(@args)}:#{type}.#{@term}"
            else
              "λ#{GenSym.resolve(@args)}.#{@term}"
            end
          end

          def rename(from_binding, to_binding)
            unless args.any? { |(_type, arg_value)| arg_value.to_s == from_binding.to_s }
              term.rename(from_binding, to_binding)
            end
            self
          end

          def check_type(context)
            with_fresh_bindings(context) do |fresh_args, fresh_term|
              fresh_args.each do |(_arg, var, opt)|
                if opt
                  opt_type = opt.check_type(context)
                  var.compatible?(opt_type, :gt)
                end
                context = context.add_binding(var.variable, var)
              end

              args_types = fresh_args.map { |(_, var, _)| var }
              type_term = fresh_term.check_type(context)

              Types::TyFunction.new(args_types, type_term, resolve_ruby_method_parameters)
            end
          end

          # abstractions are polymorphic universal types by default,
          # we need new bindings in the type variables with each instantiation of the lambda.
          def with_fresh_bindings(context)
            body = Marshal.load(Marshal.dump(term))
            @instantiation_count += 1
            fresh_args = args.map do |(type, var, opt)|
              uniq_arg = Types::TypingContext.type_variable_for_abstraction(:lambda, "#{var}_#{@instantiation_count}", context)
              body = body.rename(var.to_s, uniq_arg.variable)
              [type, uniq_arg, opt].compact
            end
            yield fresh_args, body
          end

          protected

          def resolve_ruby_method_parameters
            args.map do |(arg_type, val, _)|
              if arg_type == :optarg
                [:opt, val]
              elsif arg_type == :blockarg
                [:block, val]
              else
                [:req, val]
              end
            end
          end
        end
      end
    end
  end
end
