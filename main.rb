require 'telegram/bot'
require 'net/http'
require 'json'
require 'httparty'
require 'nokogiri'
require 'uri'
require 'rss'
require 'google/apis/books_v1' 
require 'googleauth' 
require 'dotenv/load'
require 'goodreads'
require 'openlibrary'
require 'rest-client'
require 'json'
require 'uri'
require 'base64'
require 'google/apis/youtube_v3'
require 'date'
require 'sinatra'
require 'json'
require 'uri'
require 'net/http'
require 'cgi'
require 'rest-client'
require 'open-uri'
require 'openstreetmap'
require 'rmagick'


BIBLE_API_URL = 'https://api.scripture.api.bible/v1'
LeafletJS_URL = 'https://cdn.jsdelivr.net/npm/leaflet@1.7.1/dist/leaflet.js'
LeafletCSS_URL = 'https://cdn.jsdelivr.net/npm/leaflet@1.7.1/dist/leaflet.css'

def handle_use_scrape(bot, message)
  bot.api.send_message(chat_id: message.chat.id, text: 'Please enter the URL to scrape:')
  bot.listen do |response|
    url = response.text.strip
    webpage_content = scrape_webpage(url)
    parsed_content = parse_html(webpage_content)

    if parsed_content[:error]
      bot.api.send_message(chat_id: message.chat.id, text: "Error scraping the webpage: #{parsed_content[:error]}")
    else
      response_text = "<b>#{parsed_content[:title]}</b>\n\n#{parsed_content[:content]}"
      while response_text.length > 4096
        bot.api.send_message(chat_id: message.chat.id, text: response_text.slice!(0, 4096), parse_mode: 'HTML')
      end
      bot.api.send_message(chat_id: message.chat.id, text: response_text, parse_mode: 'HTML')
    end
  end
end

def scrape_webpage(url)
  response = RestClient.get("http://api.scraperapi.com", { params: { api_key: ENV['SCRAPERAPI_KEY'], url: url } })
  response.body
rescue RestClient::ExceptionWithResponse => e
  { error: e.response }
end

def parse_html(content)
  doc = Nokogiri::HTML(content)
  title = doc.css('title').text.strip

  main_content = ""
  main_content << "## #{title}\n\n"

  main_content << doc.css('h1, h2, h3, h4, p, ul, ol, a').map do |element|
    case element.name
    when 'h1'
      "## #{element.text.strip}"
    when 'h2'
      "### #{element.text.strip}"
    when 'h3'
      "#### #{element.text.strip}"
    when 'h4'
      "##### #{element.text.strip}"
    when 'p'
      element.text.strip
    when 'ul', 'ol'
      element.css('li').map { |li| "* #{li.text.strip}" }.join("\n")
    when 'a'
      "[#{element.text.strip}](#{element['href']})"
    else
      element.text.strip
    end
  end.join("\n\n")

  user_details = doc.css('.user-details').map(&:text).join("\n\n")
  meta_description = doc.at('meta[name="description"]')['content'] rescue nil
  meta_keywords = doc.at('meta[name="keywords"]')['content'] rescue nil

  additional_content = ""
  additional_content << "### User Details\n\n#{user_details}\n\n" unless user_details.empty?
  additional_content << "### Meta Description\n\n#{meta_description}\n\n" if meta_description
  additional_content << "### Meta Keywords\n\n#{meta_keywords}\n\n" if meta_keywords

  main_content << additional_content

  { title: title, content: main_content.strip }
end

class OpenStreetMapClient
  include HTTParty
  base_uri 'https://nominatim.openstreetmap.org'

  def search(query)
  self.class.get('/search', query: { q: query, format: 'json', addressdetails: 1, limit: 1 }, headers: { 'User-Agent' => 'YourAppName/1.0 (your-email@example.com)' })
  end
end

def handle_use_cohere(bot, message)
  require 'telegram/bot'
  require 'http'
  require 'json'
  require 'logger'

  $logger = Logger.new(STDOUT)
  $logger.level = Logger::DEBUG  
    def send_typing_action(bot, chat_id)
      bot.api.send_chat_action(chat_id: chat_id, action: 'typing')
      sleep(2)
    end

    def send_message_to_cohere(prompt)
      cohere_url = 'https://api.cohere.ai/v1/generate'
      headers = {
        'Authorization' => "Bearer #{ENV['COHERE_API_KEY']}",
        'Content-Type' => 'application/json'
      }
      payload = {
        model: 'command-xlarge-nightly',
        prompt: prompt,
        max_tokens: 2048,
        temperature: 1.0
      }

      response = HTTP.headers(headers).post(cohere_url, json: payload)
      
      if response.status.success?
        JSON.parse(response.body.to_s)
      else
        $logger.error "Cohere API request failed: #{response.status} - #{response.body}"
        nil
      end
    rescue StandardError => e
      $logger.error "Error sending message to Cohere: #{e.message}"
      nil
    end

    def parse_cohere_response(response)
      if response && response['generations'] && response['generations'].any?
        response['generations'].first['text'].strip
      else
        "Sorry, I couldn't process your request."
      end
    end

    Telegram::Bot::Client.run(ENV['TELEGRAM_BOT_TOKEN']) do |bot|
      bot.listen do |message|
        begin
          case message
          when Telegram::Bot::Types::Message
            case message.text
            when 'Ask Cohere anything'
              bot.api.send_message(chat_id: message.chat.id, text: "Hello there! 👋 I'm an advanced AI assistant powered by Cohere, Ask me anything.")
            else
              send_typing_action(bot, message.chat.id)
              bot.api.send_message(chat_id: message.chat.id, text: "One moment please, I'm processing your request... ⏳")
              send_typing_action(bot, message.chat.id)
              bot.api.send_message(chat_id: message.chat.id, text: "Be advised that responses might delay. 🕑 Please wait... ")
              send_typing_action(bot, message.chat.id)
              cohere_response = send_message_to_cohere(message.text)
              if cohere_response
                response_text = parse_cohere_response(cohere_response)
                bot.api.send_message(chat_id: message.chat.id, text: response_text)
              else
                bot.api.send_message(chat_id: message.chat.id, text: "Sorry, I couldn't get a response from Cohere.")
              end
              send_typing_action(bot, message.chat.id)
              sleep(2)
              bot.api.send_message(chat_id: message.chat.id, text: "You can type /start to start again.")
            end
          end
        rescue StandardError => e
          $logger.error "Error processing message: #{e.message}"
          bot.api.send_message(chat_id: message.chat.id, text: "Sorry, there was an error processing your request.")
        end
      end
    end
end

