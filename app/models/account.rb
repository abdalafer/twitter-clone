require 'digest/md5'
require 'bcrypt'

class Account
  include ActiveModel::Validations
  include ActiveModel::Conversion
  include ActiveModel::Naming

  attr_accessor :uid, :name, :email, :username, :password

  validates_presence_of :name, :username, :password, :password_confirmation
  validates :email, :presence => true, :format => { :with => /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i  }
  validates :password, confirmation: true

  validate :user_existence

  def user_existence
      if ApiClient.redis_exist("username:#{self.username}:uid")
        errors.add(:username, "User already exist")
      end
  end

  def self.login(username, password)
    existing_uid = ApiClient.redis_get("username:#{username}:uid")
    if !existing_uid
      return false
    end

    salt = "$2a$10$V.1dLTceBXG2YA.nAqTpI."
    salty_password = BCrypt::Engine.hash_secret(password, salt)

    if salty_password == ApiClient.redis_get("uid:#{existing_uid}:password")
      auth_id = ApiClient.redis_get("uid:#{existing_uid}:auth")
      return auth_id
    end

    false
  end

  def self.logout(auth_token)
    uid = ApiClient.redis_get("auth:#{auth_token}")
    new_auth_token = SecureRandom.urlsafe_base64

    ApiClient.redis_set("uid:#{uid}:auth", new_auth_token)
    ApiClient.redis_set("auth:#{new_auth_token}", uid)
    ApiClient.redis_del("auth:#{auth_token}")
  end

  def create
    self.uid = SecureRandom.urlsafe_base64
    salt = "$2a$10$V.1dLTceBXG2YA.nAqTpI." #future addition, store users salts in db
    salty_password = BCrypt::Engine.hash_secret(self.password, salt)

    self.password = salty_password

    #create user in neo
    ApiClient.neo_query("CREATE (n:Person {uid:'#{self.uid}', username:'#{self.username}', email:'#{self.email}'}) Return n")
    ApiClient.neo_query("START n=node(*), m=node(*) where n.uid='#{uid}' and m.uid='#{self.uid}' create unique (n)-[:FOLLOWS]->(m)")

    #store all users data
    ApiClient.redis_hmset("uid:#{self.uid}:details", ['uid', self.uid, 'name', self.name, 'email', self.email, 'username', self.username])
    ApiClient.redis_set("uid:#{self.uid}:username", self.username)
    ApiClient.redis_set("uid:#{self.uid}:password", self.password)
    ApiClient.redis_set("username:#{self.username}:uid", self.uid)

    auth_token = SecureRandom.urlsafe_base64

    ApiClient.redis_set("uid:#{self.uid}:auth", auth_token)
    ApiClient.redis_set("auth:#{auth_token}", self.uid)
  end

  def self.follow(uid, follow_uid)
    ApiClient.neo_query("START n=node(*), m=node(*) where n.uid='#{uid}' and m.uid='#{follow_uid}' create unique (n)-[:FOLLOWS]->(m)")
  end

  def self.unfollow(uid, followed_uid)
    query = "START n=node(*), m=node(*) where n.uid='#{uid}' and m.uid='#{followed_uid}' MATCH (n)-[r:FOLLOWS]->(m) delete r"
    ApiClient.neo_query(query)
  end

  def self.show_following_users(uid)
    @following_list = ApiClient.neo_query("MATCH (ee:Person)-[:FOLLOWS]->(friends:Person) WHERE ee.uid = '#{uid}' and not ee = friends RETURN friends.uid as uid, friends.username as username")["data"]

    @following_list
  end

  def self.show_all_users(uid)
    @all_users = ApiClient.neo_query("START n=node(*), m=node(*) MATCH (n:Person)-[r?]->(m:Person) WHERE n.uid = '#{uid}' and not n = m and r IS NULL RETURN m.uid as uid, m.username as username")["data"]
    @all_users
  end

  def self.user_summary(username)
    following = ApiClient.neo_query("MATCH (ee:Person)-[:FOLLOWS]->(friends:Person) WHERE ee.username = '#{username}' RETURN  COUNT(ee)")["data"]
    followers = ApiClient.neo_query("MATCH (ee:Person)<-[:FOLLOWS]-(friends:Person) WHERE ee.username = '#{username}' RETURN  COUNT(friends)")["data"]
    tweet_count = ApiClient.neo_query("MATCH (ee:Person)-[:TWEETED]->(tweet:Tweet) WHERE ee.username = '#{username}' RETURN Count(tweet)")["data"]
    {:username=> username, :following => following.first.first, :followers => followers.first.first, :tweet_count => tweet_count.first.first}
  end

  def self.search(query)
    search_response = ApiClient.elastic_search(query)
    response_body = JSON.parse(search_response.options[:response_body])
    if response_body['hits'].count > 0
      return @search_hits = response_body['hits']['hits']
    end
  end

  def persisted?
  end

  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end
end