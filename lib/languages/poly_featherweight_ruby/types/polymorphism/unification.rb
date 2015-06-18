module TypedRb
  module Languages
    module PolyFeatherweightRuby
      module Types
        # Polymorphic additions to Featherweight Ruby
        module Polymorphism
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
                  fail StandardError, "Unknown type constraint #{t}"
                end
              end
            end

            def compatible_gt_type?(value_l, value_r, join_if_false = true)
              value_l > value_r ? value_l : value_r
            rescue Types::UncomparableTypes => error
              if join_if_false
                value_l.join(value_r)
              else
                raise error
              end
            end

            def compatible_lt_type?(value_l, value_r)
              error_message = "Error checking type, #{value_l} is not a subtype of #{value_r}"
              value_l <= value_r ? value_l : fail(error_message)
            end

            def compatible_send_type?(receiver, send_args)
              return_type = send_args[:return]
              arg_types = send_args[:args]
              message = send_args[:message]

              if receiver
                function = receiver.find_function_type(message)
                if function && can_apply?(function, arg_types)
                  if return_type && graph[return_type][:type]
                    compatible_gt_type?(graph[return_type][:type], function.to, false)
                  else
                    graph[return_type][:type] = function.to
                  end
                else
                  fail StandardError, "Message #{message} not found for type variable #{message}"
                end
              else
                fail StandardError, "Unbound variable #{receiver} type acting as receiver for #{message}"
              end
            end

            def can_apply?(fn, arg_types)
              arg_types.each_with_index do |arg, i|
                fn_arg = fn.from[i]
                if arg.is_a?(TypeVariable)
                  type = compatible_lt_type?(graph[arg.bound][:type], fn_arg)
                  graph[return_type][:type] = type
                else
                  compatible_lt_type?(arg, fn_arg)
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
              groups[var][:links][:grouped]
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

            def link(l, r)
              merge_groups(groups[l], groups[r])
            end

            # Join types and groups of variables.
            # The resulting type is the join type for all the
            # variables, in the group and upper vars.
            def fold_groups
              groups.values.each do |group|
                group[:type] = join_group_types(group)
              end
              self
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
              groups.values.each do |group|
                next unless group[:type]
                group[:vars].keys.each do |var|
                  var.bind(group[:type])
                end
              end
            end

            def print_groups
              groups.values.uniq.each do |group|
                vars = group[:vars].keys.map(&:to_s).join(',')
                type = group[:type] ? group[:type].to_s : '?'
                links = group[:links].map(&:to_s).join(' < ')
                puts "#{vars}:#{type} => #{links}"
              end
            end

            protected

            def make_group(vars, links = {})
              { vars: vars,
                links: links,
                grouped: vars.keys.size > 1,
                type: nil }
            end

            def join_group_types(group)
              join_type_vars = (group[:vars].keys + group[:links].keys)
              join_type = join_type_vars.map { |var| groups[var][:type] }.uniq
              join_type.reduce do |ta, tb|
                compatible_type? ta, :gt, tb
              end
            end

            def merge_groups(group_l, group_r)
              vars_common = group_l[:vars].merge(group_r[:vars])
              links_common = group_l[:links].merge(group_r[:links])
              group_common = make_group(vars_common, links_common)
              group_common[:grouped] = true
              vars_common.each { |var|  groups[var] = group_common }
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

            def initialize(constraints)
              @constraints = constraints
              @gt_constraints = @constraints.select { |(_, t, _r)| t == :gt }
              @lt_constraints = @constraints.select { |(_, t, _r)| t == :lt }
              @send_constraints = @constraints.select { |(_, t, _r)| t == :send }
              @graph = Topography.new(@constraints)
            end

            def run(bind_variables = true)
              unify(@gt_constraints)
              @lt_constraints = graph.fold_groups.replace_groups(@lt_constraints)
              unify(@lt_constraints)
              unify(@send_constraints)
              graph.do_bindings! if bind_variables
              self
            end

            def bindings
              graph.vars
            end

            def print_constraints
              @gt_constraints.each do |(l, t, r)|
                l = if l.is_a?(Hash)
                      l.keys.map(&:to_s).join(',')
                    else
                      l.to_s
                    end
                puts "#{l} :gt #{r}"
              end
              @lt_constraints.each do |(l, t, r)|
                l = if l.is_a?(Hash)
                      l.keys.map(&:to_s).join(',')
                    else
                      l.to_s
                    end
                puts "#{l} :lt #{r}"
              end
              @send_constraints.each do |(l, t, send)|
                return_type = send[:return]
                arg_types = send[:args].map(&:to_s)
                message = send[:message]
                l = if l.is_a?(Hash)
                      l.keys.map(&:to_s).join(',')
                    else
                      l.to_s
                    end
                puts "#{l} :send #{message}[ #{arg_types.join(',')} -> #{return_type}]"
              end
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
                  graph.link(l, r)
                else
                  # - In the first invocation to unify, l must always be a TypeVar
                  #   t :gt and r a type variable or a type,
                  # - In the second invocation to unify, l must always be a group
                  #   t :lt and r a type variable,
                  check_constraint(l, t, r, t != :send) # we don't binc if constraint is send
                end
                unify(rest)
              end
            end

            def check_constraint(l, t, r, bind = true)
              value_l = graph[l][:type]
              # this will throw an exception if types no compatible
              compatible_type = compatible_type?(value_l, t, r)
              graph[l][:type] = compatible_type if bind
            end
          end
        end
      end
    end
  end
end
