require "base64"
require "kemal"
require "./kemal-basic-auth/*"

# This middleware adds HTTP Basic Auth support to your application.
# Returns 401 "Unauthorized" with wrong credentials.
#
# ```crystal
# basic_auth "username", "password"
# # basic_auth {"username1" => "password2", "username2" => "password2"}
# ```
#
# `HTTP::Server::Context#authorized_username` is set when the user is
# authorized.
#
class HTTPBasicAuth
  include HTTP::Handler
  BASIC                 = "Basic"
  AUTH                  = "Authorization"
  AUTH_MESSAGE          = "Could not verify your access level for that URL.\nYou have to login with proper credentials"
  HEADER_LOGIN_REQUIRED = "Basic realm=\"Login Required\""

  # a lazy singleton instance which is automatically added to handler in first access
  @@runtime : self?
  def self.runtime
    @@runtime ||= new.tap{|handler| add_handler handler}
    @@runtime.not_nil!
  end

  delegate register, credentials?, to: @credentials_holder
  
  def initialize
    @credentials_holder = CredentialsHolder.new
  end

  def call(context)
    if credentials = credentials?(context.request.path)
      username, password = extract_username_and_password(context)
      if credentials.authorize?(username, password)
        context.kemal_authorized_username = username
        call_next(context)
      else
        call_deny(context)
      end
    else
      # no needs to authorize
      call_next(context)
    end
  end

  protected def extract_username_and_password(context)
    if value = context.request.headers[AUTH]?
      if value.size > 0 && value.starts_with?(BASIC)
        return Base64.decode_string(value[BASIC.size + 1..-1]).split(":", 2)
      end
    end
    return {"", ""}
  end

  protected def call_deny(context)
    headers = HTTP::Headers.new
    context.response.status_code = 401
    context.response.headers["WWW-Authenticate"] = HEADER_LOGIN_REQUIRED
    context.response.print AUTH_MESSAGE
  end
end

# Helper to easily add HTTP Basic Auth support.
def basic_auth(username, password, only : Regex? = nil)
  HTTPBasicAuth.runtime.register(username, password, only)
end

def basic_auth(crendentials : Hash(String, String), only : Regex? = nil)
  HTTPBasicAuth.runtime.register(crendentials, only)
end
