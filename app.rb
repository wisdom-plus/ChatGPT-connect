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
def hoge
  res = fetch('https://pokeapi.co/api/v2/pokemon/25/').await
  obj = res.json.await
  return obj
end

content_script site: 'www.example.com' do
  h1 = document.querySelector("h1")
  h1.innerText = "Hello unloosen!"
  test_object = Utils.build_js_object(memo: 'test')
  chrome.storage.local.set(test_object)
  data =hoge()
  console.log(data.name)
  chrome.runtime.onMessage.addListener do |message|
    h1 = document.querySelector('h1')
    text = window.getSelection().toString()
    chrome.storage.local.get('memo') do |obj|
      console.log(obj['memo'])
    end
    h1.innerText = text
  end
end

popup do
  submit_button = document.querySelector('button#unloosen-button')
  submit_button.addEventListener "click" do |e|
    query_object = Utils.build_js_object(active: true, currentWindow: true)
    chrome.tabs.query(query_object) do |tabs|
      tab = tabs.at(0)

      chrome.tabs.sendMessage(tab[:id], '')
    end
    e.preventDefault
  end
end

