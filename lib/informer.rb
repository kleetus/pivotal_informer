require 'pivotal-tracker'
require 'yaml'

class Informer
  attr_writer :for_realsies

  include PivotalTracker
 
  def initialize(path_to_pivotal_credentials)
    unless File.exists?(path_to_pivotal_credentials)
      puts "#{path_to_pivotal_credentials} does not exist, exiting!}"
      exit -1
    end
    @config = YAML::load_file(path_to_pivotal_credentials)
    PivotalTracker::Client.token = @config['token'] 
    @proj = PivotalTracker::Project.find(@config['project'])
    unless @proj
      puts "Could not find a pivotal project with the token and project provided, exiting!"
      exit -1
    end
  end

  def send_tag(commit_msg, tag)
    story_ids = process_tag(commit_msg)
    if story_ids.length < 1 
      puts "I could not pull out the story ids from: #{commit_msg}"
      exit -1
    end
    stories = []
    story_ids.each do |story_id|
      stories << @proj.stories.find(story_id)  
    end
    if stories.length < 1 
      puts "stories could not be found from this commit msg: #{commit_msg}, exiting!"
      exit -1
    end 
    stories.each do |story|
      next if story.nil?
      story.notes.create(:text => tag) if @for_realsies
      puts "The following note was added to story id: #{story.id}: #{tag}"
    end
  end

  private
  def process_tag(tag)
    res = tag.gsub(/\s+/, '')
    return res if res.length < 1
    #check for pivotal ids and possibly multiples separated by '/' all within '[]'
    #example "[JO][55560306/55560794] Merging over the updates for the Advanced Scr"
    #example "[CHR] [58243650] Fix floorplans not linking to correct image from det"
    list_of_ids = res.scan(/\[(\d+)|\/*(\d+)\]/)
    list_of_ids.is_a?(Array) ? list_of_ids.flatten.compact : [] 
  end

end
