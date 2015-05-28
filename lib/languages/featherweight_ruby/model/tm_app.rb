# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Languages
    module FeatherweightRuby
      module Model
# application
        class TmApp < Expr
          attr_accessor :abs,:subs
          def initialize(abs, subs, node)
            super(node)
            @abs = abs
            @subs = subs
          end

          def rename(from_binding, to_binding)
            @abs.rename(from_binding, to_binding)
            @subs.rename(from_binding, to_binding)
            self
          end

          def check_type(context)
            abs_type = abs.check_type(context)
            subs_type = subs.check_type(context)
            if abs_type.compatible?(Types::TyFunction)
              if abs_type.from.compatible?(subs_type)
                abs_type.to
              else
                fail TypeError.new("Error in application expected #{abs_type.from} got #{subs_type}", self)
              end
            else
              fail TypeError.new("Error in application expected Function type got #{abs_type}", self)
            end
          end

          def to_s
            "(#{@abs} #{@subs})"
          end
        end
      end
    end
  end
end