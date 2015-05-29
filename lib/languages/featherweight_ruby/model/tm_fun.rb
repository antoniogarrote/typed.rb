# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Languages
    module FeatherweightRuby
      module Model
        class TmFun < Expr
          attr_accessor :name, :args, :body, :owner
          def initialize(owner, name, args, body, node)
            super(node)
            @owner = parse_owner(owner)
            @name = name
            rename = {}
            @args = args.map do |arg|
              old_id = arg[1].to_s
              uniq_arg = Model::GenSym.next(old_id)
              rename[old_id] = uniq_arg
              arg[1] = uniq_arg
              arg
            end
            @body = rename.inject(body) do |body_acc, (old_id, new_id)|
              body_acc.rename(old_id, new_id)
            end
          end

          def to_s
            args_str = args.map do |arg|
              case arg.first
              when :arg
                GenSym.resolve(arg.last)
              when :optarg
                "#{GenSym.resolve(arg[1])}:#{arg[2]}"
              when :blockarg
                "&#{GenSym.resolve(arg.last)}"
              end
            end
            "#{name}(#{args_str.join(',')}){ \n\t#{body}\n }"
          end

          def rename(from_binding, to_binding)
            @terms.each{|term| term.rename(from_binding, to_binding) }
            self
          end

          def check_type(context)
            @terms.drop(1).reduce(@terms.first.check_type(context)) do |_,term|
              term.check_type(context)
            end
          end

          private

          def parse_owner(owner)
            if owner.nil?
              nil
            elsif owner.type == :self
              :self
            else
              fail RuntimeError.new("Unsupported receiver for function definition #{owner}")
            end
          end
        end
      end
    end
  end
end