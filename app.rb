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
  url = 'https://pokeapi.co/api/v2/pokemon/25/'
  res = fetch(url).await
  obj = res.json.await
  return obj
end

content_script site: 'www.example.com' do
  chrome.runtime.onMessage.addListener do |message|
    h1 = document.querySelector('h1')
    h1.innerText = message.token
  end
end

popup do
  submit_button = document.querySelector('button#unloosen-button')
  submit_button.addEventListener "click" do |e|
    token = document.querySelector('input#token').value
    prompt = document.querySelector('textarea#prompt').value
    query_object = Utils.build_js_object(active: true, currentWindow: true)
    chrome.tabs.query(query_object) do |tabs|
      tab = tabs.at(0)
      message = Utils.build_js_object(token: token, prompt: prompt)
      chrome.tabs.sendMessage(tab[:id], message)
    end
    e.preventDefault
  end
end

background do
  console.log('OK')
  chrome.runtime.onMessage.addListener do |message|
    data = get()
    console.log(data)
  end
end