def handle_use_CSE(bot, message)
  require 'telegram/bot'
  require 'google/apis/customsearch_v1'
  
  $search_client = Google::Apis::CustomsearchV1::CustomSearchAPIService.new
  $search_client.key = ENV['CUSTOM_SEARCH_API_KEY']
  
  $search_active = false
  
  def send_typing_action(bot, chat_id)
    bot.api.send_chat_action(chat_id: chat_id, action: 'typing')
    sleep(2)
  end
  
  def perform_google_search(bot, message, query)
    send_typing_action(bot, message.chat.id)
  
    start_index = 1
    max_results = 15 
    results_count = 0
  
    while results_count < max_results
      results = $search_client.list_cses(q: query, cx: ENV['CUSTOM_SEARCH_CX'], num: 10, start: start_index)
      items = results.items
      break unless items
  
      items.each_with_index do |item, index|
        title = "<b>#{item.title}</b>"
        link = item.link
        snippet = item.snippet
        image_url = find_thumbnail_for_item(item)
  
        result_text = "#{results_count + 1}. #{title}\n#{snippet}\n#{link}"
  
        send_typing_action(bot, message.chat.id)
        bot.api.send_message(chat_id: message.chat.id, text: result_text, parse_mode: 'HTML')
  
        if image_url
          send_typing_action(bot, message.chat.id)
          bot.api.send_photo(chat_id: message.chat.id, photo: image_url)
        end
  
        results_count += 1
        break if results_count >= max_results
      end
  
      start_index += 10
      break if results_count >= max_results
    end
  
    bot.api.send_message(chat_id: message.chat.id, text: "No more results found for '#{query}'") if results_count == 0
    $search_active = false
  end
  
  def find_thumbnail_for_item(item)
    return unless item.pagemap && item.pagemap['cse_thumbnail']
    item.pagemap['cse_thumbnail'][0]['src']
  end
  
  Telegram::Bot::Client.run(ENV['TELEGRAM_BOT_TOKEN']) do |bot|
    bot.listen do |message|
      case message
      when Telegram::Bot::Types::Message
        case message.text
        when 'Do a Custom Search'
          $search_active = true
          send_typing_action(bot, message.chat.id)
          bot.api.send_message(chat_id: message.chat.id, text: "Please enter your search query.")
        else
          if $search_active
            search_query = message.text
            perform_google_search(bot, message, search_query)
          else
            send_typing_action(bot, message.chat.id)
            bot.api.send_message(chat_id: message.chat.id, text: "Please type 'Do a Custom Search' to start a new search session.")
          end
        end
      end
    end
  end  
end

def handle_leave_a_message(bot, message)
  whatsapp_number = 'Add Number here!'
  whatsapp_link = "https://wa.me/#{whatsapp_number}"

  bot.api.send_message(
    chat_id: message.chat.id,
    text: "Click the link below to redirect to WhatsApp \u{1F514}",
    reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup.new(
      inline_keyboard: [
        [
          Telegram::Bot::Types::InlineKeyboardButton.new(
            text: 'Go to WhatsApp',
            url: whatsapp_link
          )
        ]
      ]
    )
  )
end

def handle_use_map(bot, message)
  mapclient = OpenStreetMapClient.new
  def handle_start(bot, message)
  reply_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
  keyboard: [
    [Telegram::Bot::Types::KeyboardButton.new(text: 'Use OpenStreetMap')]
  ],
  one_time_keyboard: true
  )
  bot.api.send_message(chat_id: message.chat.id, text: "Welcome! Choose an option:", reply_markup: reply_markup)
  end

  def handle_location_search(bot, message, mapclient)
  query = message.text
  response = mapclient.search(query)
  if response.code != 200
  bot.api.send_message(chat_id: message.chat.id, text: "Sorry, there was an error processing your request.")
  return
  end

  results = response.parsed_response
  if results.empty?
  bot.api.send_message(chat_id: message.chat.id, text: "Sorry, no location found for '#{query}'.")
  else
  location = results.first
  location_name = location['display_name']
  latitude = location['lat'].to_f
  longitude = location['lon'].to_f
  address = location['address'] || {}
  road = address['road'] || 'N/A'
  city = address['city'] || address['town'] || address['village'] || 'N/A'
  state = address['state'] || 'N/A'
  country = address['country'] || 'N/A'
  postcode = address['postcode'] || 'N/A'

  output_message = "**Location found:** #{location_name}\n\n"
  output_message << "**Coordinates:**\n"
  output_message << "Lat: **#{latitude}**, Lon: **#{longitude}**\n\n"
  output_message << "**Address Details:**\n"
  output_message << "Road: **#{road}**\n"
  output_message << "City: **#{city}**\n"
  output_message << "State: **#{state}**\n"
  output_message << "Country: **#{country}**\n"
  output_message << "Postcode: **#{postcode}**\n\n"
  output_message << "[View on OpenStreetMap](https://www.openstreetmap.org/?mlat=#{latitude}&mlon=#{longitude})"

  bot.api.send_message(chat_id: message.chat.id, text: output_message, parse_mode: 'Markdown')
  end
  end

  def send_map(bot, chat_id, latitude, longitude, output_message)
  begin
  map_image = generate_map_image(latitude, longitude, output_message)
  bot.api.send_photo(chat_id: chat_id, photo: map_image)
  rescue => e
  bot.api.send_message(chat_id: chat_id, text: "Error processing image: #{e.message}")
  puts "Error processing image: #{e.message}"
  end
  end

  def generate_map_image(latitude, longitude, message)
  map_url = "https://www.openstreetmap.org/export/embed.html?bbox=#{longitude-0.05},#{latitude-0.05},#{longitude+0.05},#{latitude+0.05}&layer=mapnik"

  file = URI.open(map_url)
  image = Magick::Image.from_blob(file.read).first
  draw = Magick::Draw.new
  draw.annotate(image, 0, 0, 10, 10, message) do
    draw.gravity = Magick::SouthGravity
    draw.pointsize = 16
    draw.stroke = 'black'
    draw.fill = 'white'
    draw.font_weight = Magick::BoldWeight
  end
  image.format = 'PNG'
  image_blob = image.to_blob
  file.close if file && !file.closed?
  image_blob
  end


  def handle_message(bot, message, mapclient, session)
  case session[:step]
  when :awaiting_location
  handle_location_search(bot, message, mapclient)
  session[:step] = nil
  else
  case message.text
  when 'Use Map'
  #   handle_start(bot, message)
  # when 'Use OpenStreetMap'
    bot.api.send_message(chat_id: message.chat.id, text: "Enter a location to search on OpenStreetMap (e.g., address, landmark):")
    session[:step] = :awaiting_location
  else
    bot.api.send_message(chat_id: message.chat.id, text: "Please use /start to begin.")
  end
  end
  end
  sessions = Hash.new { |h, k| h[k] = {} }
  Telegram::Bot::Client.run(ENV['TELEGRAM_BOT_TOKEN']) do |bot|
  bot.listen do |message|
  chat_id = message.chat.id
  session = sessions[chat_id]

  case message
  when Telegram::Bot::Types::Message
    handle_message(bot, message, mapclient, session)
  end
  end
  end

end  

