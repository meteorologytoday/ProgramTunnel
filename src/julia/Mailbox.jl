
module Mailbox
using Formatting

export MailboxInfo, hello, recv, send

default_max_try = 100

mutable struct MailboxInfo

    recv_fn :: AbstractString
    send_fn :: AbstractString

    lock_fn :: AbstractString

    function MailboxInfo(;
        recv :: AbstractString,
        send :: AbstractString,
        lock :: AbstractString,
    )
        return new(recv, send, lock)
    end

    function MailboxInfo()
        return new("cesm2mymodel.info", "mymodel2cesm.info", "lock")
    end
end


function appendPath(MI::MailboxInfo, path::AbstractString)
    MI.recv_fn = joinpath(path, MI.recv_fn)
    MI.send_fn = joinpath(path, MI.send_fn)
    MI.lock_fn = joinpath(path, MI.lock_fn)
end

function lock(
    fn::Function,
    MI::MailboxInfo,
    max_try::Integer=default_max_try
)

    obtainLock(MI, max_try)
    fn()
    releaseLock(MI)
end


function obtainLock(MI::MailboxInfo, max_try::Integer)

        
    for i=1:max_try
        
        print(format("\rGetting lock... {:d}/{:d}", i, max_try))
        if ! isfile(MI.lock_fn)
            try
                open(MI.lock_fn, "w") do io
                end
                print("\r")
                break
            catch
            end
        end

        if i != max_try
            sleep(1)
        else
            throw(ErrorException(format("Cannot obtain lock: maximum try ({:d}) reached.", max_try)))
        end
    end
end

function releaseLock(MI::MailboxInfo)
    rm(MI.lock_fn, force=true)
end

function recv(MI::MailboxInfo, max_try::Integer=default_max_try)
    local result


    for i = 1:max_try
        print(format("\rDetect mail... ({:d}/{:d})", i, max_try))
        if isfile(MI.recv_fn)
            get_through = true
            print("\r")
            break
        end

        if i != max_try
            sleep(1)
        else
            throw(ErrorException(format("Error during receiving: maximum try ({:d}) reached.", max_try)))
        end
    end

    lock(MI, max_try) do
        open(MI.recv_fn, "r") do io
            result = strip(read(io, String))
        end
        rm(MI.recv_fn, force=true)
        releaseLock(MI)
    end

    return result
end

function send(MI::MailboxInfo, msg::AbstractString, max_try::Integer=default_max_try)

    print("Sending... ")
    lock(MI, max_try) do
        open(MI.send_fn, "w") do io
            write(io, msg)
        end
    end
    print("\r")
end



function hello(MI::MailboxInfo; max_try::Integer=default_max_try)
    send(MI, "<<TEST>>", max_try)
    recv_msg = recv(MI, max_try) 
    if recv_msg != "<<TEST>>"
        throw(ErrorException("Weird message: " * recv_msg))
    end
end


end
