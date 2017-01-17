class HTTPBasicAuth 
  class CredentialsHolder
    def initialize
      @mapping = Hash(Regex, Credentials).new
    end

    def register(username : String, password : String, only : Regex? = nil)
      (@mapping[only || //] ||= Credentials.new).update(username, password)
    end

    def register(other, only : Regex? = nil)
      (@mapping[only || //] ||= Credentials.new).update(other)
    end

    def credentials?(path : String) : Credentials?
      @mapping.each do |regex, credentials|
        return credentials if regex === path
      end
      return nil
    end
  end
end