def handle_use_bible(bot, message)
  def send_main_menu(bot, chat_id)
      kb = [
        [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Fetch All Available Bibles', callback_data: 'fetch_bibles')],
        [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Fetch All Available Audio Bibles', callback_data: 'fetch_audio_bibles')],
        [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Fetch Books for a Specific Bible', callback_data: 'fetch_books_for_bible')],
        [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Fetch Books for a Specific Audio Bible', callback_data: 'fetch_books_for_audio_bible')],
        [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Search verses in Specific version', callback_data: 'search_verses')]
        #   [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Fetch All Passages in a Bible', callback_data: 'fetch_all_passages_for_bible')],
      #   [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Fetch Chapters in a Book', callback_data: 'fetch_chapters_in_book')]
      ]
      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
      bot.api.send_message(chat_id: chat_id, text: 'Choose an option:', reply_markup: markup)
    end
    
    def fetch_bibles
      url = "#{BIBLE_API_URL}/bibles"
      response = HTTParty.get(url, headers: { "api-key": ENV['BIBLE_API_KEY'] })
      response.code == 200 ? JSON.parse(response.body)['data'] : nil
    end  

    def fetch_search_results(bible_id, query)
      url = "#{BIBLE_API_URL}/bibles/#{bible_id}/search"
      params = { query: query }
      headers = { 'api-key' => ENV['BIBLE_API_KEY'] } 
      
      begin
        response = RestClient.get(url, headers: headers, params: params)
        handle_search_results_response(response)
      rescue RestClient::ExceptionWithResponse => e
        handle_search_results_response(e.response)
      rescue RestClient::Exception, StandardError => e
        puts "Error fetching search results: #{e.message}"
        nil
      end
    end
    
    def handle_search_results_response(response)
      case response.code
      when 200
        JSON.parse(response.body)['data']['results']
      else
        puts "Failed to fetch search results. HTTP #{response.code}: #{response.body}"
        nil
      end
    rescue JSON::ParserError => e
      puts "Error parsing JSON response: #{e.message}"
      nil
    end

    def fetch_chapters(bible_id, book_id)
      encoded_book_id = CGI.escape(book_id)
      url = "#{BIBLE_API_URL}/v1/bibles/#{bible_id}/books/#{encoded_book_id}/chapters"
      
      response = HTTParty.get(url, headers: { "api-key": ENV['BIBLE_API_KEY'] })
      
      if response.code == 200
        JSON.parse(response.body)['data']
      else
        puts "Failed to fetch chapters. HTTP #{response.code}: #{response.body}"
        nil
      end
    end
    
    def send_chapters_list(bot, chat_id, chapters, bible_id, book_id, page = 1)
      per_page = 20
      start_index = (page - 1) * per_page
      end_index = start_index + per_page - 1
      chapters_slice = chapters[start_index..end_index]
    
      if chapters_slice.nil?
        bot.api.send_message(chat_id: chat_id, text: 'Failed to fetch chapters. Please try again later.')
        return
      end
    
      response_text = "*Chapters in this Book (Page #{page}):*\n\n"
      chapters_slice.each do |chapter|
        response_text += "*#{chapter['number']}* (#{chapter['id']})\n"
      end
    
      kb = []
      kb << Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Previous', callback_data: "chapter_page_#{bible_id}_#{book_id}_#{page - 1}") if page > 1
      kb << Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Next', callback_data: "chapter_page_#{bible_id}_#{book_id}_#{page + 1}") if chapters.length > end_index + 1
    
      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb.each_slice(2).to_a)
      bot.api.send_message(chat_id: chat_id, text: response_text, parse_mode: 'Markdown', reply_markup: markup)
    end
    
    def fetch_all_passages(bible_id)
      url = "#{BIBLE_API_URL}/bibles/#{bible_id}/passages"
      response = HTTParty.get(url, headers: { "api-key": ENV['BIBLE_API_KEY'] })
      response.code == 200 ? JSON.parse(response.body)['data'] : nil
    end
    
    def fetch_audio_bible_books(audio_bible_id)
      url = "#{BIBLE_API_URL}/audio-bibles/#{audio_bible_id}/books"
      response = HTTParty.get(url, headers: { "api-key": ENV['BIBLE_API_KEY'] })
      response.code == 200 ? JSON.parse(response.body)['data'] : nil
    end
    
    def fetch_audio_bibles
      url = "#{BIBLE_API_URL}/audio-bibles"
      response = HTTParty.get(url, headers: { "api-key": ENV['BIBLE_API_KEY'] })
      response.code == 200 ? JSON.parse(response.body)['data'] : nil
    end
    
    def send_all_passages(bot, chat_id, passages, bible_id, page = 1)
      per_page = 50
      start_index = (page - 1) * per_page
      end_index = start_index + per_page - 1
      passages_slice = passages[start_index..end_index]
    
      if passages_slice.nil?
        bot.api.send_message(chat_id: chat_id, text: 'Failed to fetch passages. Please try again later.')
        return
      end
    
      response_text = "*Passages in this Bible (Page #{page}):*\n\n"
      passages_slice.each do |passage|
        response_text += "*#{passage['reference']}*\n#{passage['content']}\n\n"
      end
    
      kb = []
      kb << Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Previous', callback_data: "passage_page_#{bible_id}_#{page - 1}") if page > 1
      kb << Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Next', callback_data: "passage_page_#{bible_id}_#{page + 1}") if passages.length > end_index + 1
    
      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb.each_slice(2).to_a)
      bot.api.send_message(chat_id: chat_id, text: response_text, parse_mode: 'Markdown', reply_markup: markup)
    end
    
    def send_audio_bible_books_list(bot, chat_id, books, audio_bible_id, page = 1)
      per_page = 100
      start_index = (page - 1) * per_page
      end_index = start_index + per_page - 1
      books_slice = books[start_index..end_index]
    
      if books_slice.nil?
        bot.api.send_message(chat_id: chat_id, text: 'Failed to fetch books. Please try again later.')
        return
      end
    
      response_text = "*Books in this Audio Bible (Page #{page}):*\n\n"
      books_slice.each do |book|
        response_text += "*#{book['name']}* (#{book['id']})\n"
      end
    
      kb = []
      kb << Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Previous', callback_data: "audio_book_page_#{audio_bible_id}_#{page - 1}") if page > 1
      kb << Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Next', callback_data: "audio_book_page_#{audio_bible_id}_#{page + 1}") if books.length > end_index + 1
    
      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb.each_slice(2).to_a)
      bot.api.send_message(chat_id: chat_id, text: response_text, parse_mode: 'Markdown', reply_markup: markup)
    end
    
    def fetch_books(bible_id)
      url = "#{BIBLE_API_URL}/bibles/#{bible_id}/books"
      response = HTTParty.get(url, headers: { "api-key": ENV['BIBLE_API_KEY'] })
      response.code == 200 ? JSON.parse(response.body)['data'] : nil
    end
    
    def send_books_list(bot, chat_id, books, bible_id, page = 1)
      per_page = 100
      start_index = (page - 1) * per_page
      end_index = start_index + per_page - 1
      books_slice = books[start_index..end_index]
    
      if books_slice.nil?
        bot.api.send_message(chat_id: chat_id, text: 'Failed to fetch books. Please try again later.')
        return
      end
    
      response_text = "*Books in this Bible (Page #{page}):*\n\n"
      books_slice.each do |book|
        response_text += "*#{book['name']}* (#{book['id']})\n"
      end
    
      kb = []
      kb << Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Previous', callback_data: "book_page_#{bible_id}_#{page - 1}") if page > 1
      kb << Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Next', callback_data: "book_page_#{bible_id}_#{page + 1}") if books.length > end_index + 1
    
      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb.each_slice(2).to_a)
      bot.api.send_message(chat_id: chat_id, text: response_text, parse_mode: 'Markdown', reply_markup: markup)
    end
    
    def send_bibles_page(bot, chat_id, bibles, page)
      per_page = 20
      start_index = (page - 1) * per_page
      end_index = start_index + per_page - 1
      bibles_slice = bibles[start_index..end_index]
    
      if bibles_slice.nil?
        bot.api.send_message(chat_id: chat_id, text: 'Failed to fetch bibles. Please try again later.')
        return
      end
    
      response_text = "*Available Bibles (Page #{page}):*\n\n"
      bibles_slice.each do |bible|
        response_text += "*#{bible['name']}* (#{bible['id']})\n"
      end
    
      kb = []
      kb << Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Previous', callback_data: "page_#{page - 1}") if page > 1
      kb << Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Next', callback_data: "page_#{page + 1}") if bibles.length > end_index + 1
    
      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb.each_slice(2).to_a)
      bot.api.send_message(chat_id: chat_id, text: response_text, parse_mode: 'Markdown', reply_markup: markup)
    end
    
    def send_audio_bibles_page(bot, chat_id, audio_bibles, page)
      per_page = 20
      start_index = (page - 1) * per_page
      end_index = start_index + per_page - 1
      audio_bibles_slice = audio_bibles[start_index..end_index]
    
      if audio_bibles_slice.nil?
        bot.api.send_message(chat_id: chat_id, text: 'Failed to fetch audio bibles. Please try again later.')
        return
      end
    
      response_text = "*Available Audio Bibles (Page #{page}):*\n\n"
      audio_bibles_slice.each do |audio_bible|
        response_text += "*#{audio_bible['name']}* (#{audio_bible['id']})\n"
      end
    
      kb = []
      kb << Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Previous', callback_data: "audio_page_#{page - 1}") if page > 1
      kb << Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Next', callback_data: "audio_page_#{page + 1}") if audio_bibles.length > end_index + 1
    
      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb.each_slice(2).to_a)
      bot.api.send_message(chat_id: chat_id, text: response_text, parse_mode: 'Markdown', reply_markup: markup)
    end
    
    user_states = {}
    
    Telegram::Bot::Client.run(ENV['TELEGRAM_BOT_TOKEN']) do |bot|
      bot.listen do |message|
        case message
        when Telegram::Bot::Types::Message
          case message.text
          when 'Use Bible'
              # bot.api.send_chat_action(chat_id: message.chat.id, action: 'typing') 
              # sleep 2
              # bot.api.send_message(chat_id: message.chat.id, text: "This is an experimental project. Be advised not all features are available.")
              # sleep 2
            send_main_menu(bot, message.chat.id)
          else
            if user_states[message.chat.id] == :waiting_for_bible_id_for_passages
              bible_id = message.text.strip
              passages = fetch_all_passages(bible_id)
              if passages.nil?
                bot.api.send_message(chat_id: message.chat.id, text: 'Failed to fetch passages for this Bible. Please try again later.')
              else
                send_all_passages(bot, message.chat.id, passages, bible_id)
              end
              user_states.delete(message.chat.id)
            elsif user_states[message.chat.id] == :waiting_for_bible_id
              bible_id = message.text.strip
              books = fetch_books(bible_id)
              if books.nil?
                bot.api.send_message(chat_id: message.chat.id, text: 'Failed to fetch books for this Bible. Please try again later.')
              else
                send_books_list(bot, message.chat.id, books, bible_id)
              end
              user_states.delete(message.chat.id)
            elsif user_states[message.chat.id] == :waiting_for_audio_bible_id
              audio_bible_id = message.text.strip
              books = fetch_audio_bible_books(audio_bible_id)
              if books.nil?
                bot.api.send_message(chat_id: message.chat.id, text: 'Failed to fetch books for this Audio Bible. Please try again later.')
              else
                send_audio_bible_books_list(bot, message.chat.id, books, audio_bible_id)
              end
              user_states.delete(message.chat.id)
            elsif user_states[message.chat.id] == :waiting_for_bible_id_for_chapters
              user_states[message.chat.id] = { state: :waiting_for_book_id_for_chapters, bible_id: message.text.strip }
              bot.api.send_message(chat_id: message.chat.id, text: 'Please enter the Book ID:')
            elsif user_states[message.chat.id].is_a?(Hash) && user_states[message.chat.id][:state] == :waiting_for_book_id_for_chapters
              bible_id = user_states[message.chat.id][:bible_id]
              book_id = message.text.strip
              chapters = fetch_chapters(bible_id, book_id)
              if chapters.nil?
                bot.api.send_message(chat_id: message.chat.id, text: 'Failed to fetch chapters for this Book. Please try again later.')
              else
                send_chapters_list(bot, message.chat.id, chapters, bible_id, book_id)
              end
              user_states.delete(message.chat.id)
            elsif user_states[message.chat.id] == :waiting_for_bible_id_for_search
              bible_id = message.text.strip
              bot.api.send_message(chat_id: message.chat.id, text: 'Please enter your search query:')
              user_states[message.chat.id] = { state: :waiting_for_search_query, bible_id: bible_id }
            elsif user_states[message.chat.id].is_a?(Hash) && user_states[message.chat.id][:state] == :waiting_for_search_query
              query = message.text.strip
              bible_id = user_states[message.chat.id][:bible_id]
              results = fetch_search_results(bible_id, query)
              if results.nil?
              bot.api.send_message(chat_id: message.chat.id, text: 'Failed to fetch search results. Please try again later.')
              else
              send_search_results(bot, message.chat.id, results, bible_id, query)
              end
          end 
      end
      when Telegram::Bot::Types::CallbackQuery
        case message.data
        when 'fetch_bibles'
          bibles = fetch_bibles
          if bibles.nil?
            bot.api.send_message(chat_id: message.from.id, text: 'Failed to fetch bibles. Please try again later.')
          else
            send_bibles_page(bot, message.from.id, bibles, 1)
          end
        when /^page_(\d+)$/
          page = Regexp.last_match(1).to_i
          bibles = fetch_bibles
          send_bibles_page(bot, message.from.id, bibles, page)
        when 'fetch_audio_bibles'
          audio_bibles = fetch_audio_bibles
          if audio_bibles.nil?
            bot.api.send_message(chat_id: message.from.id, text: 'Failed to fetch audio bibles. Please try again later.')
          else
            send_audio_bibles_page(bot, message.from.id, audio_bibles, 1)
          end
        when /^audio_page_(\d+)$/
          page = Regexp.last_match(1).to_i
          audio_bibles = fetch_audio_bibles
          send_audio_bibles_page(bot, message.from.id, audio_bibles, page)
        when 'fetch_books_for_bible'
          bot.api.send_message(chat_id: message.from.id, text: 'Please enter the Bible ID:')
          user_states[message.from.id] = :waiting_for_bible_id
        when 'fetch_books_for_audio_bible'
          bot.api.send_message(chat_id: message.from.id, text: 'Please enter the Audio Bible ID:')
          user_states[message.from.id] = :waiting_for_audio_bible_id
        when 'fetch_all_passages_for_bible'
          bot.api.send_message(chat_id: message.from.id, text: 'Please enter the Bible ID:')
          user_states[message.from.id] = :waiting_for_bible_id_for_passages
        when 'fetch_chapters_in_book'
          bot.api.send_message(chat_id: message.from.id, text: 'Please enter the Bible ID:')
          user_states[message.from.id] = :waiting_for_bible_id_for_chapters
      when 'search_verses'
          bot.api.send_message(chat_id: message.from.id, text: 'Please enter the Bible ID:')
          user_states[message.from.id] = :waiting_for_bible_id_for_search      
        when /^bible_(\w+)$/
          bible_id = Regexp.last_match(1)
          books = fetch_books(bible_id)
          if books.nil?
            bot.api.send_message(chat_id: message.from.id, text: 'Failed to fetch books for this Bible. Please try again later.')
          else
            send_books_list(bot, message.from.id, books, bible_id)
          end
        when /^book_page_(\w+)_(\d+)$/
          bible_id = Regexp.last_match(1)
          page = Regexp.last_match(2).to_i
          books = fetch_books(bible_id)
          send_books_list(bot, message.from.id, books, bible_id, page)
        when /^audio_bible_(\w+)$/
          audio_bible_id = Regexp.last_match(1)
          books = fetch_audio_bible_books(audio_bible_id)
          if books.nil?
            bot.api.send_message(chat_id: message.from.id, text: 'Failed to fetch books for this Audio Bible. Please try again later.')
          else
            send_audio_bible_books_list(bot, message.from.id, books, audio_bible_id)
          end
        when /^audio_book_page_(\w+)_(\d+)$/
          audio_bible_id = Regexp.last_match(1)
          page = Regexp.last_match(2).to_i
          books = fetch_audio_bible_books(audio_bible_id)
          send_audio_bible_books_list(bot, message.from.id, books, audio_bible_id, page)
        end
    end
  end
  end
  bot.api.send_message(chat_id: message.chat.id, text: "Implementing Bible functionality...")
