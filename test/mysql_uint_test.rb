require 'test_helper'
require "test/unit"
require "stringio"

class MysqlUintTest < Test::Unit::TestCase
  def setup
    StringIO.open do |output|
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, output)
      @schema_dump = output.string
    end
  end

  def test_unsigned
    assert_match /"code1".+:unsigned => true/, @schema_dump
    assert_no_match /"code2".+:unsigned => true/, @schema_dump
    assert_match /"code3".+:unsigned => true/, @schema_dump
  end
end
