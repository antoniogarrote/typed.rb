# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Languages
    module FeatherweightRuby
      module Model
# abstraction
        class TmAbs < Expr
          attr_accessor :head, :term
          def initialize(head, term, type,node)
            super(node, type)
            if type.nil?
              fail StandardError, 'Missing type annotation for abstraction'
            end
            @head = head
            @term = term
          end

          def to_s
            "λ#{GenSym.resolve(@head)}:#{type}.#{@term}"
          end

          def rename(from_binding, to_binding)
            if(@head != from_binding)
              term.rename(from_binding,to_binding)
            end
            self
          end

          def check_type(context)
            context = context.add_binding(head,type.from)
            type_term = term.check_type(context)
            if type.to.nil? || type_term.compatible?(type.to)
              type.to = type_term
              type
            else
              error_message = "Error abstraction type, exepcted #{type} got #{type.from} -> #{type_term}"
              fail TypeError.new(error_message, self)
            end
          end
        end
      end
    end
  end
end