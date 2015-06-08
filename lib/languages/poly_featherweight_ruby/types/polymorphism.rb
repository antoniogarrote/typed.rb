module TypedRb
  module Languages
    module PolyFeatherweightRuby
      module Types
        module Polymorphism
          class TypeVariable
            def initialize(var_name)
              @constraings = []
              @variable = TypedRb::Languages::PolyFeatherweightRuby::Model::GenSym.next("TV_#{var_name}")
            end

            def add_constraint(type)
              @constraints << type
            end
          end
        end
      end
    end
  end
end
