require 'stringio'

module TypedRb
  module Types
    # Polymorphic additions to Featherweight Ruby
    module Polymorphism

      class UnificationError < TypedRb::TypeCheckError
        def initialize(message)
          super(message)
        end
      end

      # Common operations on types and restrictions.
      module TypeOperations
        # Check if two types are compatible for a certain restriction.
        # If no join type is possible for a particular restriction, a
        # UncomparableTypes error is raised.
        def compatible_type?(value_l, t, value_r)
          if value_l.nil? || value_r.nil?
            value_l || value_r
          else
            case t
            when :gt # assignations, e.g v = Int, v = Num => Num
              compatible_gt_type?(value_l, value_r)
            when :lt # applications, return e.g. return (Int, Num) => Int
              compatible_lt_type?(value_l, value_r)
            when :send
              compatible_send_type?(value_l, value_r)
            else
              fail UnificationError, "Unknown type constraint #{t}"
            end
          end
        end

        def compatible_gt_type?(value_l, value_r, join_if_false = true)
          value_l > value_r ? value_l : value_r
        rescue Types::UncomparableTypes, ArgumentError
          if join_if_false
            value_l.join(value_r)
          else
            raise Types::UncomparableTypes.new(value_l, value_r)
          end
        end

        def compatible_lt_type?(value_l, value_r)
          error_message = "Error checking type, #{value_l} is not a subtype of #{value_r}"
          begin
            value_l <= value_r ? value_l : fail(UnificationError, error_message)
          rescue ArgumentError
            fail(Types::UncomparableTypes.new(value_l, value_r))
          end
        end

        # This function does not return the infered type.
        # Types are assigned as a side effect.
        def compatible_send_type?(receiver, send_args)
          return_type = send_args[:return]
          arg_types = send_args[:args]
          message = send_args[:message]
          inferred_receiver = infer_receiver(receiver)
          if inferred_receiver
            klass, function = inferred_receiver.find_function_type(message, arg_types.size, false)
            return true if function.is_a?(Types::TyDynamicFunction)
            if function && can_apply?(function, arg_types)
              if return_type && graph[return_type][:upper_type]
                compatible_gt_type?(graph[return_type][:upper_type], function.to, false)
              else
                graph[return_type][:upper_type] = function.to
              end
            else
              return true if klass != inferred_receiver.ruby_type
              fail UnificationError, "Message #{message} not found for type variable #{receiver}"
            end
          else
            unless @allow_unbound_receivers
              fail UnificationError, "Unbound variable #{receiver} type acting as receiver for #{message}"
            end
          end
        end

        def infer_receiver(receiver)
          if(receiver.is_a?(Hash))
            receiver[:upper_type] = receiver[:lower_type]if receiver[:upper_type].nil?
            if receiver[:upper_type]
              receiver[:upper_type].as_object_type
            else
              nil
            end
          else
            receiver
          end
        end

        def can_apply?(fn, arg_types)
          if fn.dynamic?
            true
          else
            arg_types.each_with_index do |arg, i|
              fn_arg = fn.from[i]
              if arg.is_a?(TypeVariable)
                if graph[arg][:lower_type]
                  type = compatible_lt_type?(graph[arg][:lower_type], fn_arg)
                  graph[arg][:lower_type] = type
                else
                  graph[arg][:lower_type] = fn_arg
                end
              else
                compatible_lt_type?(arg, fn_arg)
              end
            end
          end
        end
      end

      # Keeps a graph of the var types according to the subsumption order
      # relationship.
      class Topography
        include Polymorphism::TypeOperations
        attr_reader :mapping, :groups

        # Create the graph based on the provided constraints as unlinked
        # nodes.
        def initialize(constraints)
          vars = constraints.reduce([]) do |acc, (l, _t, r)|
            vals = [l]
            if r.is_a?(Hash)
              vals << r[:return]
            else
              vals << r
            end
            acc + vals.select{ |v| v.is_a?(TypeVariable) }
          end.uniq

          @groups = vars.each_with_object({}) do |var, groups|
            groups[var] = make_group(var => true)
          end
        end

        # Is the variable in a group of variables?
        def grouped?(var)
          groups[var][:grouped]
        end

        def [](var)
          if var.is_a?(TypeVariable)
            groups[var]
          else
            var
          end
        end

        def vars
          groups.keys
        end

        def merge(l, r)
          merge_groups(groups[l], groups[r])
        end

        def replace_groups(constraints)
          groups.values.each do |group|
            group[:vars].keys.each do |l|
              constraints = replace(constraints, l, group)
            end
          end
          constraints
        end

        def do_bindings!
          text = StringIO.new
          text << "Doing bindings:\n"

          num_bindings = 0
          groups.values.uniq.each do |group|
            next if (group [:upper_type].nil? && group[:lower_type].nil?)
            group[:vars].keys.each do |var|
              final_lower_type = find_type(group[:lower_type], :lower_type)
              var.upper_bound = final_lower_type
              final_upper_type = find_type(group[:upper_type], :upper_type)
              var.lower_bound = final_upper_type
              #if var.wildcard?
              #  final_binding_type = if final_lower_type == final_upper_type
              #                         final_upper_type
              #                       elsif final_lower_type && final_upper_type
              #                         final_lower_type
              #                     #elsif final_lower_type && final_upper_type.nil?
              #                     #  final_lower_type
              #                     #else
              #                     #  final_upper_type
              #                     end
              #  binding_string = "[#{var.lower_bound ? var.lower_bound : '?'},#{var.upper_bound ? var.upper_bound : '?'}]"
              #  if final_binding_type
              #    num_bindings += 1
              #    text << "Final binding:  #{var.variable} -> #{binding_string} : #{final_binding_type}\n"
              #    var.bind(final_binding_type)
              #  else
              #    text << "Final binding:  #{var.variable} -> #{binding_string} : UNKNOWN\n"
              #  end
              #else
                final_binding_type = if final_lower_type == final_upper_type
                                       final_upper_type
                                     elsif final_lower_type && final_upper_type.nil?
                                         final_lower_type
                                     else
                                       final_upper_type
                                     end
                binding_string = "[#{var.lower_bound ? var.lower_bound : '?'},#{var.upper_bound ? var.upper_bound : '?'}]"
                if final_binding_type
                  num_bindings += 1
                  text << "Final binding:  #{var.variable} -> #{binding_string} : #{final_binding_type}\n"
                  var.bind(final_binding_type)
                else
                  text << "Final binding:  #{var.variable} -> #{binding_string} : UNKNOWN\n"
                end
              #end
            end
          end
          text << "Found #{num_bindings} bindings"
          TypedRb.log(binding, :debug, text.string)
        end

        def check_bindings
          groups.values.each do |group|
            vars = group[:vars].keys.map(&:to_s).join(',').index('TMBSA:tmbs2')
            next if (group[:upper_type].nil? && group[:lower_type].nil?)
            group[:vars].keys.each do |var|
              final_lower_type = find_type(group[:lower_type], :lower_type)
              final_upper_type = find_type(group[:upper_type], :upper_type)
              if final_lower_type && final_upper_type && final_lower_type != final_upper_type
                # final lower <= final upper
                compatible_lt_type?(final_upper_type, final_lower_type)
              end
            end
          end
        end

        def find_type(value, type)
          # type variable
          if value.is_a?(TypeVariable)
            value = if type == :lower_type
                      value.upper_bound
                    else
                      value.lower_bound
                    end
            find_type(value, type)
          # group
          elsif value.is_a?(Hash) && value[type]
            find_type(value[type], type)
          # type
          elsif value.is_a?(Type)
            value
          # nil
          else
            value
            #fail UnificationError, 'Cannot find type in type_variable binding' if value.nil?
          end
        end

        def print_groups
          TypedRb.log(binding, :debug, "Variable groups:")
          groups.values.uniq.each do |group|
            vars = group[:vars].keys.map(&:to_s).join(',')
            lower_type = group[:lower_type] ? group[:lower_type].to_s : '?'
            upper_type = group[:upper_type] ? group[:upper_type].to_s : '?'
            TypedRb.log(binding, :debug, "#{vars}:[#{lower_type},#{upper_type}]")
          end
        end

        protected

        def make_group(vars)
          { vars: vars,
            grouped: vars.keys.size > 1,
            lower_type: nil,
            upper_type: nil }
        end

        def merge_groups(group_l, group_r)
          vars_common = group_l[:vars].merge(group_r[:vars])
          group_common = make_group(vars_common)
          group_common[:grouped] = true
          # TODO: types???
          group_common[:lower_type] = max_type(group_l[:lower_type], group_r[:lower_type])
          group_common[:upper_type] = min_type(group_l[:upper_type], group_r[:upper_type])
          vars_common.keys.each { |var|  groups[var] = group_common }
        end

        def max_type(type_a, type_b)
          if type_a.nil? || type_b.nil?
            type_a || type_b
          else
            compatible_type?(type_a, :gt, type_b)
          end
        end

        def min_type(type_a, type_b)
          if type_a.nil? || type_b.nil?
            type_a || type_b
          else
            compatible_type?(type_a, :lt, type_b)
          end
        end

        def replace(rest, l, r, acc = [])
          if rest.empty?
            acc
          else
            a, t, b = rest.first
            acc << [a == l ? r : a, t, b == l ? r : b]
            replace(rest.drop(1), l, r, acc)
          end
        end
      end

      # Implements a unification algorithm for variable types
      # with support for subtyping and restrictions on variable types.
      class Unification
        include Polymorphism::TypeOperations
        attr_reader :constraints, :graph

        def initialize(constraints, options = {})
          @allow_unbound_receivers = options[:allow_unbound_receivers] || false
          @constraints = canonical_form(constraints)
          @gt_constraints = @constraints.select { |(_, t, _r)| t == :gt }.sort do |(_, _, r1), (_, _, r2)|
            -(r1 <=> r2) || 0 rescue 0
          end
          @lt_constraints = @constraints.select { |(_, t, _r)| t == :lt }.sort do |(_, _, r1), (_, _, r2)|
            (r1 <=> r2) || 0 rescue 0
          end
          @send_constraints = @constraints.select { |(_, t, _r)| t == :send }
          @graph = Topography.new(@constraints)
        end

        def canonical_form(constraints)
          disambiguation = {}

          constraints.map do |(l, t, r)|
            if l.is_a?(TypeVariable)
              l = disambiguation[l.variable] || l
              disambiguation[l.variable] = l
            end
            if r.is_a?(TypeVariable)
              r = disambiguation[r.variable] || r
              disambiguation[r.variable] = r
            end
            if(l.is_a?(TypeVariable) && r.is_a?(TypeVariable) && t == :lt)
              [r, :gt, l]
            else
              [l, t, r]
            end
          end
        end

        def run(bind_variables = true)
          print_constraints
          unify(@gt_constraints) # we create links between vars in unify, we need to fold groups afterwards
          # this just references to vars in the same group, by the group itself
          # in the remaining @lt constraints
          @lt_constraints = graph.replace_groups(@lt_constraints)
          unify(@lt_constraints)
          unify(@send_constraints)
          graph.check_bindings
          graph.print_groups
          graph.do_bindings! if bind_variables
          self
        end

        def bindings
          graph.vars
        end

        def bindings_map
          graph.vars.each_with_object({}) do |var, acc|
            acc[var.variable] = var
          end
        end

        def print_constraints
          text = StringIO.new
          text << "Running unification on #{constraints.size} constraints:\n"
          # begin
          #   fail StandardError
          # rescue StandardError => e
          #   puts e.backtrace.join("\n")
          # end
          @gt_constraints.each do |(l, _t, r)|
            l = if l.is_a?(Hash)
                  l.keys.map(&:to_s).join(',')
                else
                  l.to_s
                end
            text <<  "#{l} :gt #{r}\n"
          end
          @lt_constraints.each do |(l, _t, r)|
            l = if l.is_a?(Hash)
                  l.keys.map(&:to_s).join(',')
                else
                  l.to_s
                end
            text <<  "#{l} :lt #{r}\n"
          end
          @send_constraints.each do |(l, _t, send)|
            return_type = send[:return]
            arg_types = send[:args].map(&:to_s)
            message = send[:message]
            l = if l.is_a?(Hash)
                  l.keys.map(&:to_s).join(',')
                else
                  l.to_s
                end
            text <<  "#{l} :send #{message}[ #{arg_types.join(',')} -> #{return_type}]\n"
          end

          TypedRb.log binding, :debug, text.string
        end

        protected

        def unify(constraints)
          return if constraints.empty?
          (l, t, r), rest = constraints.first, constraints.drop(1)
          if l == r
            unify(rest)
          else
            if r.is_a?(TypeVariable)
              # this is only going to happen in the first invocation to unify
              graph.merge(l, r)
            else
              # - In the first invocation to unify, l must always be a TypeVar
              #   t :gt and r a type variable or a type,
              # - In the second invocation to unify, l must always be a group
              #   t :lt and r a type variable,
              check_constraint(l, t, r, t != :send) # we don't bind if constraint is send
            end
            unify(rest)
          end
        end

        def check_constraint(l, t, r, bind = true)
          # ONE BOUND
          value_l = if t == :lt
                      graph[l][:lower_type]
                    elsif t == :gt
                      graph[l][:upper_type]
                    else
                      graph[l]
                    end
          #value_r = r
          value_r = if  r.is_a?(Hash) && t != :send
                      if t == :lt
                        graph[r][:lower_type]
                      elsif t == :gt
                        graph[r][:upper_type]
                      else
                        graph[r]
                      end
                    else
                      r
                    end

          # this will throw an exception if types no compatible
          compatible_type = compatible_type?(value_l, t, value_r)
          if t == :lt
            graph[l][:lower_type] = compatible_type if bind
          elsif t == :gt
            graph[l][:upper_type] = compatible_type if bind
          end

