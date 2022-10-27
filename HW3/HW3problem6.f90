module sparseMatrix
    implicit none
    private
  
    type, public :: ELL_Matrix
        INTEGER(8), public :: ndof
        INTEGER(8), public :: colnummax
        INTEGER(8), ALLOCATABLE, DIMENSION(:,:) :: colidx
        INTEGER(8), ALLOCATABLE, DIMENSION(:) :: colnum
        REAL(8), ALLOCATABLE, DIMENSION(:,:) :: vals
    contains
        procedure, public :: build => build
        procedure, public :: getVal => getVal
        procedure, public :: addVal => addVal
        procedure, public :: SMVM => SMVM
    end type ELL_Matrix
contains
    subroutine build(this)
        CLASS(ELL_Matrix), intent(inout) :: this
        INTEGER(8) :: i,j
        ALLOCATE(this%vals(0:(this%ndof-1),0:this%colnummax))
        ALLOCATE(this%colidx(0:(this%ndof-1),0:this%colnummax))
        ALLOCATE(this%colnum(0:(this%ndof-1)))
        DO i=0,(this%ndof-1)
            this%colnum(i) = 0
            DO j=0,this%colnummax
                this%colidx(i,j) = -1
                this%vals(i,j) = -1000
            END DO
        END DO
    end subroutine build
    subroutine addVal(this,row,col,val)
        CLASS(ELL_Matrix), intent(inout) :: this
        INTEGER(8), INTENT(IN) :: row,col
        REAL(8), INTENT(IN) :: val
        this%vals(row,this%colnum(row)) = val
        this%colidx(row,this%colnum(row)) = col
        this%colnum(row) = this%colnum(row) + 1
    end subroutine addVal
    REAL(8) function getVal(this,row,col) result(val)
        CLASS(ELL_Matrix), intent(inout) :: this
        INTEGER(8), INTENT(IN) :: row,col
        INTEGER(8) :: j
        DO j=0,this%colnum(row)
            if (this%colidx(row,j) .eq. col) then
                val = this%vals(row,j)
                return
            end if
        end do
    end function getVal
    subroutine SMVM(this,x,out)
        CLASS(ELL_Matrix), intent(inout) :: this
        REAL(8), INTENT(IN), DIMENSION(0:(this%ndof-1)) :: x
        REAL(8), INTENT(OUT), DIMENSION(0:(this%ndof-1)) :: out
        INTEGER(8) i,j
        DO i=0,(this%ndof-1)
            out(i) = 0
            DO j=0,(this%colnum(i)-1)
                out(i) = out(i) + this%vals(i,j) * x(this%colidx(i,j))
            END DO
        END DO
    end subroutine SMVM
end module sparseMatrix
module subs
    IMPLICIT NONE
    contains
INTEGER(8) function indexer(i,j,n)
    IMPLICIT NONE
    INTEGER(8), INTENT(IN) :: i,j,n
    indexer = i*n+j
end function indexer
function deindexer(index,n)
    IMPLICIT NONE
    INTEGER(8), INTENT(IN) :: index,n
    INTEGER(8), DIMENSION(:), ALLOCATABLE :: deindexer
    ALLOCATE(deindexer(0:1));
    deindexer(1) = index/n
    deindexer(2) = MOD(index,n)

end function deindexer

REAL(8) function LaplaceEqn(u,u_0,u_1,u_2,u_3)
    IMPLICIT NONE
    REAL(8), INTENT(IN) :: u,u_0,u_1,u_2,u_3
    LaplaceEqn = (u_0+u_1+u_2+u_3-4*u)
end function LaplaceEqn

REAL(8) function updater(u,u_0,u_1,u_2,u_3)
    IMPLICIT NONE
    REAL(8), INTENT(IN) :: u,u_0,u_1,u_2,u_3
    updater = (u_0+u_1+u_2+u_3)/4.0
end function updater

