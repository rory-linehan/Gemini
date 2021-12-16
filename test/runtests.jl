using Gemini
using Test

@testset "Gemini.jl" begin
  # printstyled(color=:blue, "marketdata_v2\n")
  # @testset "marketdata_v2" begin
  #   include("marketdata_v2.jl");sleep(1)
  # end
  # printstyled(color=:blue, "symbols\n")
  # @testset "symbols" begin
  #   include("symbols.jl");sleep(1)
  # end
  # manual testing for now, until I can mock up an HTTP server to return dummy requests.
  printstyled(color=:blue, "orders\n")
  @testset "orders" begin
    include("orders.jl");sleep(1)
  end
end
