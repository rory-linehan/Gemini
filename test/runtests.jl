using Gemini
using Test

@testset "Gemini.jl" begin
  printstyled(color=:blue, "marketdata_v2\n")
  @testset "marketdata_v2" begin
    include("marketdata_v2.jl");sleep(1)
  end
end
