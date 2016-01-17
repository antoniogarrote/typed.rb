# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    class TmCaseWhen < Expr
      attr_reader :case_statement, :when_statements, :default_statement
      def initialize(node, case_statement, when_statements, default_statement)
        super(node, nil)
        @case_statement = case_statement
        @when_statements = when_statements
        @default_statement = default_statement
      end

      def check_type(context)
        conditions = build_conditionals(case_statement, when_statements)
        conditions = conditions.reduce([]) do |acc, (node, condition, then_statement)|
          next_condition = TmIfElse.new(node, condition, then_statement, nil)
          prev_condition = acc.last
          prev_condition.else_expr = next_condition unless prev_condition.nil?
          acc << next_condition
        end
        conditions.last.else_expr = default_statement if default_statement
        conditions.first.check_type(context)
      end

      protected

      def build_conditionals(case_statement, when_statements)
        when_statements.map do |when_statement|
          node, conditional, then_statement = when_statement
          condition = TmSend.new(case_statement, :===, [conditional], node)
          [node, condition, then_statement]
        end
      end
    end
  end
end