REAL(8) function laplaceEval(i,j,u,n)
    IMPLICIT NONE
    REAL(8), INTENT(IN), DIMENSION(:) :: u
    INTEGER(8), INTENT(IN) :: i,j,n
    !INTEGER(8), EXTERNAL :: indexer
    !REAL(8), EXTERNAL :: LaplaceEqn
    REAL(8) :: U0,u_0,u_1,u_2,u_3
    laplaceEval = 0
    U0 = u(indexer(i,j,n))
    u_0 = 0
    u_1 = 0
    u_2 = 0
    u_3 = 0
    IF (i>0) then
        u_2 = u(indexer(i-1,j,n))
    END IF
    IF (i<(n-1)) then
        u_0 = u(indexer(i+1,j,n))
    END IF
    IF (j>0) then
        u_1 = u(indexer(i,j-1,n))
    END IF
    IF (j<(n-1)) then
        u_3 = u(indexer(i,j+1,n))
    END IF
    laplaceEval = LaplaceEqn(U0,u_0,u_1,u_2,u_3)
end function laplaceEval

REAL(8) function updaterEval(i,j,u,n)
IMPLICIT NONE
    REAL(8), INTENT(IN), DIMENSION(:) :: u
    INTEGER(8), INTENT(IN) :: i,j,n
    !INTEGER(8), EXTERNAL :: indexer
    !REAL(8), EXTERNAL :: LaplaceEqn
    REAL(8) :: U0,u_0,u_1,u_2,u_3
    updaterEval = 0
    U0 = u(indexer(i,j,n))
    u_0 = 0
    u_1 = 0
    u_2 = 0
    u_3 = 0
    IF (i>0) then
        u_2 = u(indexer(i-1,j,n))
    END IF
    IF (i<(n-1)) then
        u_0 = u(indexer(i+1,j,n))
    END IF
    IF (j>0) then
        u_1 = u(indexer(i,j-1,n))
    END IF
    IF (j<(n-1)) then
        u_3 = u(indexer(i,j+1,n))
    END IF
    updaterEval = updater(U0,u_0,u_1,u_2,u_3)
end function updaterEval
function svp(s,u,ndof)
    IMPLICIT NONE
    INTEGER(8), INTENT(IN) :: ndof
    REAL(8), INTENT(IN), DIMENSION(:) :: u(0:(ndof-1))
    REAL(8), INTENT(IN) :: s
    REAL(8), DIMENSION(0:(ndof-1)) :: svp
    INTEGER(8) :: i
    DO i=0,(ndof-1)
        svp(i) = s*u(i)
    END DO
end
REAL(8) function vvdot(u1,u2,ndof)
    IMPLICIT NONE
    INTEGER(8), INTENT(IN) :: ndof
    REAL(8), INTENT(IN), DIMENSION(:) :: u1(0:(ndof-1)),u2(0:(ndof-1))
    INTEGER(8) :: i
    vvdot = 0
    DO i=0,(ndof-1)
        vvdot = vvdot + u1(i)*u2(i)
    END DO
end
function vva(u1,u2,ndof)
    IMPLICIT NONE
    INTEGER(8), INTENT(IN) :: ndof
    REAL(8), INTENT(IN), DIMENSION(:) :: u1(0:(ndof-1)),u2(0:(ndof-1))
    REAL(8), DIMENSION(0:(ndof-1)) :: vva
    INTEGER(8) :: i
    DO i=0,(ndof-1)
        vva(i) = u1(i)+u2(i)
    END DO
end
function mvp(A,x,ndof)
    IMPLICIT NONE
    INTEGER(8), INTENT(IN) :: ndof
    REAL(8), INTENT(IN), DIMENSION(:,:) :: A(0:(ndof-1),0:(ndof-1))
    REAL(8), INTENT(IN), DIMENSION(:) :: x(0:(ndof-1))
    REAL(8), DIMENSION(0:(ndof-1)) :: mvp
    INTEGER(8) :: i,j
    DO i=0,(ndof-1)
        mvp(i) = 0
        DO j=0,(ndof-1)
            mvp(i) = mvp(i) + A(i,j) * x(j)
        END DO
    END DO
end
function residual(A,x,b,ndof)
    IMPLICIT NONE
    INTEGER(8), INTENT(IN) :: ndof
    REAL(8), INTENT(IN), DIMENSION(:,:) :: A(0:(ndof-1),0:(ndof-1))
    REAL(8), INTENT(IN), DIMENSION(:) :: x(0:(ndof-1)),b(0:(ndof-1))
    INTEGER(8) :: i,j
    REAL(8), DIMENSION(:) :: residual(0:(ndof-1))
    residual = vva(mvp(A,x,ndof),svp(DBLE(-1),b,ndof),ndof)
