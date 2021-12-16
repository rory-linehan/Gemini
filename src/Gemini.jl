module Gemini

using WebSockets
using JSON
using Dates
using Base64
using Nettle
using HTTP
using StringEncodings

struct GeminiResponse
  status
  response
end

"""
Open a Websocket client to the v2/marketdata endpoint

https://docs.gemini.com/websocket-api/#market-data-version-2

# Arguments:
- `sandbox::Bool`: Sandbox request
- `channel::Channel{Dict}`: channel to pass data
- `names::Vector`: data feed name subscriptions (l2, candles_1m,...)
- `symbols::Vector`: symbol subscriptions (BTCUSD,...)
"""
function marketdata_v2(sandbox::Bool, channel::Channel{Dict}, names::Vector, symbols::Vector)::GeminiResponse
  if >(length(names), 0) && >(length(symbols), 0)
    if sandbox
      base_url = "wss://api.sandbox.gemini.com"
    else
      base_url = "wss://api.gemini.com"
    end
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
    WebSockets.open(base_url*"/v2/marketdata") do ws
      if isopen(ws)
        if writeguarded(ws, JSON.json(msg))
          while isopen(ws)
            data, success = readguarded(ws)
            if success
              put!(channel, JSON.parse(String(data))::Dict)
            end
          end
        else
          return GeminiResponse(false, Dict("error"=>"failed to send subscription information to Gemini"))
        end
      else
        return GeminiResponse(false, Dict("error"=>"failed to open websocket"))
      end
    end
  else
    return GeminiResponse(false, Dict("error"=>"no subscriptions given"))
  end
end

"""
Creates a new order

https://docs.gemini.com/rest-api/#new-order

# Arguments:
- `sandbox::Bool`: Sandbox request
- `api_key::String`: Gemini API key
- `api_secret::String`: Gemini API secret
- `side::String`: "buy" or "sell"
- `symbol::String`: The symbol for the new order
- `amount::String`: Quoted decimal amount to purchase
- `price::String`: Quoted decimal amount to spend per unit
- `type::String`: The order type. "exchange limit" for all order types except for stop-limit orders. "exchange stop limit" for stop-limit orders.
- `options::Vector{String}`:	Optional. An optional array containing at most one supported order execution option.
- `stop_price::String`: Optional. The price to trigger a stop-limit order. Only available for stop-limit orders.
"""
function new_order(sandbox::Bool, api_key::String, api_secret::String, side::String, symbol::String, amount::String, price::String, type::String, options::Vector{String}=Vector{String,1}(), stop_price::String="")
  if sandbox
    url = "https://api.sandbox.gemini.com/v1/order/new"
  else
    url = "https://api.gemini.com/v1/order/new"
  end
  payload = Dict(
    "request" => "/v1/order/new",
    "nonce" => string(Dates.datetime2epochms(Dates.now())),
    "symbol" => symbol,
    "amount" => amount,
    "price" => price,
    "side" => side,
    "type" => type,
    "options" => options,
    "stop_price" => stop_price
  )
  encoded_payload = encode(JSON.json(payload), "UTF-8")
  b64 = base64encode(encoded_payload)
  signature = hexdigest("SHA384", encode(api_secret, "UTF-8"), b64)
  request_headers = Dict(
    "Content-Type" => "text/plain",
    "Content-Length" => "0",
    "X-GEMINI-APIKEY" => api_key,
    "X-GEMINI-PAYLOAD" => b64,
    "X-GEMINI-SIGNATURE" => signature,
    "Cache-Control" => "no-cache"
  )
  try
    response = HTTP.request(
      "POST",
      url,
      request_headers,
      nothing,
      retry = false
    )
    return GeminiResponse(response.status, JSON.parse(String(response.body)))
  catch err
    if isa(err, HTTP.ExceptionRequest.StatusError)
      if ==(err.status, 503)
        return GeminiResponse(err.status, JSON.parse(String(err.response.body)))
      else
        return GeminiResponse(err.status, err.response.body)
      end
    end
  end
end

