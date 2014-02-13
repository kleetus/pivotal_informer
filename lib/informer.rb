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
      exit -1
    end
    @config = YAML::load_file(path_to_pivotal_credentials)
    PivotalTracker::Client.token = @config['token'] 
    @proj = PivotalTracker::Project.find(@config['project'])
    @dbdir = @config['dbdir']
    unless @proj
      puts "Could not find a pivotal project with the token and project provided, exiting!"
      exit -1
    end
  end

  def send_tag(tag)
    @tag = tag
    @commit_msg = `git log -n 1` 
    story_ids = process_tag
    if story_ids.length < 1 
      puts "I could not pull out the story ids from: #{@commit_msg}"
      exit -1
    end
    stories = []
    story_ids.each do |story_id|
      stories << @proj.stories.find(story_id)  
    end
    if stories.length < 1 
      puts "stories could not be found from this commit msg: #{@commit_msg}, exiting!"
      exit -1
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
    current_sha = parse_out_commit(@commit_msg)
    return unless current_sha
    db = Database.new(@dbdir, @testdb)
    project_name = File.expand_path('.').split('/').last
    last_read_sha = db.read_last_record(project_name)
    diff_log = compute_diff_log(current_sha, (last_read_sha||current_sha)) 
    db.post_last_record({commit: current_sha, project_name: project_name})
    res = diff_log.gsub(/\s+/, '')
    return res if res.length < 1
    list_of_ids = res.scan(/\[(\d+)|\/*(\d+)\]/)
    list_of_ids.is_a?(Array) ? list_of_ids.flatten.compact.uniq : [] 
  end
 
  def parse_out_commit(msg)
    res = msg.scan(/commit[\s*]([a-z|0-9]+)[\s*]Author/).first 
    sha = res.first unless res.nil?
    sha[0..7] if sha.length>7
  end

  def compute_diff_log(current, last)
    current != last ? `git log #{last}..#{current}` : `git log -n 1`
  end

end
