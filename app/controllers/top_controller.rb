class TopController < ApplicationController
  http_basic_authenticate_with name: "mkwk", password: "Id5sH4Sj", except: :hoge
  require 'open-uri'
  require 'nokogiri'
  require 'kconv'
  require 'csv'

  def index
    @file_path = params[:file_path]
    @csv_data = read_csv(@file_path) if @file_path.present?
  end

  def create
    results = []
    url_lines = params.permit(:url_list)[:url_list]
    url_lines.each_line do | line |
      results << get_meta(line.chomp)
    end

    file_name = "/tmp/#{SecureRandom.hex(12)}.csv"
    csv_data = CSV.open(file_name, "wb") do |csv|
      csv_column_names = ["URL","TITLE","DESCRIPTION"]
      csv << csv_column_names
      results.each do | result |
        csv_column_values = [
          "#{result[:url]}",
          "#{result[:title]}",
          "#{result[:description]}",
        ]
        csv << csv_column_values
      end
    end
    redirect_to root_path(file_path: file_name)
  end

  def download
    file_path = params[:file_path]
    file_path = Rails.root.join(file_path)
    stat = File::stat(file_path)
    send_file(file_path, :length => stat.size)
  end
  private
  def get_meta(url)
    Rails.logger.info("■■■■■■■■■■before■■■■■■■■■■■")
    Rails.logger.info(url)
    Rails.logger.info("■■■■■■■■■■start■■■■■■■■■■■")
    # agent = Mechanize.new
    title = nil
    description = nil
    begin
      html = open(url, "r:binary").read
      doc = Nokogiri::HTML(html.toutf8, nil, 'utf-8')
      # doc = Nokogiri::HTML(open(url), nil, 'CP932')
      title = doc.title
      description = doc.xpath('/html/head/meta[@name="description"]/@content').to_s
    rescue Mechanize::ResponseCodeError => e
      # puts e.page.body
      title = e.to_s
      description = ""
    rescue => e
      Rails.logger.error(e.backtrace)
      title = 'error'
      description = 'error'
    end
    Rails.logger.info("■■■■■■■■■■end■■■■■■■■■■■")
    {url: url, title: title, description: description}
  end

  def read_csv(file_path)
    results = []
    CSV.foreach(file_path, headers: true) do |data|
      results << {url: data['URL'], title: data['TITLE'], description: data['DESCRIPTION']}
    end
    results
  end
end
