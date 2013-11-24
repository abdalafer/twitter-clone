class Tweet
  include ActiveModel::Validations
  include ActiveModel::Conversion
  include ActiveModel::Naming

  attr_accessor :uid, :username, :tweet_message

  def get_all_tweets
    tweet_ids = ApiClient.neo_query("MATCH (ee:Person)-[:FOLLOWS]->(friends:Person)-[:TWEETED]->(t:Tweet) WHERE ee.uid = '#{self.uid}' or t.username='#{self.username}' RETURN t.tweet_id ORDER BY ID(t) DESC")["data"]
    return [] if tweet_ids.empty?
    @all_tweets = ApiClient.redis_get_msg(tweet_ids)
  end

  def tweet
    tweet_id = SecureRandom.urlsafe_base64
    ApiClient.elastic_post( { "uid"=>"#{self.uid}",  "username"=>"#{self.username}", "tweet_message"=>"#{self.tweet_message}" });

    #create tweet node
    ApiClient.neo_query("CREATE (n:Tweet {tweet_id:'#{tweet_id}', username:'#{self.username}', uid:'#{self.uid}'}) Return n")

    #create relationship between person node and tweet node
    ApiClient.neo_query("MATCH (n:Person), (m:Tweet) WHERE n.uid='#{self.uid}' and m.tweet_id='#{tweet_id}' create unique (n)-[:TWEETED]->(m)")
    tweet_body =  {:time => Time.now, :username => self.username, :tweet_message => self.tweet_message}
    ApiClient.redis_set_msg(tweet_id, tweet_body.to_json)
  end

  def persisted?
  end

  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end


end