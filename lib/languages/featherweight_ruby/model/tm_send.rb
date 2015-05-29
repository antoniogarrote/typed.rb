# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Languages
    module FeatherweightRuby
      module Model
        # message send
        class TmSend < Expr
          attr_accessor :receiver, :message, :args
          def initialize(receiver, message, args, node)
            super(node)
            @receiver = receiver
            @message = message
            @args = args
          end

          def to_s
            if args.size == 0
              "[#{receiver} <- #{message}"
            else
              "[#{receiver} <- #{message}(#{args.map(&to_s).join(',')})"
            end
          end

          def rename(from_binding, to_binding)
            fail StandardError, "Not implemented yet"
            if(@head != from_binding)
              term.rename(from_binding,to_binding)
            end
            self
          end

          def check_type(context)
            fail StandardError, "Not implemented yet"
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
