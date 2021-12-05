@testset "marketdata_v2" begin
  channel = Channel{Dict}(5)
  println("opening socket to Gemini v2/marketdata...")
  @async marketdata_v2(
    false,
    channel,
    ["candles_1m"],
    ["BTCUSD"]
  )
  for _ in 1:5
    wait(channel)
    data = take!(channel)
    println("received data...")
  end
  close(channel)
end