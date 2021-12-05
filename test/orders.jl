@testset "orders" begin
  api_key = "some_api_key"
  api_secret = "corresponding_api_secret"
  response = new_order(
    true,
    api_key,
    api_secret,
    "sell",
    "btcusd",
    "1",
    "50000.00",
    "exchange limit"
  )
  println(response)
  order_id = parse(Int64, response["order_id"])
  response = cancel_order(
    true,
    api_key,
    api_secret,
    order_id
  )
  println(response)
end