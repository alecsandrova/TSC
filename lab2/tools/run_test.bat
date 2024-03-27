::========================================================================================
call clean.bat
::========================================================================================
call build.bat
::========================================================================================
cd ../sim
 ::vsim -gui -do run.do
::vsim -c -do run.do
::echo  %0 %1 %2 %3 %4  
::vsim -gui -do run.do %1 %2 %3 %4  
vsim -%6 -do "do run.do %1 %2 %3 %4 %5 "
::%6 c/gui 
::tema: regresie care ruleaza 9 teste nr parametului si status pass/failed
::task final report fopen -> fopm fdisplay https://www.chipverify.com/systemverilog/systemverilog-file-io

