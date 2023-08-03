require 'unloosen'

class Utils
  def self.build_js_object(**kwargs)
    # This is workaround: in popup, JS.eval cannot be used.
    object = JS.global[:Object].call(:call)

    kwargs.each do |(key, value)|
      object[key] = value
    end

    object
  end
end

def get
  url = 'https://pokeapi.co/api/v2/pokemon/26/'
  Fiber.new do
    res = fetch(url).await 
    obj = res.json.await
  end.transfer
  return obj
end

def create_url(num)
  "https://pokeapi.co/api/v2/pokemon/#{num}/"
end


content_script site: 'www.example.com' do
  console.log('load')
  chrome.runtime.onMessage.addListener do |name|
    console.log('content_script')
    h1 = document.querySelector('h1')
    h1.innerText = name
  end
end

popup do
  submit_button = document.querySelector('button#unloosen-button')
  submit_button.addEventListener "click" do |e|
    Fiber.new do
      token = document.querySelector('input#token').value
      prompt = document.querySelector('textarea#prompt').value
      console.log('popup')
      query_object = Utils.build_js_object(active: true, currentWindow: true)
      chrome.tabs.query(query_object) do |tab|
        tab_id = tab[0]['id']
        message = Utils.build_js_object(message: 'pika', tab_id: tab_id, id: token)
        chrome.runtime.sendMessage(message)
      end
    end.transfer
    e.preventDefault
  end
end

background do
  console.log('test')
  chrome.runtime.onMessage.addListener do |message, sender, sendResponce|
    console.log(message)
    console.log(message.id)
    url = create_url(message.id)
    Fiber.new do
      res = fetch(url).await 
      data = res.json.await
      chrome.tabs.sendMessage(message.tab_id.to_i, data.name)
    end.transfer
  end
end

