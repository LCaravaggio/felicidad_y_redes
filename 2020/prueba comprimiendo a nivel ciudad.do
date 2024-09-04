* Felicidad IVQREG
* INICIO
clear all
cscript

* qui do c:\data\ivqreg.mata

set more off
set seed 12345

cd C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\
use C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\LB2020.dta


* Generar felicidad alternativa
gen fel=0
replace fel=fel+4 if p1st==1 
replace fel=fel+3 if p1st==2 
replace fel=fel+2 if p1st==3 
replace fel=fel+1 if p1st==4 

replace fel=fel+5 if p4stgbs==1
replace fel=fel+4 if p4stgbs==2
replace fel=fel+3 if p4stgbs==3
replace fel=fel+2 if p4stgbs==4
replace fel=fel+1 if p4stgbs==5

replace fel=fel+2 if p2st==1
replace fel=fel+1 if p2st==2

replace fel=fel+5 if p7stgbs==1
replace fel=fel+4 if p7stgbs==2
replace fel=fel+3 if p7stgbs==3
replace fel=fel+2 if p7stgbs==4
replace fel=fel+1 if p7stgbs==5

replace fel=fel+2 if p9stgbs==1

label variable fel "Felicidad subjetiva creada"

* Elimino las no respuestas de satisfacción con la vida, smartphone ownership, nivel de estudios, y si posee agua caliente de cañería
keep if p1st>0
keep if p78n>0

*Generar variable SNU (Social Network Use)
generate SNU = 1 
replace SNU = 0 if s19m_10==1
drop if s19m_10 <0 

generate SNU2=0
drop if  s19m_04<0 | s19m_06<0 | s19m_07 <0
replace SNU2 = s19m_04+s19m_06+s19m_07
*replace SNU2 = 1 if s19m_04==1
*replace SNU2 = 1 if s19m_06==1
*replace SNU2 = 1 if s19m_07==1

generate capital=0
replace capital=1 if tamciud==8 | tamciud==7

gen sat=0
replace sat=1 if p1st==4
replace sat=2 if p1st==3
replace sat=3 if p1st==2
replace sat=4 if p1st==1


gen remoto=0
replace remoto=1 if p78n==1
gen ingresos=s5npn
gen estudios=s16

drop if remoto<0 | ingresos<0 | estudios<0

decode ciudad, generate(city)
keep idenpa city sat SNU ingresos estudios edad

collapse (mean) idenpa edad SNU sat ingresos estudios, by(city)

merge m:1 city using "ciudades_latlon.dta" 

drop if missing( avg_d_kbps )
drop if missing( idenpa )

gen avg_d_mbps=avg_d_kbps/1024
ivreg2 sat ingresos estudios edad  (SNU=avg_d_mbps), robust first
