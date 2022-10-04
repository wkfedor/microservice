require 'open-uri'
require 'nokogiri'
require 'net/https'
require 'uri'
require 'sinatra'

def mygropdata(word) # отправляю имя группы полуаю данные о ней
  p myurl = "https://t.me/#{word.delete '@'}"
  uri = URI.parse(myurl)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)
  content = response.body
  # "code=#{response.code}"
  t = {}
  if response.code == '200'
    doc = Nokogiri::HTML(content)
    t['url'] = myurl
    t['description'] = doc.xpath(".//*[@class='tgme_page_description']//text()").text # описание
    t['extra'] = doc.xpath(".//*[@class='tgme_page_extra']//text()").text # чел
    t['title'] = doc.xpath(".//*[@class='tgme_page_title']//text()").text # title
    t['error'] = response.code
    p t.inspect
    return t
  else
    p 'error'
    p response.code
    t['error'] = response.code
    p t.inspect
    return t
  end
end

def datapars(myurl)
  uri = URI.parse(myurl)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)
  content = response.body
  Nokogiri::HTML(content)
end

def datapars?(myurl) # если тру то пост не нашли
  doc = datapars myurl
  doc.xpath(".//*[@class='tgme_widget_message_error']//text()").count > 0 ? true : false
end

# поиск максимального значения с нуля
get '/group/:id/' do
  group = params[:id]
  p = mygropdata(group)
  temp = p['extra'].match(/([0-9 ]*)/)

  p['extra'] = temp[1].gsub!(/\s+/, '').to_i
  if p['extra'] == 0
    '{"data":"0", "count":"0", "work1":"0","work2":"0","flag":"-1"}'
  else
    # колличество пользователей умножаем на 50, далее в тесте на группы подберем коэфициент
    i = 10 # ограничу поиск размера группы 15 запросами
    poznow = p['extra'] * 10
    left = 0
    right = poznow
    stop = 0
    t = {}
    t['status'] = []
    t['status2'] = 0
    t['status3'] = 0
    t['messages'] = []
    t['poznow'] = []
    t['poznow'] << poznow
    t['url'] = []
    masrand = [rand(1...100), rand(100...200), rand(400...700)]
    myurllam = ->(x, y) { "https://t.me/#{x}/#{y}?embed=1" }
    while i > 0
      p myurl = "https://t.me/#{group}/#{poznow}?embed=1"
      masurl = myurllam.call(group, (poznow + masrand[2]))
      doc = datapars myurl
      if datapars?(myurl)
        unless datapars?(masurl)
          poznow += masrand[2]
          next
          # else
          # p "--------------------ERROR FIND false------start=   #{myurl}   povtor=  #{masurl}       -----------------------------------"
        end
        p t['status'] << 'нужно меньше' #  получили сообщения пост не найден
        t['status2'] += 1
        stop = poznow # позицию в значении stop не пересекаем, дальше ничего нет
        poznow = left + (right - left) / 2
        right = poznow
        t['messages'] << ''
      else
        t['messages'] << doc.xpath(".//*[@class='tgme_widget_message_text js-message_text']//text()").text
        p t['status'] << 'нужно больше'
        t['status3'] += 1
        left = poznow
        poznow = if stop <= poznow * 2 && stop != 0
                   poznow + (stop - poznow) / 2
                 else
                   poznow * 2
                 end
        right = poznow
        #  end
      end
      t['url'] << myurl
      t['poznow'] << poznow
      i -= 1
    end
    "{\"data\":\"#{left}\", \"count\":\"#{p['extra']}\", \"work1\":\"#{t['status2']}\",\"work2\":\"#{t['status3']}\"}"
  end
end

# поиск максимального значения не с нуля
get '/maxgroup/:id/:nummax/:countuser/' do
  group = params[:id]
  nummax = params[:nummax]
  countuser = params[:countuser]
  t={}
  t['messages']=[]
  # рассмотрим 2 случая, нормальный и когда данные пришли с косяком
  # http://127.0.0.1:4567/maxgroup/logistics1520com/254955/8557/            # номральный вариант    12
  # http://127.0.0.1:4567/maxgroup/logistics1520com/79833/8557/             # косячный              11
  # нужно написать алгоритм поиска последнего сообщения, когда нам известна точка старта
  # за минимальное колличество обращений к t.me
  # код необходимо написать быстро, достаточно что бы работал, разрешены допущения.
  # Math::log(x.dopmygroup.tme == 0 ? 1 : x.dopmygroup.tme).floor
  # превая проверка логорим  while i > 0 от старого значения +  старое значение   => получаем так же дату последнего сообщения
  # если меньше, то идем от последнего сообщения по порядку
  # если больше и разница в 1 день то log*2, и как было выше, но 4 попытки
  log = Math.log(nummax == 0 ? 1 : nummax.to_i).floor # логарифм от колличества сообщений переданные в урле
  poznow = nummax.to_i + log
  i = 1 # ограничу поиск размера группы 4 запросами
  while i > 0
    p myurl = "https://t.me/#{group}/#{poznow}?embed=1"
     if datapars?(myurl)
       t['messages'] << "пост не нашли"
       else
         doc = datapars myurl
         t['messages'] << doc.xpath(".//*[@class='tgme_widget_message_text js-message_text']//text()").text
     end

    i -= 1
  end

  "{\"data\":\"#{t.inspect}\", \"group\":\"#{group}\", \"nummax\":\"#{nummax}\", \"countuser\":\"#{countuser}\"}"
end
