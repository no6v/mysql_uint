module ActiveRecord
  module ConnectionAdapters
    class ColumnDefinition
      attr_accessor :unsigned
    end

    class TableDefinition
      unless method_defined?(:column_with_unsigned)
        def column_with_unsigned(name, type, options = {})
          column_without_unsigned(name, type, options).tap do |column|
            column[name].unsigned = options[:unsigned]
          end
        end

        alias_method_chain :column, :unsigned
      end
    end

    module SchemaStatements
      unless method_defined?(:add_column_options_with_unsigned!)
        def add_column_options_with_unsigned!(sql, options)
          if options[:unsigned] || (options[:column] && options[:column].unsigned)
            sql << " UNSIGNED"
          end
          add_column_options_without_unsigned!(sql, options)
        end

        alias_method_chain :add_column_options!, :unsigned
      end
    end
  end

  class SchemaDumper
    private

    unless private_method_defined?(:column_specs_with_unsigned)
      def column_specs_with_unsigned(pk, columns)
        column_specs_without_unsigned(pk, columns).tap do |column_specs|
          columns.each do |column|
            if column.sql_type.downcase.include?(" unsigned")
              name = column.name
              if column_spec = column_specs.find{|spec| spec[:name] == name}
                column_spec[:unsigned] = true
              end
            end
          end
        end
      end

      alias_method_chain :column_specs, :unsigned
    end

    unless private_method_defined?(:known_keys_with_unsigned)
      def known_keys_with_unsigned
        known_keys_without_unsigned | [:unsigned]
      end

      alias_method_chain :known_keys, :unsigned
    end
  end
end