end
REAL(8) function L2norm(u,ndof)
    IMPLICIT NONE
    INTEGER(8), INTENT(IN) :: ndof
    REAL(8), INTENT(IN), DIMENSION(:) :: u(0:(ndof-1))
    INTEGER(8) :: i
    L2norm = 0
    DO i=0,(ndof-1)
        L2norm = L2norm + (u(i))**2
    END DO
    L2norm = DSQRT(L2norm)
end

LOGICAL function checkRes(A,x,b,tolerance,ndof)
    IMPLICIT NONE
    INTEGER(8), INTENT(IN) :: ndof
    REAL(8), INTENT(IN), DIMENSION(:,:) :: A(0:(ndof-1),0:(ndof-1))
    REAL(8), INTENT(IN), DIMENSION(:) :: x(0:(ndof-1)),b(0:(ndof-1))
    REAL(8), INTENT(IN) :: tolerance
    checkRes = (L2norm(residual(A,x,b,ndof),ndof) < tolerance)
END

REAL(8) function L2dif(u,u_prv,ndof)
IMPLICIT NONE
    REAL(8), INTENT(IN), DIMENSION(:) :: u(0:(ndof-1)),u_prv(0:(ndof-1))
    INTEGER(8), INTENT(IN) :: ndof
    INTEGER(8) :: i
    L2dif = 0
    DO i=0,(ndof-1)
        L2dif = L2dif + (u(i)-u_prv(i))**2
    END DO
    L2dif = DSQRT(L2dif)
end function L2dif

