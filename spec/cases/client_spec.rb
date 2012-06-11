require 'spec_helper'

describe LinkedIn::Client do
  before do
    LinkedIn.default_profile_fields = nil
    client.stub(:consumer).and_return(consumer)
    client.authorize_from_access('atoken', 'asecret')
  end

  let(:client){LinkedIn::Client.new('token', 'secret')}
  let(:consumer){OAuth::Consumer.new('token', 'secret', {:site => 'https://api.linkedin.com'})}

  describe "User's network feed" do

    it "client should get users feed" do
      stub_http_request(:get, /https:\/\/api.linkedin.com\/v1\/people\/~\/network\/updates*/).
          to_return(:body => "{}")
      posts = client.network_updates
      posts.length.should == 0
      posts.should be_an_instance_of(Array)
    end

    it "returned array should contain posts" do
      stub_http_request(:get, /https:\/\/api.linkedin.com\/v1\/people\/~\/network\/updates*/).
          to_return(:body => fixture("network_stream.json"))
      posts = client.network_updates
      posts.length.should == 12
      posts.first.should be_an_instance_of(LinkedIn::Post)
    end

  end

end