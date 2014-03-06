Gem::Specification.new do |s|
  s.name        = 'pivotal_tag_informer'
  s.version     = '0.0.19'
  s.date        = '2014-03-06'
  s.summary     = 'This gem just updates a pivotal story with a comment.'
  s.description = '' 
  s.authors     = ['Chris Kleeschulte']
  s.email       = 'rubygems@kleetus.33mail.com'
  s.files       = ['lib/informer.rb', 'lib/database.rb', 'lib/db.sql']
  s.required_ruby_version = '>= 1.9.3'
  s.homepage    = 'http://kleetus.org'
  s.executables << 'pivotal_tag_informer'
  s.add_dependency('pivotal-tracker-api', '= 0.1.6')
  s.add_dependency('sqlite3')
end
