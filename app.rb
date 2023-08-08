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
  Utils.build_js_object('Content-Type': 'application/json', 
                        'Authorization': "Bearer #{apiKey}",
                        'Access-Control-Allow-Origin': '*',
                        'Access-Control-Allow-Headers': 'Origin, X-Requeste-With, Content-Type, Authorization, Accept')
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
  }.to_json
end

def api_args(apiKey, input)
  header = api_header(apiKey)
  body = api_body(input)
  Utils.build_js_object(method: 'POST', headers: header, body: body)
end

content_script site: 'www.example.com' do
  console.log('load')
  chrome.runtime.onMessage.addListener do |name|
    console.log('content_script')
    message = Utils.build_js_object(type: 'popup',answer: name)
    chrome.runtime.sendMessage(message)
  end
end

popup do
  chrome.runtime.onMessage.addListener do |message|
    if message.type == 'popup'
      console.log('popup')
      answer_area = document.querySelector('p#answer-area')
      answer_area.innerText = message.answer
    end
  end
  submit_button = document.querySelector('button#unloosen-button')
  submit_button.addEventListener "click" do |e|
    Fiber.new do
      key = document.querySelector('input#key').value
      prompt = document.querySelector('textarea#prompt').value
      query_object = Utils.build_js_object(active: true, currentWindow: true)
      chrome.tabs.query(query_object) do |tab|
        tab_id = tab[0]['id']
        message = Utils.build_js_object(type: 'background', key: key, input: prompt, tab_id: tab_id)
        answer_area = document.querySelector('p#answr-area')
        chrome.runtime.sendMessage(message)
      end
    end.transfer
    e.preventDefault
  end
end

background do
  console.log('test')
  chrome.runtime.onMessage.addListener do |message|
    if message.type == 'background'
      Fiber.new do
        api_arg = api_args(message.key,message.input)
        res = JS.global.fetch(chat_url,api_arg).await 
        data = res.json.await
        chrome.tabs.sendMessage(message.tab_id.to_i, data.choices[0].message.content)
      end.transfer
    end
  end
end

