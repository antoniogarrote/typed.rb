require 'stringio'

module TypedRb
  module Types
    # Polymorphic additions to Featherweight Ruby
    module Polymorphism

      class UnitificationError < TypedRb::TypeCheckError; end

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
        rescue Types::UncomparableTypes => error
          if join_if_false
            value_l.join(value_r)
          else
            fail error
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
              fail UnificationError, "Message #{message} not found for type variable #{receiver}"
            end
          else
            fail UnificationError, "Unbound variable #{receiver} type acting as receiver for #{message}"
          end
        end

        def can_apply?(fn, arg_types)
          if fn.dynamic?
            true
          else
            arg_types.each_with_index do |arg, i|
              fn_arg = fn.from[i]
              if arg.is_a?(TypeVariable)
                type = compatible_lt_type?(graph[arg][:type], fn_arg)
                graph[arg][:type] = type
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
          text = StringIO.new
          text << "Doing bindings:\n"
          num_bindings = 0
          groups.values.each do |group|
            next unless group[:type]
            group[:vars].keys.each do |var|
              num_bindings += 1
              text << "Final binding:  #{var.variable} -> #{find_type(group[:type])}\n"
              var.bind(find_type(group[:type]))
            end
          end
          text << "Found #{num_bindings} bindings"
          TypedRb.log(binding, :debug, text.string)
        end

        def find_type(value)
          # type variable
          if value.is_a?(TypeVariable)
            find_type(value.bound)
          # group
          elsif value.is_a?(Hash) && value[:type]
            find_type(value[:type])
          # type
          elsif value.is_a?(Type)
            value
          # nil
          else
            fail UnificationError, 'Cannot find type in type_variable binding' if value.nil?
          end
        end

        def print_groups
          TypedRb.log(binding, :debug, "Variable groups:")
          groups.values.uniq.each do |group|
            vars = group[:vars].keys.map(&:to_s).join(',')
            type = group[:type] ? group[:type].to_s : '?'
            links = group[:links].map(&:to_s).join(' < ')
            TypedRb.log(binding, :debug, "#{vars}:#{type} => #{links}")
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
          # TODO: types???
          group_common[:type] = max_type(group_l[:type], group_r[:type])
          vars_common.keys.each { |var|  groups[var] = group_common }
        end

        def max_type(type_a, type_b)
          if type_a.nil? || type_b.nil?
            type_a || type_b
          else
            compatible_type?(value_l, value_r, true)
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

        def initialize(constraints)
          @constraints = constraints
          @gt_constraints = @constraints.select { |(_, t, _r)| t == :gt }.sort do |(_, _, r1), (_, _, r2)|
            -(r1 <=> r2) || 0 rescue 0
          end
          @lt_constraints = @constraints.select { |(_, t, _r)| t == :lt }.sort do |(_, _, r1), (_, _, r2)|
            (r1 <=> r2) || 0 rescue 0
          end
          @send_constraints = @constraints.select { |(_, t, _r)| t == :send }
          @graph = Topography.new(@constraints)
        end

        def run(bind_variables = true)
          print_constraints
          unify(@gt_constraints) # we create links between vars in unify, we need to fold groups afterwards
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
          text = StringIO.new
          text << "Running unification on #{constraints.size} constraints:\n"
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
              graph.link(l, r)
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
          value_l = graph[l][:type]
          #value_r = r.is_a?(Hash) ? graph[r][:type] : r
          value_r = r
          # this will throw an exception if types no compatible
          compatible_type = compatible_type?(value_l, t, value_r)
          graph[l][:type] = compatible_type if bind
        end
      end
    end
  end
end
