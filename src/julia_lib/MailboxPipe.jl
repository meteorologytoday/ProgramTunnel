
module MailboxPipe
using Formatting

export MailboxInfo, hello, recv, send, mkPipe, rmPipe

default_max_try = 100

mutable struct MailboxInfo

    recv_fn :: AbstractString
    send_fn :: AbstractString

    function MailboxInfo(;
        recv :: AbstractString,
        send :: AbstractString,
    )
        return new(recv, send)
    end

    function MailboxInfo(path)
        MI = new("cesm2mymodel.pipe", "mymodel2cesm.pipe")
        appendPath(MI, path)
        return MI
    end
end

function verify(MI::MailboxInfo)
    if !isfifo(MI.recv_fn) || !isfifo(MI.send_fn)
        throw(ErrorException("Either one or both of the pipe file is not a fifo file."))
    end
end

function rmPipe(MI::MailboxInfo)
    
    for fn in [MI.send_fn, MI.recv_fn]
        rm(fn, force=true)
    end

end


function mkPipe(MI::MailboxInfo)
    
    for fn in [MI.send_fn, MI.recv_fn]
        if !isfifo(fn)
            println(fn, " is not a fifo or does not exist. Remove it and create a new one.")
            rm(fn, force=true)
            run(`mkfifo $fn`)
        end
    end

end


function appendPath(MI::MailboxInfo, path::AbstractString)
    MI.recv_fn = joinpath(path, MI.recv_fn)
    MI.send_fn = joinpath(path, MI.send_fn)
end

function recv(MI::MailboxInfo)
    local result

    open(MI.recv_fn, "r") do io
        result = strip(read(io, String))
    end

    return result
end

function send(MI::MailboxInfo, msg::AbstractString)

    open(MI.send_fn, "w") do io
        write(io, msg)
    end
end



function hello(MI::MailboxInfo)
    send(MI, "<<TEST>>")
    recv_msg = recv(MI) 
    if recv_msg != "<<TEST>>"
        throw(ErrorException("Weird message: " * recv_msg))
    end
end


end
