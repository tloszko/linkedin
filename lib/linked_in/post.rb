module LinkedIn
  class Post < LinkedIn::Base
    lazy_attr_reader :activities, :commentable, :comments, :likable, :liked, :num_likes,
                     :post_type, :posted_at, :text, :update_key, :user


    #@return [LinkedIn::Post]
    def initialize(attrs={})
      super
      self.activities
    end

    # @return [LinkedIn::Activity]
    def activities
      @activities ||= create_activities(@attrs)
    end

    # @return [Boolean]
    def commentable
      @commentable ||= @attrs["is_commentable"]
    end

    # @return [LinkedIn::Comments]
    def comments
      @comments ||= @attrs["update_comments"].nil? ? [] : @attrs["update_comments"].fetch("all", []).map{|comment| LinkedIn::Comment.new(comment)}
    end

    # @return [Boolean]
    def likable
      @likable ||= @attrs["is_likable"] unless @attrs["is_likable"].nil?
    end

    # @return [Boolean]
    def liked
      @liked ||= @attrs["is_liked"] unless @attrs["is_liked"].nil?
    end

    #@return Time
    def posted_at
      @posted_at ||= Time.at(@attrs["timestamp"]/1000) unless @attrs["timestamp"].nil?
    end

    # @return [Symbol]
    def post_type
      #@post_type ||= @attrs["update_type"].downcase.to_sym unless @attrs["update_type"].nil?
      @post_type ||= guess_post_type(@attrs)
    end

    # @return [String]
    def text
      @text ||= case @attrs["update_type"]
                  when "STAT" then @attrs["update_content"]["person"]["current_status"]
                  when "SHAR" then @attrs["update_content"]["person"]["comment"]
                  when "VIRL" then "added_#{@attrs["update_action"]["action"]["code"]}"
                  else nil
                end
    end

    # @return [LinkedIn::User]
    def user
      @user ||= (@attrs["update_type"] == "MSFC") ? LinkedIn::User.new(@attrs["update_content"]["company_person_update"]["person"]) : LinkedIn::User.new(@attrs["update_content"]["person"]) unless @attrs["update_content"].nil?
    end

    private
      def create_activities(attrs)
        person_updates = attrs["update_content"].person
        activities = []
        case attrs["update_type"]
          when "MSFC"
            company = attrs["update_content"].fetch("company")
            unless company.blank?
              activities << LinkedIn::Activity.new("name" => company.name, "url" =>  "http://linkedin.com/company/#{company.id}")
            end
          when "APPM"
            arr = []
            raw_activities = person_updates.fetch("person_activities", {"all" => []}).fetch("all")
            raw_activities.each {|activity|
              activities << LinkedIn::Activity.new("name" => activity.body)
            }
            arr
          when "QSTN"
            question = attrs["update_content"]["question"]
            activities << LinkedIn::Activity.new("name" => question.title, "url" =>  question.web_url)
          when "ANSW"
            question = attrs["update_content"]["question"]
            answers = question.fetch("answers", [])
            answers.each { |answer|
              activities << LinkedIn::Activity.new("name" => question["title"], "url" => question["web_url"], "description_url" => answer["web_url"])
            }
          when "JGRP"
            raw_groups = person_updates.fetch("member_groups", {"all" => []}).fetch("all")
            raw_groups.each { |group|
              url = group["site_group_request"].fetch("url", nil)  if group["site_group_request"]
              activities << LinkedIn::Activity.new("name" => group["name"], "url" => url)
            }
          when "CONN"
            raw_connections = person_updates.fetch("connections", {"all" => []}).fetch("all")
            raw_connections.each { |connection|
              user = LinkedIn::User.new(connection)
              activities << LinkedIn::Activity.new("name" => user.name, "url" => user.profile_url)
            }
          when "PREC"
            raw_recommendations = person_updates.fetch("recommendations_received", {"all" => []}).fetch("all")
            raw_recommendations.each {|recommendation|
              recommender = recommendation["recommender"]
              unless recommender.blank?
                user = LinkedIn::User.new(recommender)
                activities << LinkedIn::Activity.new("name" => user.name, "url" => user.profile_url)
              end
            }
          when "SVPR"
            raw_recommendations = person_updates.fetch("recommendations_given", {"all" => []}).fetch("all")
            raw_recommendations.each {|recommendation|
              recommendee = recommendation["recommendee"]
              unless recommendee.blank?
                user = LinkedIn::User.new(recommender)
                activities << LinkedIn::Activity.new("name" => user.name, "url" => user.profile_url)
              end
            }
          when "PROF"
            changed_hash = attrs.fetch("updated_fields", {"all" => []}).fetch("all").last
            unless changed_hash.blank?
              changed = changed_hash["name"]
              case changed
                when "person/skills"
                  skills = person_updates.fetch("skills", {"all" => []})
                  all_skills = skills.fetch("all")
                  all_skills.each {|skill|
                    activities << LinkedIn::Activity.new("name" => skill["skill"]["name"])
                  }
                  #post.post_type = :skill
                when "person/positions"
                  positions = person_updates.fetch("positions", {"all" => []})
                  all_positions = positions.fetch("all")
                  all_positions.each {|position|
                    company = position["company"]
                    unless company.blank?
                      activities << LinkedIn::Activity.new("name" => company.name, "url" => "http://linkedin.com/company/#{company.id}")
                      #post.post_type = :position
                    end
                  }
                when "person/organizations"
                  #post.post_type = :organization
              end
            end
        end
        activities
      end

      def guess_post_type attrs
        return attrs["update_type"].downcase.to_sym if attrs["update_type"] != "PROF"

        changed_hash = attrs.fetch("updated_fields", {"all" => []}).fetch("all").last
        unless changed_hash.blank?
          changed = changed_hash["name"]
          case changed
            when "person/skills"
              :skill
            when "person/positions"
              :position
            when "person/organizations"
              :organization
            else
              :prof
          end
        else
          :prof
        end

      end


  end
end