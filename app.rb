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

popup do
  submit_button = document.querySelector('button#unloosen-button')

  chrome.runtime.onMessage.addListener do |message|
    if message.type == 'popup'
      submit_button.disabled = false
      answer_area = document.querySelector('p#answer-area')
      answer_area.innerText = message.answer
    end
  end

  submit_button.addEventListener "click" do |e|
    submit_button.disabled = true
    Fiber.new do
      key = document.querySelector('input#key').value
      prompt = document.querySelector('textarea#prompt').value
      message = Utils.build_js_object(type: 'background', key: key, input: prompt)
      answer_area = document.querySelector('p#answr-area')
      chrome.runtime.sendMessage(message)
    end.transfer
    e.preventDefault
  end
end

background do
  chrome.runtime.onMessage.addListener do |message|
    if message.type == 'background'
      Fiber.new do
        api_arg = api_args(message.key,message.input)
        res = JS.global.fetch(chat_url,api_arg).await 
        if res.status.to_i == 200
          data = res.json.await
          message = Utils.build_js_object(type: 'popup',answer: data.choices[0].message.content)
        elsif res.status.to_i == 401
          message = Utils.build_js_object(type: 'popup',answer: '提供されたAPIkeyが正しくありません')
        elsif res.status.to_i == 429
          message = Utils.build_js_object(type: 'popup',answer: 'リクエストのレート制限に達しました')
        elsif res.status.to_i == 500
          message = Utils.build_js_object(type: 'popup',answer: 'サーバーでエラーが発生しました')
        else
          message = Utils.build_js_object(type: 'popup',answer: 'apiエラー発生')
        end
        chrome.runtime.sendMessage(message)
      end.transfer
    end
  end
end

