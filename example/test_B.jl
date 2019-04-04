include("BinaryIO.jl")
include("ProgramTunnel.jl")

using Formatting
using .ProgramTunnel
TS = defaultTunnelSet(path=".")

n = parse(Int, recvText(TS))

data = zeros(Float64, n)
buffer = zeros(UInt8, length(data) * 8)

recvBinary!(TS, data, buffer)

println("What I got here?")
println(data)


