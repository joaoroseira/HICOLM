module variaveis_module

  implicit none

contains

  subroutine variaveis(nstp,nat)

    implicit none

    integer i,j,k,nstp,nat,varmax

    parameter (varmax=13)

    real(8) var(varmax),sum(varmax),med(varmax),dsv(varmax)

    do i=1,varmax
       sum(i)=0.d0
    end do

    write(2,'(7x,13a12)')'#TIME',('STRESS',i=1,6),'VOLUME','TEMPERA.','PRESSURE','EKINET',&
         'ETOTAL','DENSITY'

    do i=1,nstp
       read(1,*)
       read(1,*)(var(j),j=1,6)
       read(1,*)(var(j),j=7,12)
       read(1,*)(var(j),j=13,varmax)
       do k=1,5
          read(1,*)
       end do
       do k=1,nat
          read(1,*)
          read(1,*)
          read(1,*)
       end do
       do j=1,varmax
          sum(j)=sum(j)+var(j)
       end do
       write(2,'(7x,13f12.4)')var(7),(var(j),j=1,6),(var(j),j=8,13)
    end do

    do j=1,varmax
       med(j)=sum(j)/nstp
    end do

    rewind(1)

    read(1,*)

    do j=1,varmax
       sum(j)=0.d0
    end do

    do i=1,nstp
       read(1,*)
       read(1,*)(var(j),j=1,6)
       read(1,*)(var(j),j=7,12)
       read(1,*)(var(j),j=13,varmax)
       do k=1,5
          read(1,*)
       end do
       do k=1,nat
          read(1,*)
          read(1,*)
          read(1,*)
       end do
       do j=1,varmax
          sum(j)=sum(j)+(var(j)-med(j))**2
       end do
    end do

    do j=1,varmax
       dsv(j)=sqrt(sum(j)/(nstp-1))
    end do

    write(2,*)
    write(2,'(a7,6f12.4)')'## MED1',(med(i),i=1,6)
    write(2,'(a7,6f12.4)')'## DSV1',(dsv(i),i=1,6)
    write(2,*)
    write(2,'(a7,6f12.4)')'## MED2',(med(i),i=7,12)
    write(2,'(a7,6f12.4)')'## DSV2',(dsv(i),i=7,12)
    write(2,*)
    write(2,'(a7,6f12.4)')'## MED3',(med(i),i=13,varmax)
    write(2,'(a7,6f12.4)')'## DSV3',(dsv(i),i=13,varmax)

    return

  end subroutine variaveis

end module variaveis_module

module rdf_module

  implicit none

  integer nk,nkmx,nmolec,molectt,spctot
  integer, allocatable :: idna(:),atp(:)
  integer qmolec(10),qatom(10),namoltt(10000),spcat(2)

  parameter(nkmx=1000000)

  real(8) rdfcut,drdfcut,a,b,c
  real(8), allocatable :: gr(:)
  real(8), allocatable :: v(:,:)
  real(8), allocatable :: xa(:),ya(:),za(:)

  contains

  subroutine rdf_prepare(nat,nstp)

    implicit none

    integer i,j,k,nat,nstp,nx,nxx

    allocate (xa(nat),ya(nat),za(nat))
    allocate (idna(nat),atp(nat))
    allocate (gr(nkmx))
    allocate (v(3,3))

    drdfcut=0.025d0

    write(*,*)'Types of molecules (qty):'
    read(*,*)nmolec
    write(*,*)'Number of molecules per type:'
    read(*,*)(qmolec(i),i=1,nmolec)
    write(*,*)'Number of atoms per molecule per type:'
    read(*,*)(qatom(i),i=1,nmolec)
    write(*,*)'Choose two species for the RDF calculus:'
    read(*,*)spcat(1),spcat(2)

    molectt=1
    do i=1,nmolec
       do j=1,qmolec(i)
          namoltt(molectt)=qatom(i)
          molectt=molectt+1
       end do
    end do

    molectt=molectt-1

    do k=1,nkmx
       gr(k)=0.d0
    end do

!    write(*,*)'R_cutoff','dR_cutoff'
!    read(*,*)rdfcut,drdfcut