"""
Cancels an open order

https://docs.gemini.com/rest-api/#cancel-order

# Arguments:
- `sandbox::Bool`: Sandbox request
- `api_key::String`: Gemini API key
- `api_secret::String`: Gemini API secret
- `order_id::Int64`: Order id to cancel, given by new_order()
"""
function cancel_order(sandbox::Bool, api_key::String, api_secret::String, order_id::Int64)
  if sandbox
    url = "https://api.sandbox.gemini.com/v1/order/cancel"
  else
    url = "https://api.gemini.com/v1/order/cancel"
  end
  payload = Dict(
    "request" => "/v1/order/cancel",
    "nonce" => string(Dates.datetime2epochms(Dates.now())),
    "order_id" => order_id,
  )
  encoded_payload = encode(JSON.json(payload), "UTF-8")
  b64 = base64encode(encoded_payload)
  signature = hexdigest("SHA384", encode(api_secret, "UTF-8"), b64)
  request_headers = Dict(
    "Content-Type" => "text/plain",
    "Content-Length" => "0",
    "X-GEMINI-APIKEY" => api_key,
    "X-GEMINI-PAYLOAD" => b64,
    "X-GEMINI-SIGNATURE" => signature,
    "Cache-Control" => "no-cache"
  )
  try
    response = HTTP.request(
      "POST",
      url,
      request_headers,
      nothing,
      retry = false
    )
    return GeminiResponse(response.status, JSON.parse(String(response.body)))
  catch err
    if isa(err, HTTP.ExceptionRequest.StatusError)
      if ==(err.status, 503)
        return GeminiResponse(err.status, JSON.parse(String(err.response.body)))
      else
        return GeminiResponse(err.status, err.response.body)
      end
    end
  end
end

"""
This endpoint retrieves all available symbols for trading

https://docs.gemini.com/rest-api/#symbols

# Arguments:
- `sandbox::Bool`: Sandbox request
"""
function symbols(sandbox::Bool)
  if sandbox
    url = "https://api.sandbox.gemini.com/v1/symbols"
  else
    url = "https://api.gemini.com/v1/symbols"
  end
  try
    response = HTTP.request("GET", url)
    return GeminiResponse(response.status, JSON.parse(String(response.body)))
  catch err
    if isa(err, HTTP.ExceptionRequest.StatusError)
      if ==(err.status, 503)
        return GeminiResponse(err.status, JSON.parse(String(err.response.body)))
      else
        return GeminiResponse(err.status, err.response.body)
      end
    end
  end
end

"""
This endpoint retrieves extra detail on supported symbols, such as minimum order size, tick size, quote increment and more.

https://docs.gemini.com/rest-api/#symbol-details

# Arguments:
- `sandbox::Bool`: Sandbox request
- `symbol::String`: Trading pair symbol
"""
function symbol_details(sandbox::Bool, symbol::String)
  if sandbox
    url = "https://api.sandbox.gemini.com/v1/symbols/details/"
  else
    url = "https://api.gemini.com/v1/symbols/details/"
  end
  try
    response = HTTP.request("GET", url*symbol)
    return GeminiResponse(response.status, JSON.parse(String(response.body)))
  catch err
    if isa(err, HTTP.ExceptionRequest.StatusError)
      if ==(err.status, 503)
        return GeminiResponse(err.status, JSON.parse(String(err.response.body)))
      else
        return GeminiResponse(err.status, err.response.body)
      end
    end
  end
end

"""
Order events is a private API that gives you information about your orders in real time.

https://docs.gemini.com/websocket-api/#order-events

# Arguments:
- `sandbox::Bool`: Sandbox request
- `channel::Channel{Dict}`: channel to pass data
- `names::Vector`: data feed name subscriptions (l2, candles_1m,...)
- `symbols::Vector`: symbol subscriptions (BTCUSD,...)
"""
#=
function order_events(sandbox::Bool, api_key::String, api_secret::String, channel::Channel{Dict})::GeminiResponse
  if sandbox
    base_url = "wss://api.sandbox.gemini.com"
  else
    base_url = "wss://api.gemini.com"
  end
  payload = Dict(
    "request" => "/v1/order/events",
    "nonce" => string(Dates.datetime2epochms(Dates.now()))
  )
  encoded_payload = encode(JSON.json(payload), "UTF-8")
  b64 = base64encode(encoded_payload)
  signature = hexdigest("SHA384", encode(api_secret, "UTF-8"), b64)
  request_headers = Dict(
    "Content-Type" => "text/plain",
    "Content-Length" => "0",
    "X-GEMINI-APIKEY" => api_key,
    "X-GEMINI-PAYLOAD" => b64,
    "X-GEMINI-SIGNATURE" => signature,
    "Cache-Control" => "no-cache"
  )
  WebSockets.open(base_url*"/v1/order/events") do ws
    if isopen(ws)
      if writeguarded(ws, JSON.json(msg))
        while isopen(ws)
          data, success = readguarded(ws)
          if success
            put!(channel, JSON.parse(String(data))::Dict)
          end
        end
      else
        return GeminiResponse(false, Dict("error"=>"failed to send subscription information to Gemini"))
      end
    else
      return GeminiResponse(false, Dict("error"=>"failed to open websocket"))
    end
  end
end
=#

export GeminiResponse
export marketdata_v2
export new_order
export cancel_order
export symbols
export symbol_details

end # module
