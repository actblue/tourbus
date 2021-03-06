class Webrat::Form
  def self.query_string_to_params(query_string)
    # webrat is buggy. This is to work around
    # https://webrat.lighthouseapp.com/projects/10503/tickets/401-webrat-doesnt-handle-form-fields-with-an-equals-sign
    query_string.split('&').map {|query| { query.split('=',2).first => query.split('=',2).last }}
  end
end

class Webrat::MechanizeAdapter
  # work around webrat's bugs about passing headers to mechanize
  # https://webrat.lighthouseapp.com/projects/10503/tickets/402-webrat-mechanize-doesnt-support-custom-headers#ticket-402-1
  def get(url, data, headers =  nil)
    #! Not sure what this was trying to get at, but mechanize 2.5.1 has a different api for get -- whk 20130228
    # @response = mechanize.get( { :url => url, :headers => headers }, data)
    @response = mechanize.get(url, data, nil, headers)
  end

    def post(url, data, headers = {})
      post_data = data.inject({}) do |memo, param|
        case param
        when Hash
          param.each {|attribute, value| memo[attribute] = value }
          memo
        when Array
          case param.last
          when Hash
            param.last.each {|attribute, value| memo["#{param.first}[#{attribute}]"] = value }
          else
            memo[param.first] = param.last
          end
          memo
        end
      end
      @response = mechanize.post(url, post_data, headers)
    end
end

class Webrat::Session
  #! Out of the box this sets the "HTTP_AUTHORIZATION" header, which of course appears to rails as HTTP_HTTP_AUTHORIZATION -- whk 20110316
  def basic_auth(user, pass)
    encoded_login = ["#{user}:#{pass}"].pack("m*").gsub(/\n/, '')
    header('Authorization', "Basic #{encoded_login}")
  end
end
