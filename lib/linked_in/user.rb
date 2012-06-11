module LinkedIn
  class User < LinkedIn::Base
    lazy_attr_reader :headline, :id, :name, :profile_image, :profile_url


    #@return [LinkedIn::User]
    def initialize(attrs={})
      super
    end

    #@return [String]
    def name
      @name ||= (@attrs["id"] == "private") ? "someone" : @attrs["first_name"] + " " + @attrs["last_name"] unless @attrs["id"].nil?
    end

    #@return [String]
    def profile_image
      @profile_image ||= @attrs["picture_url"] if @attrs["picture_url"]
    end

    #@return [String]
    def profile_url
      @profile_url ||=
           if @attrs["id"] == "private"
             nil
           else
             return @attrs["site_standard_profile_request"].url if @attrs["site_standard_profile_request"]
             "http://www.linkedin.com/profile/view?id=#{@attrs["id"]}"
           end
    end

  end
end