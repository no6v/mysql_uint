module ActiveRecord
  class SchemaDumper
    private

    alias_method :orig_table, :table

    def table(table, stream)
      columns = @connection.columns(table)
      begin
        tbl = StringIO.new
        pk = create_table_line(table, columns, tbl)
        column_specs = column_specs(pk, columns)
        column_spec_lines(column_specs, tbl)
        tbl.puts "  end"
        tbl.puts

        indexes(table, tbl)

        tbl.rewind
        stream.print tbl.read
      rescue => e
        stream.puts "# Could not dump table #{table.inspect} because of following #{e.class}"
        stream.puts "#   #{e.message}"
        stream.puts
      end

      stream
    end

    def create_table_line(table, columns, tbl)
      # first dump primary key column
      if @connection.respond_to?(:pk_and_sequence_for)
        pk, pk_seq = @connection.pk_and_sequence_for(table)
      elsif @connection.respond_to?(:primary_key)
        pk = @connection.primary_key(table)
      end

      tbl.print "  create_table #{table.inspect}"
      if columns.detect{ |c| c.name == pk }
        if pk != 'id'
          tbl.print %Q(, :primary_key => "#{pk}")
        end
      else
        tbl.print ", :id => false"
      end
      tbl.print ", :force => true"
      tbl.puts " do |t|"
      pk
    end

    def column_specs(pk, columns)
      # then dump all non-primary key columns
      column_specs = columns.map do |column|
        raise StandardError, "Unknown type '#{column.sql_type}' for column '#{column.name}'" if @types[column.type].nil?
        next if column.name == pk
        spec = {}
        spec[:name]      = column.name

        # AR has an optimisation which handles zero-scale decimals as integers.  This
        # code ensures that the dumper still dumps the column as a decimal.
        spec[:type]      = if column.type == :integer && [/^numeric/, /^decimal/].any? { |e| e.match(column.sql_type) }
                             'decimal'
                           else
                             column.type.to_s
                           end
        spec[:limit]     = column.limit if column.limit != @types[column.type][:limit] && spec[:type] != 'decimal'
        spec[:precision] = column.precision if !column.precision.nil?
        spec[:scale]     = column.scale if !column.scale.nil?
        spec[:null]      = false if !column.null
        spec[:default]   = default_string(column.default) if column.has_default?
        spec
      end.compact
    end

    def column_spec_lines(column_specs, tbl)
      column_specs.each do |spec|
        spec.each do |key, value|
          case key
          when :name
            spec[key] = value.inspect
          when :type
            # no-op
          else
            spec[key] = "#{key.inspect} => #{value.inspect}"
          end
        end
      end

      # find all migration keys used in this table
      keys = known_keys & column_specs.map(&:keys).flatten

      # figure out the lengths for each column based on above keys
      lengths = keys.map{ |key| column_specs.map{ |spec| spec[key] ? spec[key].length + 2 : 0 }.max }

      # the string we're going to sprintf our values against, with standardized column widths
      format_string = lengths.map{ |len| "%-#{len}s" }

      # find the max length for the 'type' column, which is special
      type_length = column_specs.map{ |column| column[:type].length }.max

      # add column type definition to our format string
      format_string.unshift "    t.%-#{type_length}s "

      format_string *= ''

      column_specs.each do |colspec|
        values = keys.zip(lengths).map{ |key, len| colspec.key?(key) ? colspec[key] + ", " : " " * len }
        values.unshift colspec[:type]
        tbl.print((format_string % values).gsub(/,\s*$/, ''))
        tbl.puts
      end
    end

    def known_keys
      [:name, :limit, :precision, :scale, :default, :null]
    end

    alias_method :orig_default_string, :default_string

    def default_string(value)
      case value
      when BigDecimal
        value.to_f
      when Date, DateTime, Time
        value.to_s(:db)
      else
        value
      end
    end
  end
end
