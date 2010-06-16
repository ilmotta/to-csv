# encoding: UTF-8

module ToCSV

  CSVClass = RUBY_VERSION < '1.9' ? ::FasterCSV : ::CSV

  class Converter
    def initialize(data, options = {}, csv_options = {}, &block)
      @opts = options.to_options.reverse_merge({
        :byte_order_marker => ToCSV.byte_order_marker,
        :locale            => ToCSV.locale || ::I18n.locale,
        :primary_key       => ToCSV.primary_key,
        :timestamps        => ToCSV.timestamps
      })

      @opts[:only]    = Array(@opts[:only]).map(&:to_s)
      @opts[:except]  = Array(@opts[:except]).map(&:to_s)
      @opts[:methods] = Array(@opts[:methods]).map(&:to_s)

      @data = data
      @block = block
      @csv_options = csv_options.to_options.reverse_merge(ToCSV.csv_options)
      @associations = @opts[:include].kind_of?(Array) ? @opts[:include] : [@opts[:include]] if @opts[:include]
    end

    def to_csv
      build_headers_and_rows

      output = CSVClass.generate(@csv_options) do |csv|
        csv << @header_row if @header_row.try(:any?)
        @rows.each { |row| csv << row }
      end

      @opts[:byte_order_marker] ? "\xEF\xBB\xBF#{output}" : output
    end

    private
      def build_headers_and_rows
        send "headers_and_rows_from_#{ discover_data_type }"
      end

      def discover_data_type
        test_data = @data.first
        return 'ar_object' if instance_of_active_record? test_data
        return 'hash' if test_data.is_a? Hash
        return 'unidimensional_array' if test_data.is_a?(Array) && !test_data.first.is_a?(Array)
        return 'bidimensional_array' if test_data.is_a?(Array) && test_data.first.is_a?(Array) && test_data.first.size == 2
        'simple_data'
      end

      def instance_of_active_record?(obj)
        obj.class.base_class.superclass == ActiveRecord::Base
      rescue Exception
        false
      end

      def headers_and_rows_from_simple_data
        @header_row = nil
        @rows = [@data.dup]
      end

      def headers_and_rows_from_hash
        @header_row = @data.first.keys if display_headers?
        @rows = @data.map(&:values)
      end

      def headers_and_rows_from_unidimensional_array
        @header_row = @data.first if display_headers?
        @rows = @data[1..-1]
      end

      def headers_and_rows_from_bidimensional_array
        @header_row = @data.first.map(&:first) if display_headers?
        @rows = @data.map { |array| array.map(&:last) }
      end

      def headers_and_rows_from_ar_object
        attributes = sort_attributes(filter_attributes(attribute_names))
        if display_headers?
          @header_row =  human_attribute_names(attributes)
          @header_row |= human_attribute_names(headers_from_association_ar_object) if @opts[:include]
        end
        @rows = if @block
          attributes_class = Struct.new(*attributes.map(&:to_sym))
          @data.map do |item|
            @block.call(obj = attributes_class.new, item)
            result = attributes.map { |attribute| obj[attribute] || try_formatting_date(item.send(attribute)) }
            (result << rows_from_association_ar_object(item);result.flatten!) if @opts[:include] && @row_header_association
            result
          end
        else
          @data.map do |item|
            result = attributes.map { |attribute| try_formatting_date item.send(attribute) }
            (result << rows_from_association_ar_object(item);result.flatten!) if @opts[:include] && @row_header_association
            result
          end
        end
      end

      def rows_from_association_ar_object(item)
        @result = []
        @associations.each do |association|
          @row_header_association = instance_variable_get("@row_header_association_for_#{from_sym_to_string(association)}")
          association = association.to_sym
          case item.class.reflect_on_association(association).macro
            when :has_many, :has_and_belongs_to_many
              records = item.send(association).to_a
              unless records.empty?
                records.collect do |record|
                  @row_header_association.map do |attribute|
                    @result << try_formatting_date(record.send(attribute))
                  end
                end
              end
            when :has_one, :belongs_to
              if record = item.send(association)
                @row_header_association.map do |attribute|
                  @result <<  try_formatting_date(record.send(attribute))
                end
              end
          end
        end
        @result.flatten
      end

      def headers_from_association_ar_object
        @header_association = []
        @associations.each do |association|
          association = association.to_sym
          case @data.first.class.reflect_on_association(association).macro
            when :has_many, :has_and_belongs_to_many
              records = @data.first.send(association).to_a
              unless records.empty?
                instance_variable_set("@row_header_association_for_#{from_sym_to_string(association)}", records.first.attribute_names.map(&:to_s))
                @row_header_association = instance_variable_get("@row_header_association_for_#{from_sym_to_string(association)}")
                (1..records.size).each do |record|
                  @row_header_association.map do |header|
                    @header_association << "#{from_sym_to_string(association)}_#{record}_#{header}"
                  end
                end
              end
            when :has_one, :belongs_to
              instance_variable_set("@row_header_association_for_#{from_sym_to_string(association)}", @data.first.send(association).attribute_names.map(&:to_s))
              @row_header_association = instance_variable_get("@row_header_association_for_#{from_sym_to_string(association)}")
              @data.first.send(association).attribute_names.map do |header|
                @header_association << "#{from_sym_to_string(association)}_#{header}"
              end
          end
        end
        @header_association.flatten
      end

      def display_headers?
        @opts[:headers].nil? || (Array(@opts[:headers]).any? && Array(@opts[:headers]).all? { |h| h != false })
      end

      def human_attribute_names(attributes)
        @opts[:locale] ? translate(attributes) : humanize(attributes)
      end

      def humanize(attributes)
        attributes.map(&:humanize)
      end

      def translate(attributes)
        ::I18n.with_options :locale => @opts[:locale], :scope => [:activerecord, :attributes, @data.first.class.to_s.underscore] do |locale|
          attributes.map { |attribute| locale.t(attribute, :default => attribute.humanize) }
        end
      end

      def try_formatting_date(value)
        is_a_date?(value) ? value.to_s(:db) : value
      end

      def is_a_date?(value)
        value.is_a?(Time) || value.is_a?(Date) || value.is_a?(DateTime)
      end

      def primary_key_filter(attributes)
        return attributes if @opts[:primary_key]
        attributes - Array(@data.first.class.primary_key.to_s)
      end

      def timestamps_filter(attributes)
        return attributes if @opts[:timestamps]
        return attributes if (@opts[:only] + @opts[:except]).any? { |attribute| timestamps.include? attribute }
        attributes - timestamps
      end

      def timestamps
        @timestamps ||= %w[ created_at updated_at created_on updated_on ]
      end

      def methods_filter(attributes)
        attributes | @opts[:methods]
      end

      def only_filter(attributes)
        return attributes if @opts[:only].empty?
        attributes & @opts[:only]
      end

      def except_filter(attributes)
        attributes - @opts[:except]
      end

      def attribute_names
        @data.first.attribute_names.map(&:to_s)
      end

      def filter_attributes(attributes)
        attributes = methods_filter(attributes)
        attributes = primary_key_filter(attributes)
        attributes = timestamps_filter(attributes)
        attributes = @opts[:only].any?? only_filter(attributes) : except_filter(attributes)
        attributes
      end

      def sort_attributes(attributes)
        attributes = attributes.map(&:to_s).sort
        return attributes if @opts[:headers].nil?
        headers = Array(@opts[:headers]).map(&:to_s)
        headers.delete_if { |attribute| attribute == 'false' }
        if index = headers.index('all')
          (headers & attributes).insert(index, (attributes - headers)).flatten
        else
          headers + (attributes - headers)
        end
      end

      def from_sym_to_string(sym)
        sym.to_s.gsub(':','')
      end

  end
end

