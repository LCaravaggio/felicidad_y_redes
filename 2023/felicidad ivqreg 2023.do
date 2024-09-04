* Felicidad IVQREG
* INICIO
clear all
cscript

* qui do ivqreg.mata

set more off
set seed 12345

cd C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\2023
use LB2023


* Elimino las no respuestas de satisfacción con la vida, smartphone ownership, nivel de estudios, y si posee agua caliente de cañería
keep if P1ST>0


gen s14=0
replace s14=1 if S14M_A==1
replace s14=1 if S14M_B==1
replace s14=1 if S14M_C==1
replace s14=1 if S14M_D==1
replace s14=1 if S14M_E==1
replace s14=1 if S14M_F==1
replace s14=1 if S14M_G==1
replace s14=1 if S14M_H==1


*Generar variable SNU (Social Network Use)
generate SNU = 1 
replace SNU = 0 if S14M_J==1

gen sat=0
replace sat=1 if P1ST==4
replace sat=2 if P1ST==3
replace sat=3 if P1ST==2
replace sat=4 if P1ST==1

histogram sat, discrete normal kdensity plotregion(fcolor(white) style(none) color(gs16)) graphregion(fcolor(white))
graph export "Graph2.png", as(png) name("Graph") replace

* Regresión lineal MCO
* reg sat SNU p78n edad [pw=wt], robust (No es necesario ponderar la muestra)
reg sat SNU edad, robust

merge m:1 city using "ciudades_latlon_2023.dta" 


generate capital=0
replace capital=1 if tamciud==8 | tamciud==7

gen ingresos=0
replace ingresos=1 if S5==4
replace ingresos=2 if S5==3
replace ingresos=3 if S5==2
replace ingresos=4 if S5==1

gen estudios=S11

*Genero una variable en Megabits y con logaritmo para reducir variabilidad y problemas de medición
gen avg_d_mbps=avg_d_kbps/1024
gen lavg_d_mbps=log(avg_d_mbps)


* Estimación con IV y Test de Kleibergen-Paap para Velocidad de Internet como IV de SNU en Satisfacción
* ivreg2 sat ingresos edad (SNU=lavg_d_mbps), robust first



* Regresión lineal MCO
* reg sat SNU p78n edad [pw=wt], robust (No es necesario ponderar la muestra)
quietly reg sat SNU ingresos edad , robust
estimates store A
outreg2 using "Irrestricto 2023.tex", tex(frag) ctitle("MCO") replace fmt(fc) dec(3)  nor2

*First Stage
quietly reg SNU lavg_d_mbps ingresos edad , robust
estimates store B
outreg2 using "Irrestricto 2023.tex", tex(frag) ctitle("FS") append fmt(fc) dec(3)  nor2

* IV
quietly ivreg2 sat ingresos edad  (SNU=lavg_d_mbps) , robust first
estimates store C
outreg2 using "Irrestricto 2023.tex", tex(frag) ctitle("IV") append fmt(fc) dec(3) nor2

quietly ivreg2 sat estudios edad  (SNU=lavg_d_mbps) , robust first
estimates store D
outreg2 using "Irrestricto 2023.tex", tex(frag) ctitle("estudios") append fmt(fc) dec(3) nor2

quietly ivreg2 sat ingresos edad sexo  (SNU=lavg_d_mbps) , robust first
estimates store E
outreg2 using "Irrestricto 2023.tex", tex(frag) ctitle("sexo") append fmt(fc) dec(3) nor2

estimates table A B C D E, b(%8.3f) star stats(N) title(Irrestricto 2023)


rename S14M_A Facebook
rename S14M_B Snapchat
rename S14M_C Youtube
rename S14M_D Twitter
rename S14M_E Whatsapp
rename S14M_F Instagram
rename S14M_G TikTok
rename S14M_H LinkedIn

gen red=Facebook
quietly ivreg2 sat ingresos edad sexo  (red=lavg_d_mbps) , robust first
outreg2 using "Redes 2023.tex", tex(frag) ctitle(Facebook) replace fmt(fc) dec(3) nor2
local redes  Youtube Twitter Whatsapp Instagram TikTok 
foreach red in `redes'{
	replace red = `red'
	quietly ivreg2 sat ingresos edad sexo  (red=lavg_d_mbps) , robust first
	outreg2 using "Redes 2023.tex", tex(frag) ctitle(`red') append fmt(fc) dec(3) nor2
	}