end

def fetch_latest_news
  rss_url = 'https://www.standardmedia.co.ke/rss/headlines.php'
  begin
    rss = RSS::Parser.parse(rss_url, false)
    if rss && rss.items.any?
      news_items = rss.items.take(5)
      news_texts = []
      
      news_items.each_with_index do |item, index|
        title = item.title
        link = item.link
        guid = item.guid.content if item.guid
        pub_date = item.pubDate.strftime("%Y-%m-%d %H:%M:%S") if item.pubDate
        description = item.description if item.description
        creator = item.dc_creator if item.dc_creator
        
        news_text = "Article #{index + 1}:\n"
        news_text += "Title: #{title}\n"
        news_text += "GUID: #{guid}\n" if guid
        news_text += "Published Date: #{pub_date}\n" if pub_date
        news_text += "Description: #{description}\n" if description
        news_text += "Link: #{link}\n"
        news_text += "Creator: #{creator}\n" if creator
        
        news_texts << news_text
      end
      
      return news_texts.join("\n\n")
    else
      return "Failed to fetch latest news from The Standard. No items found."
    end
  rescue StandardError => e
    puts "Error fetching RSS feed: #{e.message}"
    return "Failed to fetch latest news from The Standard. Please try again later."
  end
end

def fetch_latest_kenyan_news
  rss_url = 'https://www.standardmedia.co.ke/rss/kenya.php'
  begin
    rss_content = URI.open(rss_url).read
    rss = RSS::Parser.parse(rss_content, false)
    
    if rss && rss.items.any?
      news_items = rss.items.take(5)
      news_texts = []
      
      news_items.each_with_index do |item, index|
        title = item.title
        link = item.link
        guid = item.guid.content if item.guid
        pub_date = item.pubDate.strftime("%Y-%m-%d %H:%M:%S") if item.pubDate
        description = item.description if item.description
        creator = item.dc_creator if item.dc_creator
        
        news_text = "Article #{index + 1}:\n"
        news_text += "Title: #{title}\n"
        news_text += "GUID: #{guid}\n" if guid
        news_text += "Published Date: #{pub_date}\n" if pub_date
        news_text += "Description: #{description}\n" if description
        news_text += "Link: #{link}\n"
        news_text += "Creator: #{creator}\n" if creator
        
        news_texts << news_text
      end
      
      return news_texts.join("\n\n")
    else
      return "Failed to fetch latest news from The Standard. No items found."
    end
  rescue StandardError => e
    puts "Error fetching RSS feed: #{e.message}"
    return "Failed to fetch latest Kenyan news from The Standard. Please try again later."
  end
