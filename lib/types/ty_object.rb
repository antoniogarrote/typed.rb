module TypedRb
  module Types
    class UncomparableTypes < TypeCheckError
      attr_reader :from, :to
      def initialize(from, to, node = nil)
        nodes = [from.node, to.node].compact
        if node
          super("Cannot compare types #{from} <=> #{to}", node)
        elsif nodes.size == 2
          super("Cannot compare types #{from} <=> #{to}", nodes)
        elsif nodes.size == 1
          super("Cannot compare types #{from} <=> #{to}", nodes.first)
        else
          super("Cannot compare types #{from} <=> #{to}", nil)
        end
      end
    end

    class TyObject < Type
      include Comparable

      attr_reader :hierarchy, :classes, :modules, :ruby_type, :with_ruby_type

      def initialize(ruby_type, node = nil, classes = [], modules = [])
        super(node)
        if ruby_type
          @ruby_type = ruby_type
          @hierarchy = ruby_type.ancestors
          @classes = @hierarchy.select { |klass| klass.instance_of?(Class) }
          @modules = @hierarchy.select { |klass| klass.instance_of?(Module) }
          @with_ruby_type = true
        else
          @ruby_type = classes.first
          @classes = classes
          @modules = modules
          @hierarchy = (modules + classes).uniq
          @with_ruby_type = false
        end
      end

      def dynamic?
        false
      end

      def generic?
        false
      end

      def singleton?
        false
      end

      def either?
        false
      end

      def check_type(_context)
        self
      end

      def compatible?(other_type, relation = :lt)
        if other_type.is_a?(TyObject)
          begin
            if relation == :gt
              self >= other_type
            elsif relation == :lt
              self <= other_type
            end
          rescue ArgumentError
            raise UncomparableTypes.new(self, other_type)
          end
        else
          other_type.compatible?(self, relation == :lt ? :gt : :lt)
        end
      end

      def as_object_type
        self
      end

      # Non generic type, the function is alwasy going to be concrete
      def find_function_type(message, num_args, block)
        klass, function = find_function_type_in_hierarchy(:instance, message, num_args, block)
        if klass != ruby_type && function.generic?
          generic_type = ::BasicObject::TypeRegistry.find_generic_type(klass)
          if generic_type.nil?
            return klass, function # generic method in non-generic class
          elsif generic_type.type_vars.size == 1
            generic_type.materialize([self]).find_function_type(message, num_args, block)
          else
            fail "Undeclared generic type variables for #{ruby_type} super class/mix-in #{klass.class} #{klass}##{message}, please add a 'super' type annotation"
          end
        else
          return klass, function
        end
      end

      def find_var_type(var, _type = ruby_type)
        # This is only in case the type has been explicitely declared
        var_type = BasicObject::TypeRegistry.find(:instance_variable, ruby_type, var)
        if var_type
          var_type
        else
          # If no types has been declared, we'll find a var type in the registry
          var_type = Types::TypingContext.type_variable_for(:instance_variable, var, hierarchy)
          var_type.node = node
          var_type
        end
      end

      def find_function_type_in_hierarchy(kind, message, num_args, block)
        initial_value = select_matching_function_in_class(@hierarchy.first, kind, message, num_args, block)
        @hierarchy.drop(1).inject([@hierarchy.first, initial_value]) do |(klass, acc), type|
          if acc.nil? || acc.is_a?(TyDynamicFunction)
            maybe_function = select_matching_function_in_class(type, kind, message, num_args, block)
            [type, (maybe_function || TyDynamicFunction.new(klass, message))]
          else
            [klass, acc]
          end
        end
      end

      def resolve_ruby_method(message)
        @ruby_type.instance_method(message)
      end

      def to_s
        if @with_ruby_type
          @ruby_type.name
        else
          "#{@classes.first} with [#{@modules.map(&:to_s).join(',')}]"
        end
      end

      def union(other_type, node = nil)
        smaller_common_class = (classes & other_type.classes).first
        TyObject.new(smaller_common_class, (node || self.node || other_type.node))
      end

      def <=>(other)
        if other.is_a?(TyObject)
          if other.with_ruby_type
            if with_ruby_type
              compare_ruby_ruby(other)
            else
              compare_with_union(other)
            end
          else
            if with_ruby_type
              compare_with_union(other)
            else
              compare_with_union(other)
            end
          end
        #else
        #  fail UncomparableTypes.new(self, other)
        end
      end

      def join(other)
        common_classes = classes & other.classes
        common_modules = modules & other.modules
        if common_modules.size == 1
          TyObject.new(common_modules.first, (node || other.node))
        else
          TyObject.new(nil, (node || other.node), common_classes, common_modules)
        end
      end

      protected

      def compare_ruby_ruby(other)
        if ruby_type == NilClass && other.ruby_type == NilClass
          0
        elsif ruby_type == NilClass
          -1
        elsif other.ruby_type == NilClass
          1
        else
          if other.ruby_type == ruby_type
            0
          elsif other.hierarchy.include?(ruby_type)
            1
          elsif hierarchy.include?(other.ruby_type)
            -1
          #else
          #  fail UncomparableTypes.new(self, other)
          end
        end
      end

      def compare_with_union(other)
        all_those_modules_included = other.modules.all? { |m| hierarchy.include?(m) }
        all_these_modules_included = modules.all? { |m| other.hierarchy.include?(m) }

        if other.ruby_type == ruby_type && all_these_modules_included && all_these_modules_included
          0
        elsif other.hierarchy.include?(ruby_type) && all_these_modules_included && !all_those_modules_included
          1
        elsif hierarchy.include?(ruby_type) && all_those_modules_included && !all_these_modules_included
          -1
        #else
        #  fail UncomparableTypes.new(self, other)
        end
      end

      def select_matching_function_in_class(klass, kind, message, num_args, block)
        functions = BasicObject::TypeRegistry.find(kind, klass, message)
        initial_values = functions.select { |fn| fn.arg_compatible?(num_args) }
        if initial_values.count == 2 && block
          initial_values.detect(&:block_type)
        elsif initial_values.count == 2 && !block
          initial_values.detect { |f| f.block_type.nil? }
        else
          initial_values.first
        end
      end
    end

    class TyInteger < TyObject
      def initialize(node = nil)
        super(Integer, node)
      end
    end

    class TyFloat < TyObject
      def initialize(node = nil)
        super(Float, node)
      end
    end

    class TyString < TyObject
      def initialize(node = nil)
        super(String, node)
      end
    end

    class TyUnit < TyObject
      def initialize(node = nil)
        super(NilClass, node)
      end
    end

    class TySymbol < TyObject
      def initialize(node = nil)
        super(Symbol, node)
      end
    end

    class TyRegexp < TyObject
      def initialize(node = nil)
        super(Regexp, node)
      end
    end
  end
end
