@testset "symbols" begin
  r = symbols(false)
  println(r)
  r.response::Vector{Any}
  r = symbol_details(false, r.response[begin])
  println(r)
  r.response::Dict{String, Any}
end