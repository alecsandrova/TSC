::========================================================================================
call clean.bat
::========================================================================================
call build.bat
::========================================================================================
cd ../sim
:: vsim -gui -do run.do
vsim -c -do run.do