require 'sqlite3'


class Database

  def initialize(dbdir, dbname=nil)
    @dbdir = dbdir
    @db_name = dbname.nil? ? "informer.db" : dbname 
    create_database unless File.exists? "#{@dbdir}/#{@db_name}" 
  end

  def db
    @db ||= SQLite3::Database.new "#{@dbdir}/#{@db_name}" 
  end

  def create_database
    sql_file_name = "#{File.dirname(__FILE__)}/db.sql"
    db_file = File.read sql_file_name
    db.execute db_file
  end

  def post_last_record(record)
    return unless record or not record[:commit] or record[:project_name]
    res = read_last_record(record[:project_name])
    sql = res.nil? ? "insert into commits values ('#{record[:commit]}', '#{record[:project_name]}')" 
	: "update commits set commit_id='#{record[:commit]}' where project_name='#{record[:project_name]}'" 
    db.execute sql 
  end

  def read_last_record(project_name)
    return unless project_name
    res = nil
    db.execute "select commit_id from commits where project_name='#{project_name}'" do |row|
      res = row.first
    end    
    res
  end
end
