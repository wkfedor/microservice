require 'open-uri'
require 'nokogiri'
require "net/https"
require 'uri'
require "sinatra"

def mygropdata word # отправляю имя группы полуаю данные о ней
  p myurl = "https://t.me/#{word.delete "@" }"
  uri = URI.parse(myurl)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)
  content=response.body
  #"code=#{response.code}"
  t={}
  if response.code == '200'
    doc = Nokogiri::HTML(content)
    t['url'] = myurl
    t['description'] = doc.xpath(".//*[@class='tgme_page_description']//text()").text  #описание
    t['extra'] = doc.xpath(".//*[@class='tgme_page_extra']//text()").text         #чел
    t['title'] = doc.xpath(".//*[@class='tgme_page_title']//text()").text        #title
    t['error']=response.code
    p t.inspect
    return t
  else
    p "error"
    p response.code
    t['error']=response.code
    p t.inspect
    return t
  end
end


def datapars myurl
  uri = URI.parse(myurl)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)
  content=response.body
  Nokogiri::HTML(content)
end


def datapars? myurl    # если тру то пост не нашли
  doc=datapars myurl
  doc.xpath(".//*[@class='tgme_widget_message_error']//text()").count > 0 ? true : false
end


get '/group/:id/' do
  #p "--------------------------1"
  #p params[:id]
  #p params[:splat].inspect
  #p "--------------------------2"
  #group=params[:splat].first
  group=params[:id]

  #p "--------------------------3"
  p=mygropdata(group)
  #p "--------------------------4"
  #p p.inspect
  #p "--------------------------5"
  #p=Mywork.mygropdata(group)

  temp=p['extra'].match(/([0-9 ]*)/)
  
  p['extra']=temp[1].gsub!(/\s+/, '').to_i
  # колличество пользователей умножаем на 50, далее в тесте на группы подберем коэфициент
  i=10      # ограничу поиск размера группы 15 запросами
  poznow=p['extra']*30
  left=0
  right=poznow
  stop=0
  t={}
  t['status']=[]
  t['messages']=[]
  t['poznow']=[]
  t['poznow'] << poznow
  t['url']=[]
  masrand=[rand(1...100),rand(100...200),rand(400...700)]
  myurllam = lambda{|x,y| "https://t.me/#{x}/#{y}?embed=1"}
  while  i > 0 do
    myurl = "https://t.me/#{group}/#{poznow}?embed=1"
    masurl = myurllam.call(group,(poznow+masrand[2]))
    doc=datapars myurl
    if datapars?(myurl)
      unless datapars?(masurl)
        poznow=poznow+masrand[2]
        next
        #else
        # p "--------------------ERROR FIND false------start=   #{myurl}   povtor=  #{masurl}       -----------------------------------"
      end
      t['status'] << "нужно меньше" #  получили сообщения пост не найден
      stop=poznow    # позицию в значении stop не пересекаем, дальше ничего нет
      poznow=left+(right-left)/2
      right=poznow
      t['messages'] << ""
    else
      t['messages'] << doc.xpath(".//*[@class='tgme_widget_message_text js-message_text']//text()").text
      t['status'] << "нужно больше"
      left=poznow
      if stop <= poznow*2 && stop!=0
        poznow=poznow+(stop-poznow)/2
      else
        poznow=poznow*2
      end
      right=poznow
      #  end
    end
    t['url'] << myurl
    t['poznow'] << poznow
    i-=1
  end
  #p "--------#{t.inspect}-----------"
  "{data:#{left}, test:1}"
end
