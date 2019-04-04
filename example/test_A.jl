include("BinaryIO.jl")
include("ProgramTunnel.jl")

using Formatting
using .ProgramTunnel
TS = defaultTunnelSet(path=".")
reverseRole!(TS)

mkTunnel(TS)

data = rand(Float64, 8)
buffer = zeros(UInt8, length(data) * 8)

msg = format("{:d}", length(data))
println("Going to send: ", msg)
sendText(TS, msg)

println("Going to send: ", data)

sendBinary!(TS, data, buffer)