#          # OTHER BOUND
#
#          value_l = if t == :lt
#                      graph[l][:upper_type]
#                    elsif t == :gt
#                      graph[l][:lower_type]
#                    else
#                      graph[l]
#                    end
#          #value_r = r
#          value_r = if  r.is_a?(Hash)
#                      if t == :lt
#                        graph[r][:upper_type]
#                      elsif t == :gt
#                        graph[r][:lower_type]
#                      else
#                        graph[r]
#                      end
#                    else
#                      r
#                    end
#
#          # this will throw an exception if types no compatible
#          compatible_type = compatible_type?(value_l, (t == :gt ? :lt : :gt), value_r)
#          if t == :lt
#            graph[l][:upper_type] = compatible_type if bind
#          elsif t == :gt
#            graph[l][:lower_type] = compatible_type if bind
#          end
        end

        # def check_constraint(l, t, r, bind = true)
        #   value_l = if t == :lt
        #               graph[l][:lower_type]
        #             elsif t == :gt
        #               graph[l][:upper_type]
        #             else
        #               graph[l]
        #             end
        #   #value_r = r
        #   value_r = if  r.is_a?(Hash)
        #               if t == :lt
        #                 graph[r][:lower_type]
        #               elsif t == :gt
        #                 graph[r][:upper_type]
        #               else
        #                 graph[r]
        #               end
        #             else
        #               r
        #             end
        #
        #   # this will throw an exception if types no compatible
        #   compatible_type = compatible_type?(value_l, t, value_r)
        #   if t == :lt
        #     graph[l][:lower_type] = compatible_type if bind
        #   elsif t == :gt
        #     graph[l][:upper_type] = compatible_type if bind
        #   end
        # end

      end
    end
  end
end
