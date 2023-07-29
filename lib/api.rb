class Client
  def initialize
    @url = 'https://pokeapi.co/api/v2/pokemon/25/'
  end

  def get
    res = fetch(@url).await
    obj = res.json.await
    return obj
  end
end
