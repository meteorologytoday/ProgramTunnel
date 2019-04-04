module MailboxPipeMod
implicit none

type mbp_MailboxInfo
    Integer :: recv_cnt
    Integer :: send_cnt
    Integer :: recv_fd
    Integer :: send_fd
    
    character(len = 256) :: recv_fn
    character(len = 256) :: send_fn

    character(len = 256) :: log_file
end type


contains

logical function mbp_verify()
    type(mbp_MailboxInfo) :: MI
    logical               :: if_recv_fn_exists
    logical               :: if_send_fn_exists

    mbp_verify = .true.

    inquire(file=MI%recv_fn, exist=if_recv_fn_exists)
    inquire(file=MI%send_fn, exist=if_send_fn_exists)

    if ( (if_send_fn_exists .eqv. .false.).or. (if_recv_fn_exists .eqv. .false.) ) then
        mbp_verify = .false.
    end if
end function

integer function mbp_get_file_unit()
    
    integer :: lu, iostat
    logical :: opened
      
    do lu = 99, 1,-1
       inquire (unit=lu, opened=opened, iostat=iostat)
       if (iostat.ne.0) cycle
       if (.not.opened) exit
    end do
    
    mbp_get_file_unit = lu
    return
end function 

subroutine mbp_setDefault(MI)
    implicit none
    type(mbp_MailboxInfo) :: MI

    MI%recv_fn  = "mymodel2cesm.pipe"
    MI%send_fn  = "cesm2mymodel.pipe"
 
    MI%log_file = "log"

    MI%recv_cnt = 0
    MI%send_cnt = 0
 
    MI%recv_fd = mbp_get_file_unit()
    MI%send_fd = mbp_get_file_unit()
end subroutine 

subroutine mbp_appendPath(MI, path)
    implicit none
    type(mbp_MailboxInfo) :: MI
    character(len=256) :: path

    MI%recv_fn  = path // "/" // MI%recv_fn 
    MI%send_fn  = path // "/" // MI%send_fn 
    MI%log_file = path // "/" // MI%log_file

end subroutine 

subroutine mbp_delFile(fn, fd)
    implicit none
    integer :: fd
    character(len=*) :: fn
    logical :: file_exists

    inquire(file=fn, exist=file_exists)

    if (file_exists .eqv. .true.) then
        open(unit=fd, file=fn, status="old")
        close(unit=fd, status="delete")
    end if

end subroutine

subroutine mbp_clean(MI)
    implicit none
    type(mbp_MailboxInfo) :: MI

    call mbp_delFile(MI%recv_fn, MI%recv_fd)
    call mbp_delFile(MI%send_fn, MI%send_fd)
end subroutine


integer function mbp_recv(MI, msg)
    implicit none
    type(mbp_MailboxInfo)  :: MI
    character(len=*)       :: msg
    
    logical :: file_exists
    integer :: try_cnt

    mbp_recv = 0
    open(unit=MI%recv_fd, file=MI%recv_fn, form="formatted", access="stream", action="read", iostat=mbp_recv)
    if (mbp_recv /= 0) then
        print *, "ERROR OPENING PIPE STOP RECV"
        close(MI%recv_fd)
        return
    end if

    mbp_recv = 0
    read (MI%recv_fd, '(A)', iostat=mbp_recv) msg
    if (mbp_recv /= 0) then
        print *, msg
        print *, "ERROR READING PIPE STOP RECV"
        close(MI%recv_fd)
        return
    end if


    close(MI%recv_fd)
    
    msg = trim(msg)

end function


integer function mbp_send(MI, msg)
    implicit none
    type(mbp_MailboxInfo)  :: MI
    character(len=*)       :: msg

    mbp_send = 0
    open(unit=MI%send_fd, file=MI%send_fn, form="formatted", access="stream", action="write", iostat=mbp_send)
    if (mbp_send /= 0) then
        print *, "[mbp_send] Error during open."
        close(MI%send_fd)
        return
    end if

    mbp_send = 0
    write (MI%send_fd, *, iostat=mbp_send) msg
    if (mbp_send /= 0) then
        print *, "[mbp_send] Error during write."
        close(MI%send_fd)
        return
    end if
   
    close(MI%send_fd)

end function


subroutine mbp_hello(MI)
    implicit none
    type(mbp_MailboxInfo) :: MI
    character(256) :: msg

    integer :: stat

    stat = mbp_recv(MI, msg)
    if (stat /= 0) then
        print *, "Something went wrong during recv stage. Error io stat: ", stat
        return
    end if

    if (mbp_messageCompare(msg, "<<TEST>>")) then
        print *, "Recv hello!"
    else
        print *, len(msg), " : ", len("<<TEST>>")
        print *, "Weird msg: [", msg, "]"
    end if

    stat = mbp_send(MI, "<<TEST>>")
    if (stat /= 0) then
        print *, "Something went wrong during send stage. Error io stat: ", stat
        return
    end if

end subroutine

logical function mbp_messageCompare(msg1, msg2)
    implicit none
    character(*) :: msg1, msg2

    if (msg1 .eq. msg2) then
        mbp_messageCompare = .true.
    else
        mbp_messageCompare = .false.
    end if

end function


end module MailboxPipeMod