end

def fetch_latest_entertainment_news
  rss_url = 'https://www.standardmedia.co.ke/rss/entertainment.php'
  begin
    rss = RSS::Parser.parse(rss_url, false)
    if rss && rss.items.any?
      news_items = rss.items.take(5)
      news_texts = []
      
      news_items.each_with_index do |item, index|
        title = item.title
        link = item.link
        guid = item.guid.content if item.guid
        pub_date = item.pubDate.strftime("%Y-%m-%d %H:%M:%S") if item.pubDate
        description = item.description if item.description
        creator = item.dc_creator if item.dc_creator
        
        news_text = "Article #{index + 1}:\n"
        news_text += "Title: #{title}\n"
        news_text += "GUID: #{guid}\n" if guid
        news_text += "Published Date: #{pub_date}\n" if pub_date
        news_text += "Description: #{description}\n" if description
        news_text += "Link: #{link}\n"
        news_text += "Creator: #{creator}\n" if creator
        
        news_texts << news_text
      end
      
      return news_texts.join("\n\n")
    else
      return "Failed to fetch latest news from The Standard. No items found."
    end
  rescue StandardError => e
    puts "Error fetching RSS feed: #{e.message}"
    return "Failed to fetch latest Entertainment news from The Standard. Please try again later."
  end
end

class CheckOpenLibrary
  BASE_URL = 'https://openlibrary.org'.freeze
  RESULTS_LIMIT = 30

  def search_books(author_name)
    encoded_author = URI.encode_www_form_component(author_name)
    url = "#{BASE_URL}/search.json?author=#{encoded_author}&limit=#{RESULTS_LIMIT}"
    response = HTTParty.get(url)

    if response.success?
      parse_books(response)
    else
      puts "Error: #{response.code} - #{response.message}"
      []
    end
  rescue StandardError => e
    puts "Error searching Open Library: #{e.message}"
    []
  end

  private

  def parse_books(response)
    data = response.parsed_response
    if data && data['docs'].any?
      books = data['docs'].map do |book|
        {
          title: book['title'],
          author: Array(book['author_name']).join(', '),
          link: "#{BASE_URL}#{book['key']}",
          description: book['subtitle'] || 'No description available'
        }
      end
      books
    else
      puts 'No books found.'
      []
    end
  end
end

def scrape_webpage(url)
  response = RestClient.get("http://api.scraperapi.com", { params: { api_key: ENV['SCRAPERAPI_KEY'], url: url } })
  response.body
rescue RestClient::ExceptionWithResponse => e
  { error: e.response }
end

def parse_html(content)
  doc = Nokogiri::HTML(content)
  title = doc.css('title').text.strip

  main_content = ""
  main_content << "## #{title}\n\n"

  main_content << doc.css('h1, h2, h3, h4, p, ul, ol, a').map do |element|
    case element.name
    when 'h1'
      "## #{element.text.strip}"
    when 'h2'
      "### #{element.text.strip}"
    when 'h3'
      "#### #{element.text.strip}"
    when 'h4'
      "##### #{element.text.strip}"
    when 'p'
      element.text.strip
    when 'ul', 'ol'
      element.css('li').map { |li| "* #{li.text.strip}" }.join("\n")
    when 'a'
      "[#{element.text.strip}](#{element['href']})"
    else
      element.text.strip
    end
  end.join("\n\n")

  user_details = doc.css('.user-details').map(&:text).join("\n\n")
  meta_description = doc.at('meta[name="description"]')['content'] rescue nil
  meta_keywords = doc.at('meta[name="keywords"]')['content'] rescue nil

  additional_content = ""
  additional_content << "### User Details\n\n#{user_details}\n\n" unless user_details.empty?
  additional_content << "### Meta Description\n\n#{meta_description}\n\n" if meta_description
  additional_content << "### Meta Keywords\n\n#{meta_keywords}\n\n" if meta_keywords

  main_content << additional_content

  { title: title, content: main_content.strip }
