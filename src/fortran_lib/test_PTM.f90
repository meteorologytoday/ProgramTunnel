include "ProgramTunnelMod.f90"

program test_PTM

    use ProgramTunnelMod
    implicit none
    type(ptm_TunnelSet) :: TS
    integer :: i, j
    character(256) :: recvmsg

    call ptm_setDefault(TS)
    call ptm_printSummary(TS)

    !call ptm_iterTunnel(TS, c_send_txt)
    !call ptm_iterTunnel(TS, c_send_txt)
    !call ptm_iterTunnel(TS, c_recv_txt)
    !call ptm_iterTunnel(TS, c_send_bin)
    !call ptm_iterTunnel(TS, c_send_txt)
    !call ptm_printSummary(TS) 

    i = ptm_recvText(TS, recvmsg)
    print *, i, "; ", trim(recvmsg)
 
    i = ptm_recvText(TS, recvmsg)
    print *, i, "; ", trim(recvmsg)
 
    i = ptm_recvText(TS, recvmsg)
    print *, i, "; ", trim(recvmsg)
 
    i = ptm_sendText(TS, "Hello!")
    print *, i
    i = ptm_sendText(TS, "Hello, will we connect to the same pipe?")
    print *, i
    i = ptm_sendText(TS, "Another evil test...")
    print *, i


end program
