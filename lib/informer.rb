require 'pivotal-tracker'
require 'yaml'
require 'sqlite3'
require_relative './database.rb'

class Informer
  attr_writer :for_realsies, :testdb, :dbdir

  include PivotalTracker
 
  def initialize(path_to_pivotal_credentials)
    unless File.exists?(path_to_pivotal_credentials)
      puts "#{path_to_pivotal_credentials} does not exist, exiting!}"
      return
    end
    @config = YAML::load_file(path_to_pivotal_credentials)
    PivotalTracker::Client.token = @config['token'] 
    @proj = PivotalTracker::Project.find(@config['project'])
    @dbdir = @config['dbdir']
    unless @proj
      puts "Could not find a pivotal project with the token and project provided, exiting!"
      return
    end
  end

  def send_tag(tag)
    @tag = tag
    @commit_msg = `git log -n 1` 
    story_ids = process_tag
    if story_ids.length < 1 
      puts "I could not pull out the story ids from: #{@commit_msg}\n\n-OR- we have already sent this tag to Pivotal"
      return
    end
    stories = []
    story_ids.each do |story_id|
      stories << @proj.stories.find(story_id)  
    end
    stories = check_stories_for_tag_type(stories)
    if stories.length < 1 
      puts "stories could not be found from this commit msg: #{@commit_msg} \nexiting!"
      return
    end 
    send_to_pivotal stories
  end

  def send_to_pivotal(stories)
    res = stories.map do |story|
      next if story.nil?
      story.notes.create(:text => @tag) if @for_realsies
      puts "The following note was added to story id: #{story.id}: #{@tag}"
      {story.id => @tag}
    end
  end

  private
  def process_tag
    current_sha = parse_out_commit
    return unless current_sha
    db = Database.new(@dbdir, @testdb)
    last_read_sha = db.read_last_record(project_name)
    db.post_last_record({commit: current_sha, project_name: project_name})
    diff_log = compute_diff_log(current_sha, last_read_sha) 
    return [] unless diff_log
    res = diff_log.gsub(/\s+/, '')
    return res if res.length < 1
    list_of_ids = res.scan(/\[(\d+)|\/*(\d+)\]/)
    list_of_ids.is_a?(Array) ? list_of_ids.flatten.compact.uniq : [] 
  end
 
  def project_name
    @project_name ||= File.expand_path('.').split('/').send("[]",  (File.directory?('.git') ? -1 : -2))
  end

  def parse_out_commit
    res = @commit_msg.scan(/commit[\s*]([a-z|0-9]+)$/).first 
    sha = res.first unless res.nil?
    sha[0..7] if sha.length>7
  end

  def compute_diff_log(current, last)
    return `git log -n 1` unless last 
    return `git log #{last}..#{current}` if current != last 
  end

  def check_stories_for_tag_type(stories)
    ret = []
	
    stories.each do |story|
      labels = story.labels.scan(/(ag)|(rent)/).flatten.compact!
      labels << "apartmentguide" if labels.member? 'ag'
      labels.each do |label|
        ret << story if project_name =~ /#{label}/
      end
    end 
    ret
  end
end
