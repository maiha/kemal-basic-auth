require "./spec_helper"

describe "HTTPBasicAuth#credentials?" do
  it "matches all paths in default" do
    handler = HTTPBasicAuth.new
    handler.register("serdar", "123")
    handler.credentials?("/").should_not be_nil
  end

  it "matches given strings" do
    handler = HTTPBasicAuth.new
    handler.register("serdar", "123", only: %r(^/foo))
    handler.credentials?("/").should be_nil
    handler.credentials?("/foo2").should_not be_nil
    handler.credentials?("/foo/").should_not be_nil
    handler.credentials?("/bar").should be_nil
  end

  it "matches given regexps" do
    handler = HTTPBasicAuth.new
    handler.register("serdar", "123", only: %r(^/my/))
    handler.register("serdar", "123", only: /secret/)
    handler.credentials?("/").should be_nil
    handler.credentials?("/my/").should_not be_nil
    handler.credentials?("/my/page").should_not be_nil
    handler.credentials?("/foo/").should be_nil
    handler.credentials?("/foo/my/").should be_nil

    handler.credentials?("/secret/").should_not be_nil
    handler.credentials?("/foo/secret/").should_not be_nil
  end
end
