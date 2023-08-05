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

def chat_url
  'https://api.openai.com/v1/chat/completions'
end

def api_header(apiKey)
  # header = { 'Content-Type': 'application/json', 'Authorization': "Bearer #{apiKey}"}
  js_header = Utils.build_js_object('Content-Type': 'application/json', 
                                    'Authorization': "Bearer #{apiKey}",
                                    'Access-Control-Allow-Origin': '*',
                                    'Access-Control-Allow-Headers': 'Origin, X-Requeste-With, Content-Type, Authorization, Accept')
  return js_header
end

def api_body(input)
  body = {
    messages: [
      {'role': 'user', 'content': input }
    ],
    model: 'gpt-3.5-turbo',
    max_tokens: 500,
    temperature: 1,
    n: 1,
  }
  json_body = JSON.generate(body)
  return json_body
end

def api_args(apiKey, input)
  header = api_header(apiKey)
  body = api_body(input)
  args = Utils.build_js_object(method: 'POST', headers: header, body: body)
  return args
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
      key = document.querySelector('input#key').value
      prompt = document.querySelector('textarea#prompt').value
      console.log('popup')
      query_object = Utils.build_js_object(active: true, currentWindow: true)
      chrome.tabs.query(query_object) do |tab|
        tab_id = tab[0]['id']
        message = Utils.build_js_object(key: key, input: prompt, tab_id: tab_id)
        chrome.runtime.sendMessage(message)
      end
    end.transfer
    e.preventDefault
  end
end

background do
  console.log('test')
  chrome.runtime.onMessage.addListener do |message, sender, sendResponce|
    Fiber.new do
      api_arg = api_args(message.key,message.input)
      res = JS.global.fetch(chat_url,api_arg).await 
      data = res.json.await
      console.log(data)
      chrome.tabs.sendMessage(message.tab_id.to_i, 'test')
    end.transfer
  end
end

