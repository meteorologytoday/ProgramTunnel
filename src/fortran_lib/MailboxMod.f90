module MailboxMod
implicit none

type mbm_MailboxInfo
    Integer :: recv_cnt
    Integer :: send_cnt
    Integer :: recv_fd
    Integer :: send_fd
    Integer :: lock_fd

    character(len = 256) :: recv_fn
    character(len = 256) :: send_fn

    character(len = 256) :: lock_fn

    character(len = 256) :: log_file
end type


contains

integer function mbm_get_file_unit()
    
    integer :: lu, iostat
    logical :: opened
      
    do lu = 99, 1,-1
       inquire (unit=lu, opened=opened, iostat=iostat)
       if (iostat.ne.0) cycle
       if (.not.opened) exit
    end do
    
    mbm_get_file_unit = lu
    return
end function 

subroutine mbm_setDefault(MI)
    implicit none
    type(mbm_MailboxInfo) :: MI

    MI%recv_fn  = "mymodel2cesm.info"
    MI%send_fn  = "cesm2mymodel.info"
 
    MI%lock_fn  = "lock"
   
    MI%log_file = "log"

    MI%recv_cnt = 0
    MI%send_cnt = 0
 
    MI%recv_fd = mbm_get_file_unit()
    MI%send_fd = mbm_get_file_unit()
    MI%lock_fd = mbm_get_file_unit()
end subroutine 

subroutine mbm_appendPath(MI, path)
    implicit none
    type(mbm_MailboxInfo) :: MI
    character(len=256) :: path

    MI%recv_fn  = path // "/" // MI%recv_fn 
    MI%send_fn  = path // "/" // MI%send_fn 
    MI%lock_fn  = path // "/" // MI%lock_fn
    MI%log_file = path // "/" // MI%log_file

end subroutine 

subroutine mbm_obtainLock(MI, max_try, stat)
    type(mbm_MailboxInfo) :: MI
    integer               :: max_try, stat

    logical :: file_exists
    integer :: io

    logical :: get_through
    integer :: try_cnt

    get_through = .false.
    do try_cnt = 1, max_try
        ! try to get lock
        inquire(file=MI%lock_fn, exist=file_exists)
        
        if (file_exists .eqv. .true.) then
            call sleep(1)
            cycle
        end if
       
        ! Try to create a file 
        io = 0
        open(unit=MI%lock_fd, file=MI%lock_fn, form="formatted", access="stream", action="write", iostat=io)
        close(MI%lock_fd)


        if (io == 0) then
            ! If we did open a file then leave
            get_through = .true.        
            exit
        else
            ! But if open file fails then try again
            call sleep(1)
            cycle
        end if
    end do 

    if (get_through .eqv. .true.) then
        stat = 0
    else
        stat = 1
    end if

end subroutine

subroutine mbm_releaseLock(MI)
    type(mbm_MailboxInfo) :: MI
    call mbm_delFile(MI%lock_fn, MI%lock_fd)
end subroutine

subroutine mbm_delFile(fn, fd)
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

subroutine mbm_clean(MI)
    implicit none
    type(mbm_MailboxInfo) :: MI

    call mbm_delFile(MI%recv_fn, MI%recv_fd)
    call mbm_delFile(MI%send_fn, MI%send_fd)
end subroutine


subroutine mbm_recv(MI, msg, max_try, stat)
    implicit none
    type(mbm_MailboxInfo)  :: MI
    character(len=*)       :: msg
    integer                :: max_try
    integer, intent(inout) :: stat

    integer :: io
    logical :: file_exists
    integer :: try_cnt

    logical :: get_through

    get_through = .false.
    do try_cnt = 1, max_try
        inquire(file=MI%recv_fn, exist=file_exists)
        if (file_exists .eqv. .true.) then
            get_through = .true.
            exit
        else
            call sleep(1)
            cycle
        end if
    end do

    if (get_through .eqv. .true.) then
        stat = 0
    else
        stat = 1
        return
    end if

    call mbm_obtainLock(MI, max_try, stat)
    if (stat /= 0 ) then
        return
    end if
    
    io = 0
    open(unit=MI%recv_fd, file=MI%recv_fn, form="formatted", access="stream", action="read", iostat=io)
    
    read (MI%recv_fd, '(A)', iostat=io) msg
    close(MI%recv_fd)
    
    msg = trim(msg)

    call mbm_delFile(MI%recv_fn, MI%recv_fd)

    call mbm_releaseLock(MI)
    
end subroutine


subroutine mbm_send(MI, msg, max_try, stat)
    implicit none
    type(mbm_MailboxInfo)  :: MI
    character(len=*)       :: msg
    integer                :: max_try
    integer, intent(inout) :: stat


    integer :: io
    
    call mbm_obtainLock(MI, max_try, stat)
    if (stat /= 0 ) then
        return
    end if

    !print *, "Lock get" 
    io = 0
    open(unit=MI%send_fd, file=MI%send_fn, form="formatted", access="stream", action="write", iostat=io)
    if (io /= 0) then
        print *, "Create send file iostat: ", io
    end if

    io = 0
    write (MI%send_fd, *, iostat=io) msg
    if (io /= 0) then
        print *, "Output send file iostat: ", io
    end if
    
    close(MI%send_fd)
    call mbm_releaseLock(MI)

end subroutine


subroutine mbm_hello(MI, max_try)
    implicit none
    type(mbm_MailboxInfo) :: MI
    character(256) :: msg
    integer :: max_try

    integer :: stat

    print *, "Max try: ", max_try

    call mbm_recv(MI, msg, max_try, stat)
    if (stat /= 0) then
        print *, "Something went wrong during recv stage... exit"
        return
    end if

    if (mbm_messageCompare(msg, "<<TEST>>")) then
        print *, "Recv hello!"
    else
        print *, len(msg), " : ", len("<<TEST>>")
        print *, "Weird msg: [", msg, "]"
    end if

    call mbm_send(MI, "<<TEST>>", max_try, stat)
    if (stat /= 0) then
        print *, "Something went wrong during send stage... exit"
        return
    end if


end subroutine

logical function mbm_messageCompare(msg1, msg2)
    implicit none
    character(*) :: msg1, msg2

    if (msg1 .eq. msg2) then
        mbm_messageCompare = .true.
    else
        mbm_messageCompare = .false.
    end if

end function


end module MailboxMod