end module subs
PROGRAM HW3problem6
    
    ! Author : Dylan Lyon
    ! Title : bicgstabber
    ! Date : 10/26/2022


    ! Functions
    use subs
    use sparseMatrix

    IMPLICIT NONE

    



    ! Variable declarations
    INTEGER(8) :: i,j,k ! Indices
    INTEGER(8) :: m,n,ndof,niters ! number of rows/cols, number of u entries, iteration counter
    INTEGER(4) :: verbose ! Verbose control.
    REAL :: start, stop ! timing record
    TYPE(ELL_Matrix) :: A ! Sparse matrix
    REAL(8), ALLOCATABLE, DIMENSION(:) :: x,x_prv ! Current and previous solution to Laplace eqn
    REAL(8), ALLOCATABLE, DIMENSION(:) :: p,p_prv,r,r_prv,v,v_prv,s,t,h,b,res,dummy
    REAL(8) :: rho,rho_prv,alpha,beta,w,w_prv
    REAL(8) :: tolerance,r0,rL ! Convergence criterion
    INTEGER(8) :: nitersEstimate,max_iters ! Estimate based on spectral radius

    ! File args
    CHARACTER(2) :: solver
    INTEGER(8) :: grid_size

    ! Input buffer
    CHARACTER(100) :: buffer

    ! Matrix numbers from petsc, poisson 5 stencil
    m = 100
    n = 100

    ! Set verbose
    verbose = 1;

    ! Set tol and max iters
    tolerance = 1e-7
    max_iters = 5000

    if (verbose > 3) then
        WRITE(*,*) "Declared variables."
    end if
    
    if (verbose > 3) then
        WRITE(*,*) "Read inputs."
    end if
    
    ! Initialize and allocate
    ndof = m*n
    alpha = 1
    rho = 1
    rho_prv = 1
    w = 1
    w_prv = 1

    ! Build A
    A%colnummax = 5
    A%ndof = ndof
    call A%build()

    ALLOCATE(x(0:(ndof-1)))
    ALLOCATE(x_prv(0:(ndof-1)))
    ALLOCATE(r(0:(ndof-1)))
    ALLOCATE(r_prv(0:(ndof-1)))
    ALLOCATE(p(0:(ndof-1)))
    ALLOCATE(p_prv(0:(ndof-1)))
    ALLOCATE(v(0:(ndof-1)))
    ALLOCATE(v_prv(0:(ndof-1)))
    ALLOCATE(s(0:(ndof-1)))
    ALLOCATE(h(0:(ndof-1)))
    ALLOCATE(b(0:(ndof-1)))
    ALLOCATE(res(0:max_iters))

    DO i=0,(ndof-1)
        x(i) = 1
        x_prv(i) = 0
        r(i) = 0
        r_prv(i) = 0
        p(i) = 0
        p_prv(i) = 0
        v(i) = 0
        v_prv(i) = 0
        s(i) = 0
        h(i) = 0
        b(i) = 0
        DO j=0,(ndof-1)
            A(i,j) = 0
        END DO
    END DO
    DO i=0,m-1
        DO j=0,n-1
    	    A(indexer(i,j,n),indexer(i,j,n)) = 4;
        END DO
    END DO
    DO i=0,m-1
        DO j=1,n-1
    	    A(indexer(i,j,n),indexer(i,j-1,n)) = -1;
        END DO
    END DO
    DO i=0,m-1
        DO j=0,n-2
    	    A(indexer(i,j,n),indexer(i,j+1,n)) = -1;
        END DO
    END DO
    DO i=1,m-1
        DO j=0,n-1
    	    A(indexer(i,j,n),indexer(i-1,j,n)) = -1;
        END DO
    END DO
    DO i=0,m-2
        DO j=0,n-1
    	    A(indexer(i,j,n),indexer(i+1,j,n)) = -1;
        END DO
    END DO

    
    r = residual(A,x,b,ndof)
    res(0) = L2norm(r,ndof)
    DO i=0,(ndof-1)
        r_prv(i) = r(i)
    END DO

    niters = 1
    call cpu_time(start);
    DO WHILE(niters<max_iters)
        rho = vvdot(r,r_prv,ndof)
        beta = (rho/rho_prv)*(alpha/w_prv)
        p = vva(r_prv,svp(beta,vva(p_prv,svp(-w_prv,v_prv,ndof),ndof),ndof),ndof)
        v = mvp(A,p,ndof)
        alpha = rho/vvdot(r,v,ndof)
        h = vva(x_prv,svp(alpha,p,ndof),ndof)
        ! Check h accuracy
        if(checkRes(A,h,b,tolerance,ndof)) then
            x = svp(DBLE(1),h,ndof)
            res(niters) = L2norm(residual(A,x,b,ndof),ndof)
            exit
        end if
        s = vva(r_prv,svp(-alpha,v,ndof),ndof)
        t = mvp(A,s,ndof)
        w = vvdot(t,s,ndof)/vvdot(t,t,ndof)
        x = vva(h,svp(w,s,ndof),ndof)

        ! Check x accuracy
        res(niters) = L2norm(residual(A,x,b,ndof),ndof)
        if(checkRes(A,x,b,tolerance,ndof)) then
            exit
        end if
        r = vva(s,svp(-w,t,ndof),ndof)

        ! Update all prvs x r p v rho w
        rho_prv = rho
        w_prv = w
        DO i=0,(ndof-1)
            x_prv(i) = x(i)
            r_prv(i) = r(i)
            p_prv(i) = p(i)
            v_prv(i) = v(i)
        END DO

        niters = niters + 1
    END DO
    call cpu_time(stop);
    
    WRITE(*,*) "Iteration count: ",niters
    WRITE(*,*) "Average time per iteration (ms): ", (stop-start)/DBLE(niters)*1000
    WRITE(*,*) "Residual: ", res(niters)
    ! Write outputs!
    IF (rL/r0 < tolerance) then
        WRITE(*,*) "Converged"
        rho = tolerance**(1.0/(niters))
        nitersEstimate = FLOOR(LOG(1e-6)/LOG(rho))
        WRITE(*,'(A,F10.3)') "solve time (s): ", (stop-start)
        if (verbose>0) then
            WRITE(*,'(A,I10)') "iters: ",niters
            WRITE(*,'(A,ES10.4)') "residual: ",rL/r0
        end if
        WRITE(*,'(A,F10.4)') "Estimated spectral radius: ",rho
        if (verbose>0) then
            WRITE(*,'(A,I10)') "Iterations to reach 10^-6: ",nitersEstimate
        end if
        WRITE(*,'(A,F10.4)') "Average time per iter (ms): ",(stop-start)/(niters)*1000
    ELSE
        WRITE(*,*) "Diverged."
    END IF
    
END PROGRAM HW3problem6