!    nk=int(rdfcut/drdfcut)

    do i=1,nstp
       do k=1,5
          read(1,*)
       end do
       do k=1,3
          read(1,*)v(k,1),v(k,2),v(k,3)
       end do
       read(1,*)
       do k=1,nat
          read(1,*)
          read(1,*)
          read(1,*)
       end do
       if(i.eq.1)then
          a=sqrt(v(1,1)**2+v(1,2)**2+v(1,3)**2)
          b=sqrt(v(2,1)**2+v(2,2)**2+v(2,3)**2)
          c=sqrt(v(3,1)**2+v(3,2)**2+v(3,3)**2)
       else
          a=min(a,sqrt(v(1,1)**2+v(1,2)**2+v(1,3)**2))
          b=min(b,sqrt(v(2,1)**2+v(2,2)**2+v(2,3)**2))
          c=min(c,sqrt(v(3,1)**2+v(3,2)**2+v(3,3)**2))
       end if
    end do

    rdfcut=0.5d0*min(a,min(b,c))

    nk=int(rdfcut/drdfcut)

    rewind(1)

    return

  end subroutine rdf_prepare

  subroutine rdf_calc(nstp,nat)

    implicit none

    integer nstp,nat,k,i,spct(3)
    real(8) lx

    call rdf_prepare(nat,nstp)

    do i=1,nstp
       do k=1,5
          read(1,*)
       end do
       do k=1,3
          read(1,*)v(k,1),v(k,2),v(k,3)
       end do
       read(1,*)
       do k=1,nat
          read(1,*)idna(k),atp(k),lx,lx,xa(k),ya(k),za(k)
          read(1,*)
          read(1,*)
       end do
       call rdf
    end do

    do i=1,spctot
       spct(i)=0
       do k=1,nat
          if(atp(k).eq.i)spct(i)=spct(i)+1
       end do
    end do

    call rdf_final(nstp,spct)

    return

  end subroutine rdf_calc

  subroutine rdf

    implicit none

    integer i,j,k,l,ll,ii,jj,kk,nx,nxx,s,ss,g,gg
    real(8) xvz,yvz,zvz,dr,rr,sum,drr

    drr=drdfcut

    rr=0.d0
    do l=1,nk
       s=0
       do i=1,molectt
          do j=1,namoltt(i)
             nx=s+j
             ss=0
             do ii=i+1,molectt
                do jj=1,namoltt(ii)
                   nxx=ss+jj+(s+namoltt(i))
                   if(atp(nx).eq.spcat(1).and.atp(nxx).eq.spcat(2))then
                      call mic(nx,nxx,xvz,yvz,zvz)
                      dr=sqrt(xvz**2+yvz**2+zvz**2)
                      if(rr.gt.(dr-0.5d0*drr))then
                         if(rr.le.(dr+0.5d0*drr))gr(l)=gr(l)+2.d0
                      end if
                   end if
                end do
                ss=ss+namoltt(ii)
             end do
          end do
          s=s+namoltt(i)
       end do
       rr=rr+drr
    end do

    return

  end subroutine rdf

  subroutine rdf_final(nstp,spct)

    implicit none

    integer i,j,k,nstp,spct(3)
    real(8) rr,drr,vol

    write(2,'(a26,2i5)')'# RDF calculus of species:',spcat(1),spcat(2)

    drr=drdfcut

    rr=0.0d0
    do k=1,nk
       vol=4*3.14d0*((rr+0.5d0*drr)**3-(rr-0.5d0*drr)**3)/3.d0
       gr(k)=gr(k)*a*b*c/(vol*nstp*spct(spcat(1))*spct(spcat(2)))
       rr=rr+drr
    end do

    rr=0.0d0
    do k=1,nk
       write(2,*)rr,gr(k)
       rr=rr+drr
    end do

    return

  end subroutine rdf_final

  subroutine mic(i,j,xvz,yvz,zvz)
    !**************************************************************************
    !subrotina responsavel por aplicar a tecnica minimum image convention     *
    !**************************************************************************
    implicit none

    integer i,j
    real(8) xx,yy,zz,xvz,yvz,zvz

    xx=v(1,1)+v(2,1)+v(3,1)
    yy=v(1,2)+v(2,2)+v(3,2)
    zz=v(1,3)+v(2,3)+v(3,3)

    xvz=(xa(j)-xa(i))-xx*int(2.d0*(xa(j)-xa(i))/xx)
    yvz=(ya(j)-ya(i))-yy*int(2.d0*(ya(j)-ya(i))/yy)
    zvz=(za(j)-za(i))-zz*int(2.d0*(za(j)-za(i))/zz)

    return

  end subroutine mic

end module rdf_module

program tbmc

  use rdf_module
  use variaveis_module

  implicit none

  integer nstp,nvar,nat,nopt
  real(8) dtime

  open(1,file='HICOLM.md',status='old')
  open(2,file='HICOLM.dat',status='unknown')

  read(1,*)nstp,dtime,nvar,nat,spctot

  write(*,*)'RDF -> 1'
  write(*,*)'Medias -> 2'

!    nopt=2   
  read(*,*)nopt

  select case(nopt)
  case(1)
     call rdf_calc(nstp,nat)
  case(2)
     call variaveis(nstp,nat)
  end select

end program tbmc
