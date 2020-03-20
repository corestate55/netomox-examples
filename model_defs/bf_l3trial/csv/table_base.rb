# frozen_string_literal: true

require 'csv'

# commons for table/table-record.
class TableObjectBase
  def initialize(debug = false)
    @debug = debug
  end

  # debug print
  def debug(*message)
    puts message if @debug
  end
end

# Base class for csv-wrapper
class TableBase < TableObjectBase
  def initialize(target, table_file, debug = false)
    super(debug)

    @records = 'will be overwritten in sub-class.'
    return if table_file.nil?

    csv_dir = "model_defs/bf_l3trial/csv/#{target}"
    @orig_table = CSV.table("#{csv_dir}/#{table_file}")
  end

  def to_s
    # for debugging
    @records.to_s
  end
end

# Base class for record of csv-wrapper
class TableRecordBase < TableObjectBase
  def initialize(debug = false)
    super(debug)
  end

  # get multiple method-results
  def values(attrs)
    attrs.map { |attr| send(attr) }
  end
end
