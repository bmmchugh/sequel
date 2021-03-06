require 'rubygems'

if defined?(RSpec)
  begin
    require 'rspec/expectations'
  rescue LoadError
    nil
  end
end

unless Object.const_defined?('Sequel') && Sequel.const_defined?('Model')
  $:.unshift(File.join(File.dirname(File.expand_path(__FILE__)), "../../lib/"))
  require 'sequel/no_core_ext'
end

begin
  # Attempt to load ActiveSupport inflector first, so Sequel inflector
  # can override it.
  require 'active_support/inflector'
  require 'active_support/core_ext/string/inflections'
rescue LoadError
  nil
end

# Load most extensions by default, so that any conflicts are easily detectable.
Sequel.extension(*%w'string_date_time inflector pagination query pretty_table blank migration schema_dumper looser_typecasting sql_expr thread_local_timezones to_dot columns_introspection server_block arbitrary_servers pg_auto_parameterize pg_statement_cache pg_array pg_array_ops pg_hstore pg_hstore_ops pg_range pg_range_ops pg_json pg_inet pg_row pg_row_ops schema_caching null_dataset select_remove query_literals eval_inspect')

Sequel::Dataset.introspect_all_columns if ENV['SEQUEL_COLUMNS_INTROSPECTION']

def skip_warn(s)
  warn "Skipping test of #{s}" if ENV["SKIPPED_TEST_WARN"]
end

Sequel.quote_identifiers = false
Sequel.identifier_input_method = nil
Sequel.identifier_output_method = nil

class << Sequel::Model
  attr_writer :db_schema
  alias orig_columns columns
  def columns(*cols)
    return super if cols.empty?
    define_method(:columns){cols}
    @dataset.instance_variable_set(:@columns, cols) if @dataset
    def_column_accessor(*cols)
    @columns = cols
    @db_schema = {}
    cols.each{|c| @db_schema[c] = {}}
  end
end

Sequel::Model.use_transactions = false
Sequel::Model.cache_anonymous_models = false

db = Sequel.mock(:fetch=>{:id => 1, :x => 1}, :numrows=>1, :autoid=>proc{|sql| 10})
def db.schema(*) [[:id, {:primary_key=>true}]] end
def db.reset() sqls end
Sequel::Model.db = MODEL_DB = db