end 

def get_access_token
  url = "https://open-api.tiktok.com/oauth/access_token/"
  response = HTTParty.post(url, body: {
    # Ensure you create a TikTok app here: https://open.tiktok.com/developer/apps/ which will give you a client_key and client_secret.
    client_key: 'XXXXXXXXXXXXXXXXXX',
    client_secret: 'XXXXXXXXXXXXXXXXXXXXXXXXXXX',
    grant_type: 'client_credentials'
  })
  if response.code == 200
    response.parsed_response['access_token']
  else
    raise "Failed to get access token: #{response.code} - #{response.body}"
  end
end 

def get_user_info(username)
  url = "https://open-api.tiktok.com/v1/user/@#{username}/"
  headers = {
    'Authorization' => "Bearer #{get_access_token}"
  }
  response = HTTParty.get(url, headers: headers)
  if response.code == 200
    response.parsed_response
  else
    "Failed to fetch user information: #{response.code} - #{response.body}"
  end
end

def search_videos(keyword)
  url = "https://open-api.tiktok.com/v1/challenge/search/?keyword=#{URI.encode_www_form_component(keyword)}"
  headers = {
    'Authorization' => "Bearer #{get_access_token}"
  }
  response = HTTParty.get(url, headers: headers)
  case response.code
  when 200
    response.parsed_response
  when 404
    "No videos found for keyword '#{keyword}'."
  else
    "Failed to search videos: #{response.code} - #{response.body}"
  end
end

def fetch_trending_videos
  url = "https://open-api.tiktok.com/v1/challenge/trending/?count=10"  # Adjust count as needed
  headers = {
    'Authorization' => "Bearer #{get_access_token}"
  }
  response = HTTParty.get(url, headers: headers)
  if response.code == 200
    response.parsed_response['data']
  else
    "Failed to fetch trending videos: #{response.code} - #{response.body}"
  end
end

def send_tiktok_options(bot, message)
  options = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
    keyboard: [
      [Telegram::Bot::Types::KeyboardButton.new(text: 'Find a user')],
      [Telegram::Bot::Types::KeyboardButton.new(text: 'Look up video')],
      [Telegram::Bot::Types::KeyboardButton.new(text: 'Trending topics')]
    ],
    one_time_keyboard: true
  )
  bot.api.send_message(chat_id: message.chat.id, text: 'Choose an option:', reply_markup: options)
end

#     else
#       raise "Failed to retrieve data from Anna's Archive. Status code: #{response.code}"
#     end
#   rescue StandardError => e
#     puts "Error searching Anna's Archive: #{e.message}"
#     return nil
#   end
 # Replace with your actual YouTube API key

# YOUTUBE_API_KEY = 'LuffTwaffe'
youtube_service = Google::Apis::YoutubeV3::YouTubeService.new
youtube_service.key = ENV['YOUTUBE_SERVICE_KEY']

def send_youtube_search_prompt(bot, message)
  bot.api.send_message(
    chat_id: message.chat.id,
    text: 'Enter your search query to find videos on YouTube:'
  )
end

#15 MAX RESULTS
def send_youtube_search_results(bot, chat_id, query, youtube_service)
    bot.api.send_chat_action(chat_id: chat_id, action: 'typing')
    sleep(2)

  bot.api.send_message(
    chat_id: chat_id,
    text: "Searching YouTube for '#{query}'..."
  )
  sleep(3)

  search_response = youtube_service.list_searches('snippet', q: query, type: 'video', max_results: 15)

  if search_response.items.any?
    search_response.items.each do |video|
      video_url = "https://www.youtube.com/watch?v=#{video.id.video_id}"
      published_at = DateTime.parse(video.snippet.published_at)
      # Format the message with video details and a button to watch
      message_text = "<b>#{video.snippet.title}</b>\n"
      message_text += "<b>Channel:</b> #{video.snippet.channel_title}\n"
      message_text += "<b>Published:</b> #{published_at.year}\n"

      # Send the message with the video thumbnail and a button to watch
      bot.api.send_photo(
        chat_id: chat_id,
        photo: video.snippet.thumbnails.default.url,
        caption: message_text,
        parse_mode: 'HTML',
        reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup.new(
          inline_keyboard: [
            [
              Telegram::Bot::Types::InlineKeyboardButton.new(
                text: 'Watch on YouTube',
                url: video_url
              )
            ]
          ]
        )
      )
    end
  else
    bot.api.send_message(
      chat_id: chat_id,
      text: "Oops! No videos found for '#{query}'. Try a different search. 😔"
      )
  end

  Thread.new do
    sleep 1
    bot.api.send_message(
      chat_id: chat_id,
      text: "⚠️  YouTube videos cannot be played in Telegram! 👇 Click the link below the video to watch 🎥 ."
    )
  end
end

def send_options(bot, message)
  question = 'Choose an option:'
  answers = [
    Telegram::Bot::Types::KeyboardButton.new(text: 'Latest Headlines from Standard'),
    Telegram::Bot::Types::KeyboardButton.new(text: 'Latest Kenyan News'),
    Telegram::Bot::Types::KeyboardButton.new(text: 'Latest Entertainment News'),
    Telegram::Bot::Types::KeyboardButton.new(text: 'Go to YouTube Channel'),
    Telegram::Bot::Types::KeyboardButton.new(text: 'Check Google Books for something'),
    Telegram::Bot::Types::KeyboardButton.new(text: 'Find a book @Internet Archive'),
    Telegram::Bot::Types::KeyboardButton.new(text: 'Search for Lyrics'),
    Telegram::Bot::Types::KeyboardButton.new(text: 'Search Spotify'),
    Telegram::Bot::Types::KeyboardButton.new(text: 'Leave a Message'),
    Telegram::Bot::Types::KeyboardButton.new(text: 'Go to TikTok'),
    Telegram::Bot::Types::KeyboardButton.new(text: 'Start scraping'),
    Telegram::Bot::Types::KeyboardButton.new(text: 'Do a Custom Search'),
  ]
  markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: answers, one_time_keyboard: true)
  bot.api.send_message(chat_id: message.chat.id, text: question, reply_markup: markup)
end

spotify_client_id = ENV['SPOTIFY_CLIENT_ID']
spotify_client_secret = ENV['SPOTIFY_CLIENT_SECRET']

def get_spotify_access_token(client_id, client_secret)
  auth_token = Base64.strict_encode64("#{client_id}:#{client_secret}")
  response = RestClient.post(
    'https://accounts.spotify.com/api/token',
    { grant_type: 'client_credentials' },
    { Authorization: "Basic #{auth_token}" }
  )
  JSON.parse(response.body)['access_token']
end

