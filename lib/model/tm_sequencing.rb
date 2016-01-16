# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    class TmSequencing < Expr
      attr_accessor :terms
      def initialize(terms, node)
        super(node)
        @terms = terms.reject(&:nil?)
      end

      def check_type(context)
        process_terms_before_return(@terms, context)
      end

      private

      def process_terms_before_return(terms, context, processed_terms=[], potential_return=nil)
        if terms.empty?
          make_final_return(processed_terms.last, potential_return)
        else
          term_type = terms.first.check_type(context)
          if term_type.stack_jump?
            process_terms_after_return(terms.drop(1), context)
            make_final_return(term_type, potential_return)
          elsif term_type.either?
            process_terms_before_return(terms.drop(1), context, processed_terms << nil, make_final_return(term_type, potential_return))
          else
            process_terms_before_return(terms.drop(1), context, processed_terms << term_type, potential_return)
          end
        end
      end

      def process_terms_after_return(terms, context)
        terms.each { |term| term.check_type(context) }
      end


      def make_final_return(type_a, type_b)
        return (type_a || type_b) if type_a.nil? || type_b.nil?
        either_types = [type_a, type_b].map{ |type| Types::TyEither.wrap(type) }
        reduced_final_type = either_types.reduce { |a,b| a.compatible_either?(b) }.unwrap
        if type_a.stack_jump? || type_b.stack_jump?
          jump_kind = [type_a, type_b].detect {|type| type.stack_jump? }.jump_kind
          reduced_final_type[jump_kind]
        else
          reduced_final_type
        end
      end
    end
  end
end
