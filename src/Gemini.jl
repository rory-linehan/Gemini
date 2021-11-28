module Gemini

using WebSockets
using JSON

struct GeminiResponse
  status::Bool
  body::Dict
end

"""
Open a Websocket client to the v2/marketdata endpoint

https://docs.gemini.com/websocket-api/#market-data-version-2

# Arguments:
- `channel::Channel{Dict}`: channel to pass data
- `names::Vector`: data feed name subscriptions (l2, candles_1m,...)
- `symbols::Vector`: symbol subscriptions (BTCUSD,...)
"""
function marketdata_v2(channel::Channel{Dict}, names::Vector, symbols::Vector)
  if >(length(names), 0) && >(length(symbols), 0)
    msg = Dict(
      "type" => "subscribe",
      "subscriptions" => []
    )
    for name in names
      push!(
        msg["subscriptions"],
        Dict(
          "name" => name,
          "symbols" => symbols
        )
      )
    end
    WebSockets.open("wss://api.gemini.com/v2/marketdata") do ws
      if isopen(ws)
        if writeguarded(ws, JSON.json(msg))
          while isopen(ws)
            data, success = readguarded(ws)
            if success
              put!(channel, JSON.parse(String(data))::Dict)
            end
          end
        else
          return GeminiResponse(
            false,
            Dict(
              "error" => "failed to send subscription information to Gemini"
            )
          )
        end
      else
        return GeminiResponse(
          false,
          Dict(
            "error" => "failed to open websocket"
          )
        )
      end
    end
  else
    return GeminiResponse(
      false,
      Dict(
        "error" => "no subscriptions given"
      )
      )
  end
end

export GeminiResponse
export marketdata_v2

end # module
