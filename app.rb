require 'sinatra'
require 'base64'
require 'openssl'
require 'json'
require 'net/http'
require 'uri'

post '/callback' do
  channel_secret = ENV['CHANNEL_SECRET']
  http_request_body = request.body.read
  hash = OpenSSL::HMAC::digest(OpenSSL::Digest::SHA256.new, channel_secret, http_request_body)
  signature = Base64.strict_encode64(hash)

  x_line_channelsignature = request.env["HTTP_X_LINE_CHANNELSIGNATURE"]
  if signature == x_line_channelsignature
    puts "vaild signature"

    json = JSON.parse(http_request_body)
    json["result"].each do |result|
      content = result["content"]
      from = content["from"].to_s
      text = content["text"].to_s

      uri = URI.parse("https://trialbot-api.line.me/v1/events")
      _, username, password, host, port = ENV["FIXIE_URL"].gsub(/(:|\/|@)/,' ').squeeze(' ').split
      https = Net::HTTP.new(uri.host, uri.port, host, port, username, password)
      https.use_ssl = true
      req = Net::HTTP::Post.new(uri.path)

      req["Content-type"] = "application/json; charset=UTF-8"
      req["X-Line-ChannelID"] = ENV['CHANNEL_ID']
      req["X-Line-ChannelSecret"] = ENV['CHANNEL_SECRET']
      req["X-Line-Trusted-User-With-ACL"] = ENV["MID"]
      payload = {
        "to" => [from],
        "toChannel" => 1383378250,
        "eventType" => "138311608800106203",
        "content" => {
          "contentType": 1,
          "toType": 1,
          "text": text
        }
      }.to_json

      req.body = payload
      res = https.request(req)

      p res
    end

  else
    puts "invaild signature"
  end

  puts http_request_body
  puts x_line_channelsignature
  p request.env
  "ok"
end
