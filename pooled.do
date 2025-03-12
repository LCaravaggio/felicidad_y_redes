* Felicidad IVQREG
* INICIO
clear all
cscript

* qui do ivqreg.mata

set more off
set seed 12345

cd C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\
use "2020 mergeada"
append using "2023 mergeada"

ivreg2 sat edad capital (SNU=internet) , robust first

* Mujeres de más de 25 años
ivreg2 sat edad capital (SNU=internet) if (sexo==0 & edad>25), robust first

* Mujeres de menos de 25 años
ivreg2 sat edad capital (SNU=internet) if (sexo==0 & edad<25), robust first
