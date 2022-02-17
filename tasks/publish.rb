require 'pry'
require 'http'
require 'marcel'

class Github
  def initialize
    @api_host = 'https://api.github.com'
    @upload_host = 'https://uploads.github.com'
    @token = ENV['GITHUB_ACCESSS_TOKEN']
    @repo = 'mjason/cyber-openwrt-21.02.1'
    @client = HTTP.auth("token #{@token}")
    @api_client = @client.headers({Accept: 'application/vnd.github.v3+json'})
  end

  def create_release(tag_name:, body:)
    url = "#{@api_host}/repos/#{@repo}/releases"
    json = JSON.parse(@api_client.post(url, json: {tag_name: tag_name, body: body}).body)
    
    release_id = json['id']
    assets_url = "#{@upload_host}/repos/#{@repo}/releases/#{release_id}/assets"

    self.files.each do |entry|
      file_path = "./bin/targets/x86/64/#{entry}"
      self.upload(assets_url, file_path, entry)
    end

    self.upload(assets_url, "./.config", "./.config")
  end

  def upload(url, entry, name)
    puts "start #{entry} done"
    file = File.open(entry)
    content_type = Marcel::MimeType.for file
    @client
      .headers(content_type: content_type)
      .post(url, params: {name: name},body: file)
    puts "upload #{entry} done"
  end

  def files
    Dir.children("./bin/targets/x86/64/")
      .select {|name| name != 'packages'}
  end

end

github = Github.new
release = github.create_release(
  tag_name: "build-#{Time.now.to_i}",
  body: File.read("./changelog.md")
)