def search_spotify(query, access_token)
  response = RestClient.get(
    'https://api.spotify.com/v1/search',
    {
      params: {
        q: query,
        type: 'track',
        limit: 30
      },
      Authorization: "Bearer #{access_token}"
    }
  )
  tracks = JSON.parse(response.body)['tracks']['items']
  tracks.map do |track|
    {
      name: track['name'],
      artist: track['artists'].map { |artist| artist['name'] }.join(', '),
      album: track['album']['name'],
      release_date: track['album']['release_date'],
      thumbnail: track['album']['images'].first['url'],
      url: track['external_urls']['spotify']
    }
  end
end

def handle_spotify(bot, message,spotify_client_id, spotify_client_secret)
  bot.api.send_message(chat_id: message.chat.id, text: 'Please enter the song or artist name:')
      bot.listen do |response|
        query = response.text.strip
        bot.api.send_message(chat_id: message.chat.id, text: "Searching Spotify for '#{query}'...")
    
        bot.api.send_message(
          chat_id: message.chat.id,
          text: "Kindly be advised that music cannot be played in this app. Results are being fetched..."
        )
        sleep(rand(5))
        access_token = get_spotify_access_token(spotify_client_id, spotify_client_secret)
        spotify_results = search_spotify(query, access_token)
    
        if spotify_results.any?
          spotify_results.each do |track|
            inline_keyboard = Telegram::Bot::Types::InlineKeyboardMarkup.new(
              inline_keyboard: [
                [
                  Telegram::Bot::Types::InlineKeyboardButton.new(
                    text: 'Play on Spotify',
                    url: track[:url]
                  )
                ]
              ]
            )
    
            bot.api.send_photo(
              chat_id: message.chat.id,
              photo: track[:thumbnail],
              caption: "<b>#{track[:name]}</b>\n<b>Artist:</b> #{track[:artist]}\n<b>Album:</b> #{track[:album]}\n<b>Release Date:</b> #{track[:release_date]}",
              parse_mode: 'HTML',
              reply_markup: inline_keyboard
            )
          end
        else
          bot.api.send_message(chat_id: message.chat.id, text: "No results found for #{query}.")
        end
    
        break
      end
end

def handle_check_google_books(bot, message)
  bot.api.send_message(chat_id: message.chat.id, text: 'Please enter the name of the author:')
  bot.listen do |response|
    author_name = response.text.strip
    
    google_books_results = search_google_books(author_name)

    response_text = ""
    if google_books_results
      google_books_results.each_with_index do |book, index|
        response_text += "Book #{index + 1}:\n"
        response_text += "*#{book[:title]}*\n\n"
        response_text += "#{book[:description]}\n\n"
        response_text += "Find out more: #{book[:link]}\n\n"
      end
    else
      response_text = "No books found on Google Books for #{author_name}."
    end

    while response_text.length > 4096  # message limit
      bot.api.send_message(chat_id: message.chat.id, text: response_text.slice!(0, 4096))
    end  
    
    bot.api.send_message(chat_id: message.chat.id, text: response_text)
    break
  end
end

def handle_find_book_internet_archive(bot, message)
  bot.api.send_message(chat_id: message.chat.id, text: 'Please enter the name of the author:')
      bot.listen do |response|
        author_name = response.text.strip
        open_library = CheckOpenLibrary.new
        open_library_results = open_library.search_books(author_name)

        if open_library_results.any?
          open_library_results.each_with_index do |book, index|
            response_text = "<b>Book #{index + 1}:</b>\n"
            response_text += "<b>Title:</b> #{book[:title]}\n"
            response_text += "<b>Description:</b> #{book[:description]}\n"
            response_text += "<b>Link:</b> #{book[:link]}\n\n"

            while response_text.length > 0
              bot.api.send_message(chat_id: message.chat.id, text: response_text.slice!(0, 4096), parse_mode: 'HTML')
            end
          end
        else
          bot.api.send_message(chat_id: message.chat.id, text: "No books found on Open Library for #{author_name}.")
        end

        break
      end
end
def handle_use_lyrics(bot, message)
  bot.api.send_message(chat_id: message.chat.id, text: 'Please enter the artist and song title (e.g., Artist - Song):')
      bot.listen do |response|
        query = response.text.strip
        if query.include?('-')
          artist, song_title = query.split('-', 2).map(&:strip)
          song_lyrics_service = SongLyricsService.new
          lyrics = song_lyrics_service.fetch_lyrics(artist, song_title)

          if lyrics.start_with?("No lyrics found")
            bot.api.send_message(chat_id: message.chat.id, text: lyrics)
          else
            bot.api.send_message(chat_id: message.chat.id, text: "<b>#{artist} - #{song_title}</b>\n\n#{lyrics}", parse_mode: 'HTML')
          end
        else
          bot.api.send_message(chat_id: message.chat.id, text: 'Invalid format. Please use Artist - Song format.')
        end
        break
      end
end

def search_dictionary(word)
  response = RestClient.get("https://api.dictionaryapi.dev/api/v2/entries/en/#{word}")
  JSON.parse(response.body)
rescue RestClient::ExceptionWithResponse => e
  { error: e.response }
end

def format_dictionary_response(data)
  return "No definitions found." if data.is_a?(Hash) && data.key?('error')

  entry = data.first
  response_text = "Word: *#{entry['word']}*\n"
  response_text += "Phonetic: #{entry['phonetic']}\n\n"

  entry['meanings'].each do |meaning|
    response_text += "*Part of Speech: #{meaning['partOfSpeech']}*\n"
    meaning['definitions'].each_with_index do |definition, index|
      response_text += "#{index + 1}. #{definition['definition']}\n"
      response_text += "_Example: #{definition['example']}_\n" if definition['example']
      response_text += "\n"
    end
  end

  response_text
end

def handle_dictionary_search(bot, message)
  bot.api.send_message(chat_id: message.chat.id, text: 'Please enter the word you want to look up:')
  bot.listen do |response|
    word = response.text.strip
    dictionary_results = search_dictionary(word)
    response_text = format_dictionary_response(dictionary_results)

    while response_text.length > 4096 
      bot.api.send_message(chat_id: message.chat.id, text: response_text.slice!(0, 4096), parse_mode: 'Markdown')
    end  

    bot.api.send_message(chat_id: message.chat.id, text: response_text, parse_mode: 'Markdown')
    break
  end
end

