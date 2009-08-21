if ActiveRecord::Base.configurations[RAILS_ENV]["adapter"] == "mysql"
  require "better_schema_dumper"
  require "mysql_uint"
end
