module AppleReporter
  class Reporter
    ENDPOINT = 'https://reportingitc-reporter.apple.com/reportservice'

    #
    # Usage:
    # reporter = Apple::Reporter::Sale.new(user_id: 'iscreen', password: 'secret', account: 'myAccount')
    #
    def initialize(config = {})
      @config = {
        sales_path: '/sales/v1',
        finance_path: '/finance/v1',
        mode: 'Robot.XML',
        version: '1.0',
      }.merge(config)
    end

    private

    def fetch(api_path, params)
      headers = {
        'Content-Type' => 'application/x-www-form-urlencoded'
      }
      payload = {
        userid: @config[:user_id],
        password: @config[:password],
        version: @config[:version],
        mode: @config[:mode],
        queryInput: "[p=Reporter.properties, #{params}]"
      }
      payload[:account] = @config[:account] if @config[:account]

      response = RestClient.post("#{ENDPOINT}#{api_path}", "jsonRequest=#{payload.to_json}", headers)
      handleResponse(@config[:mode], response)
    rescue RestClient::ExceptionWithResponse => err
      handleResponse(@config[:mode], err.response)
    end

    #
    def handleResponse(mode, response)
      if response.code == 200
        if response.headers[:content_type] == 'application/a-gzip'
          io = StringIO.new(response.body)
          gz = Zlib::GzipReader.new(io)
          return gz.readlines.join
        else
          return Hash.from_xml(response.body)
        end
      end

      return Hash.from_xml(response.body) if mode == 'Robot.XML'

      response.body
    end
  end
end
