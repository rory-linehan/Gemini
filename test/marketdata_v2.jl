@testset "marketdata_v2" begin
    channel = Channel(5)
    println("opening socket to Gemini v2/marketdata...")
    @async marketdata_v2(channel, ["candles_1m"], ["BTCUSD"])
    for _ in 1:5
        wait(channel)
        data = take!(channel)
        println("received data...")
    end
    close(channel)
end