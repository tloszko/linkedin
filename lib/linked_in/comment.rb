module LinkedIn
  class Comment < LinkedIn::Base
    lazy_attr_reader :id, :posted_at, :text, :user


    #@return [LinkedIn::Comment]
    def initialize(attrs={})
      super
    end

    #@return [String]
    def text
      @text ||= @attrs["comment"] unless @attrs["comment"].nil?
    end

    #@return Time
    def posted_at
      @posted_at ||= Time.at(@attrs["timestamp"]/1000) unless @attrs["timestamp"].nil?
    end

    #@return [LinkedIn::User]
    def user
      @user ||= LinkedIn::User.new(@attrs["person"]) if @attrs["person"]
    end
  end
end