def search_google_books(author_name)
    books_service = Google::Apis::BooksV1::BooksService.new
    books_service.key = ENV['GOOGLE_BOOKS_SERVICE_KEY']
  
    results = books_service.list_volumes("inauthor:#{author_name}", max_results: 5)
  
    if results.items.any?
      books = results.items.map.with_index(1) do |item, index|
        {
          title: item.volume_info.title,
          description: item.volume_info.description || "No description available",
          link: item.volume_info.info_link,
          index: index
        }
      end
      books
    else
      nil
    end
  rescue StandardError => e
    puts "Error searching Google Books: #{e.message}"
    nil
  end
  
  class SongLyricsService
    LYRICS_API_BASE_URL = 'https://api.lyrics.ovh/v1'.freeze
  
    def fetch_lyrics(artist, song_title)
      encoded_artist = URI.encode_www_form_component(artist)
      encoded_title = URI.encode_www_form_component(song_title)
      url = "#{LYRICS_API_BASE_URL}/#{encoded_artist}/#{encoded_title}"
  
      response = HTTParty.get(url)
  
      if response.success?
        response_body = JSON.parse(response.body)
        response_body['lyrics']
      else
        "No lyrics found for #{song_title} by #{artist}."
      end
    rescue StandardError => e
      puts "Error fetching lyrics: #{e.message}"
      "Failed to fetch lyrics for #{song_title} by #{artist}."
    end
  end

  def send_initial_options(bot, chat_id)
    question = 'Choose an option:'
    answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
      keyboard: [
        [
          Telegram::Bot::Types::KeyboardButton.new(text: 'Latest Headlines from Standard'),
          Telegram::Bot::Types::KeyboardButton.new(text: 'Go to YouTube Channel')
        ],
        [
          Telegram::Bot::Types::KeyboardButton.new(text: 'Latest Kenyan News'),
          Telegram::Bot::Types::KeyboardButton.new(text: 'Latest Entertainment News')
        ],
        [
          Telegram::Bot::Types::KeyboardButton.new(text: 'Check Google Books for something'),
          Telegram::Bot::Types::KeyboardButton.new(text: 'Find a book @Internet Archive')
        ],
        [
          Telegram::Bot::Types::KeyboardButton.new(text: 'Search for Lyrics'),
          Telegram::Bot::Types::KeyboardButton.new(text: 'Search Spotify')
        ],
        [
          Telegram::Bot::Types::KeyboardButton.new(text: 'Use Bible'),
          Telegram::Bot::Types::KeyboardButton.new(text: 'Use Map')
        ],
        [
          Telegram::Bot::Types::KeyboardButton.new(text: 'Go to TikTok'),
          Telegram::Bot::Types::KeyboardButton.new(text: 'Start scraping')
        ],
        [
          Telegram::Bot::Types::KeyboardButton.new(text: 'Ask Cohere anything'),
          Telegram::Bot::Types::KeyboardButton.new(text: 'Do a Custom Search')
        ],
        [   
          Telegram::Bot::Types::KeyboardButton.new(text: 'Use Dictionary'),
          Telegram::Bot::Types::KeyboardButton.new(text: 'Leave a Message')
        ]
      ],
      one_time_keyboard: true
    )
  
    bot.api.send_message(chat_id: chat_id, text: question, reply_markup: answers)
  end
  

  def handle_clear(bot, chat_id)
    send_initial_options(bot, chat_id)
  end
  
  Telegram::Bot::Client.run(ENV['TELEGRAM_BOT_TOKEN']) do |bot|
    state = {}
  
    bot.listen do |message|
      user_id = message.from.id
      state[user_id] ||= :initial
  
      case message.text
      when '/start'
        state[user_id] = :initial
        handle_clear(bot, message.chat.id)
      
      when 'clear'
        state[user_id] = :initial
        handle_clear(bot, message.chat.id)
      
      else
        case state[user_id]
        when :initial
          case message.text
          when 'Latest Headlines from Standard'
            state[user_id] = :headlines
            news = fetch_latest_news
            bot.api.send_message(chat_id: message.chat.id, text: news)
          
          when 'Use Bible'
            state[user_id] = :bible
            handle_use_bible(bot, message)
          
          when 'Use Map'
            state[user_id] = :map
            handle_use_map(bot, message)
          
          when 'Use Dictionary'
            state[user_id] = :dictionary
            handle_dictionary_search(bot, message)
          
          when 'Ask Cohere anything'
            state[user_id] = :cohere
            handle_use_cohere(bot, message)
          
          when 'Do a Custom Search'
            state[user_id] = :cse
            handle_use_CSE(bot, message)
          
          when 'Latest Kenyan News'
            state[user_id] = :kenyan_news
            news = fetch_latest_kenyan_news
            bot.api.send_message(chat_id: message.chat.id, text: news)
          
          when 'Latest Entertainment News'
            state[user_id] = :entertainment_news
            news = fetch_latest_entertainment_news
            bot.api.send_message(chat_id: message.chat.id, text: news)
          
          when 'Leave a Message'
            state[user_id] = :leave_message
            handle_leave_a_message(bot, message)
          
          when 'Start scraping'
            state[user_id] = :scrape
            handle_use_scrape(bot, message)
          
          when 'Go to YouTube Channel'
            state[user_id] = :youtube
            send_youtube_search_prompt(bot, message)
              bot.listen do |response|
                send_youtube_search_results(bot, message.chat.id, response.text, youtube_service)
              break
            end
          
          when 'Search Spotify'
            state[user_id] = :spotify
            handle_spotify(bot, message, spotify_client_id, spotify_client_secret)
          
          when 'Check Google Books for something'
            state[user_id] = :google_books
            handle_check_google_books(bot, message)
          
          when 'Find a book @Internet Archive'
            state[user_id] = :internet_archive
            handle_find_book_internet_archive(bot, message)
          
          when 'Search for Lyrics'
            state[user_id] = :lyrics
            handle_use_lyrics(bot, message)
          
          when 'Go to TikTok'
            state[user_id] = :tiktok
            send_tiktok_options(bot, message)
          
          else
            bot.api.send_message(chat_id: message.chat.id, text: "I don't understand that command.")
            send_initial_options(bot, message.chat.id)
          end
  
        when :youtube
          send_youtube_search_results(bot, message.chat.id, message.text)
          state[user_id] = :initial
        
        when :spotify
          handle_spotify(bot, message, spotify_client_id, spotify_client_secret)
          state[user_id] = :initial
  
        when :google_books
          handle_check_google_books(bot, message)
          state[user_id] = :initial
  
        when :internet_archive
          handle_find_book_internet_archive(bot, message)
          state[user_id] = :initial
  
        when :lyrics
          handle_use_lyrics(bot, message)
          state[user_id] = :initial
  
        when :tiktok
          case message.text
          when 'Find a user'
            bot.api.send_message(chat_id: message.chat.id, text: 'Enter TikTok username:')
            state[user_id] = :tiktok_find_user
  
          when 'Look up video'
            bot.api.send_message(chat_id: message.chat.id, text: 'Enter search keyword for TikTok videos:')
            state[user_id] = :tiktok_lookup_video
  
          when 'Trending topics'
            trending_videos = fetch_trending_videos
            if trending_videos.is_a?(Array) && !trending_videos.empty?
              message = "Trending TikTok Videos:\n\n"
              trending_videos.each_with_index do |video, index|
                message += "#{index + 1}. #{video['title']}\n"
                message += "#{video['video_url']}\n\n"
              end
              bot.api.send_message(chat_id: message.chat.id, text: message)
            else
              bot.api.send_message(chat_id: message.chat.id, text: "Failed to fetch trending videos.")
            end
            state[user_id] = :initial
  
          else
            bot.api.send_message(chat_id: message.chat.id, text: "I don't understand that command.")
            send_tiktok_options(bot, message)
          end
  
        when :tiktok_find_user
          username = message.text.strip
          user_info = get_user_info(username)
          bot.api.send_message(chat_id: message.chat.id, text: "User Info:\n#{user_info}")
          state[user_id] = :initial
          handle_clear(bot, message.chat.id)
  
        when :tiktok_lookup_video
          keyword = message.text.strip
          videos = search_videos(keyword)
          bot.api.send_message(chat_id: message.chat.id, text: "Search Results:\n#{videos}")
          state[user_id] = :initial
          handle_clear(bot, message.chat.id)
  
        else
          bot.api.send_message(chat_id: message.chat.id, text: "I don't understand that command.")
          send_initial_options(bot, message.chat.id)
        end
      end
    end
  end
  