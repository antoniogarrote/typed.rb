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
            # This is safe, within the function, args names are bound
            # to this reference
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
                "#{GenSym.resolve(arg[1])}:#{arg[2].type}"
              when :blockarg
                "&#{GenSym.resolve(arg.last)}"
              end
            end
            "#{name}(#{args_str.join(',')}){ \n\t#{body}\n }"
          end

          def rename(from_binding, to_binding)
            # rename receiver
            if !owner.nil? && owner != :self
              @owner = @owner.rename(from_binding, to_binding)
            end
            # rename default args
            args.each do |arg|
              if arg.first == :optarg
                arg[2] = arg[2].rename(from_binding, to_binding)
              end
            end
            #rename free variables -> not bound (and already renamed) in args
            @body = @body.rename(from, to_binding)
            self
          end

          def check_type(context)
            fail 'Not implemented yet'
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
