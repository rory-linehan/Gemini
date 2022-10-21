@testset "orders" begin
  r = new_order(
    true,
    ENV["GEMINI_API_KEY"],
    ENV["GEMINI_API_SECRET"],
    "buy",
    "btcusd",
    "1",
    "49000.00",
    "exchange limit",
    ["fill-or-kill"]
  )
  println(r)
  if ==(r.status, 200)
    if ==(r.response["is_cancelled"], false)
      order_id = parse(Int64, r.response["order_id"])
      r = cancel_order(
        true,
        ENV["GEMINI_API_KEY"],
        ENV["GEMINI_API_SECRET"],
        order_id
      )
      println(r)
      if !=(r.status, 200)
        @test false
      end
    end
  else
    @test false
  end
end