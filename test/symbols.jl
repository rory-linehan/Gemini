@testset "symbols" begin
  response = symbols(false)
  response::Vector{Any}
  response = symbol_details(false, response[begin])
  response::Dict{String, Any}
end