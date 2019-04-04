program test_str_ptr
implicit none
!character(len=16), pointer :: str_arr(:)
character(len=16) :: str_arr(10)
integer :: i
integer :: N = 10
integer, parameter:: pints(3) = (/1,2,3/)
character(len=*), parameter :: pstrs(3) = (/"abc", "def", "ghi"/)

!allocate(str_arr(N))

do i = 1, N

    write(str_arr(i), '(I5)') i 

end do

do i = 1, 3
    print *, pstrs(i)
end do

do i = 1, N

    print *, i, ":", str_arr(i), "."

end do

end program
