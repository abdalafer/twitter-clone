class ApiClient
#todo error handling on failed connections
  def self.redis_get_msg(tweet_ids)
    ids = []
    tweet_ids.each do |id|
      ids << id.first
    end
    tweets = $redis.hmget("tweet", ids)
  end

  def  self.redis_set_msg(key, value)
    $redis.hset('tweet', key, value)
  end

  def self.redis_set(key, value)
    $redis.set(key, value)
  end

  def self.redis_get(key)
    $redis.get(key)
  end

  def self.redis_del(key)
    $redis.del(key)
  end

  def self.redis_exist(key)
    $redis.exists(key)
  end

  def self.redis_hmset(key, array_value)
    $redis.hmset(key, array_value)
  end

  def self.redis_hgetall(key)
    $redis.hgetall(key)
  end

  def self.neo_query(query)
    @neo = Neography::Rest.new
    @neo.execute_query(query)
  end

  def self.elastic_post(tweet_message)
    response = Typhoeus.post("#{ENV["ELASTICSEARC_URL"]}/twitter-clone/tweet/",
                             body:tweet_message.to_json)
  end

  def self.elastic_search(query)
    response = Typhoeus.get("#{ENV["ELASTICSEARC_URL"]}/twitter-clone/tweet/_search",
                            body:{'query'=>{'query_string'=>{'query'=>"#{query}"}}}.to_json)
  end
end