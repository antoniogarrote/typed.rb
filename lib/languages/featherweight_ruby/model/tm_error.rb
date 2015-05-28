# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Languages
    module FeatherweightRuby
      module Model
        class TmError < Expr
          def initialize(node)
            super(node)
          end

          def to_s
            'error'
          end

          def check_type(_context)
            Types::TyError.new
          end
        end
      end
    end
  end
end