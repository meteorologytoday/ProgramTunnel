# ProgramTunnel
This is a tool to let different programs send text or binary data to each other using named pipes (FIFOs). This project is developed along sith SMARTSLAB to let fortran program (CESM) to communicate with ocean model written in Julia.


# Basic examples

## Between Matlabs

### First create fifos
```
> cd example/matlab_matlab
> ./mkTunnels.sh
```

### Screen 1 (Matlab interactive mode)

```
> % In folder example/matlab_matlab
> proc1
```

### Screen 2 (Matlab interactive mode)
```
> % In folder example/matlab_matlab
> proc2
```

## Between Fortran and Matlab

### First create fifos
```
> cd example/fortran_matlab
> ./mkTunnels.sh
```

### Screen 1 (Bash)

```
> # In folder example/fortran_matlab
> gfortran proc1.f90 -o proc1.out
> ./proc1.out
```

### Screen 2 (Matlab interactive mode)
```
> % In folder example/fortran_matlab
> proc2
```
