* Felicidad IVQREG
* INICIO
clear all
cscript

* qui do ivqreg.mata

set more off
set seed 12345

cd C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\2018
use "LB2018 2"

* Elimino las no respuestas de satisfacción con la vida
drop if P1STC<0


*Generar variable SNU (Social Network Use)
generate SNU = 0
replace SNU = 1 if noredes==0

gen sat=0
replace sat=1 if P1STC==4
replace sat=2 if P1STC==3
replace sat=3 if P1STC==2
replace sat=4 if P1STC==1

gen ingresos=0
replace ingresos=1 if S1==4
replace ingresos=2 if S1==3
replace ingresos=3 if S1==2
replace ingresos=4 if S1==1

gen capital=0
replace capital =1 if TAMCIUD==8
replace capital =1 if TAMCIUD==7
*replace capital =1 if TAMCIUD==6
*replace capital =1 if TAMCIUD==5

gen estudios = S10


*histogram sat, discrete normal kdensity plotregion(fcolor(white) style(none) color(gs16)) graphregion(fcolor(white))
*graph export "Graph2.png", as(png) name("Graph") replace

gen city2=city
gen edad=EDAD

merge m:1 city using "a_mano_2018.dta" 


gen lavg_d_mbps=log(avg_d_kbps/1024)
*drop if latitude==0
drop if NUMINVES==.

gen internet=lavg_d_mbps
gen sexo=SEXO

* 0 es Mujer, 1 es hombre
replace sexo=0 if sexo==2



* Estadísticas básicas
local varlist sat SNU internet edad capital sexo ingresos estudios
matrix B = J(8,4,0)
local i=1
foreach var of local varlist {
    quietly sum `var'
		 
	matrix B[`i',1] = round(r(mean), 0.01)
	matrix B[`i',2] = round(r(Var), 0.01)
	matrix B[`i',3] = round(r(min), 0.1)
	matrix B[`i',4] = round(r(max), 0.1)

	
	local i = `i' + 1
}

matrix colnames B = Media Varianza Min Max
matrix rownames B = `varlist'

esttab matrix(B) using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\EstBas.tex", replace title(Estadísticas Básicas) postfoot("\label{EstBas} \floatfoot{Nota: Se presentan las medias, varianzas, mínimos y máximos de las principales variables de interés.} \end{tabular} \end{table}") nomtitles


* Prueba de diferencia de medias
local varlist sat internet edad capital sexo ingresos estudios
matrix A = J(7,5,0)
local i=1
foreach var of local varlist {
    quietly ttest `var', by(SNU)	
		 
	matrix A[`i',1] = r(mu_1)
	matrix A[`i',2] = r(mu_2)
	matrix A[`i',3] = r(sd_1)
	matrix A[`i',4] = r(sd_2)
	matrix A[`i',5] = r(p)
	
	local i = `i' + 1
}

matrix colnames A = No_Usa Usa sd_1 sd_2  P-Value
matrix rownames A = `varlist'

estout matrix(A, fmt(%3.2f)) using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\DefMedias.tex" , style(tex) replace



* Estadísticas por sat
local varlist SNU internet edad capital sexo ingresos estudios
matrix C = J(7,8,0)
local i=1
foreach var of local varlist {
    quietly sum `var' if sat==1
	matrix C[`i',1] = round(r(mean), 0.01)
	quietly sum `var' if sat==2
	matrix C[`i',2] = round(r(mean), 0.01)
	quietly sum `var' if sat==3
	matrix C[`i',3] = round(r(mean), 0.01)
	quietly sum `var' if sat==4
	matrix C[`i',4] = round(r(mean), 0.01)
	
	quietly sum `var' if sat==1
	matrix C[`i',5] = round(r(Var), 0.01)
	quietly sum `var' if sat==2
	matrix C[`i',6] = round(r(Var), 0.01)
	quietly sum `var' if sat==3
	matrix C[`i',7] = round(r(Var), 0.01)
	quietly sum `var' if sat==4
	matrix C[`i',8] = round(r(Var), 0.01)
	
	local i = `i' + 1
}

matrix colnames C = SAT1 SAT2 SAT3 SAT4 SAT1 SAT2 SAT3 SAT4
matrix rownames C = `varlist'

esttab matrix(C) using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\EstporSAT.tex", replace title(Estadísticas por Nivel de Satistacción) postfoot("\label{EstporSAT} \floatfoot{Nota: Se presentan las medias de las principales variables de interés por nivel de Satisfacción.} \end{tabular} \end{table}") nomtitles






* Regresión lineal MCO
* reg sat SNU p78n edad [pw=wt], robust (No es necesario ponderar la muestra)
quietly reg sat SNU edad capital, robust
estimates store A
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Cuadros.tex", tex(frag land) ctitle("MCO") replace fmt(fc) dec(2)  nor2 

*First Stage
quietly reg SNU internet edad capital, robust
estimates store B
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Cuadros.tex", tex(frag  land) ctitle("FS") append fmt(fc) dec(2)  nor2

* IV
quietly ivreg2 sat edad capital (SNU=internet) , robust first
estimates store C
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Cuadros.tex", tex(frag  land) ctitle("IV") append fmt(fc) dec(2) nor2 e(rkf) 



***** SEXO ****
* Regresión lineal MCO
quietly reg sat SNU edad capital if sexo==1, robust
estimates store A
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Sexo 2018.tex", tex(frag land) ctitle("MCO") replace fmt(fc) dec(2) nor2

*First Stage
quietly reg SNU internet edad capital if sexo==1, robust
estimates store B
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Sexo 2018.tex", tex(frag land) ctitle("FS") append fmt(fc) dec(2) nor2

* IV
quietly ivreg2 sat edad capital (SNU=internet) if sexo==1, robust first
estimates store C
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Sexo 2018.tex", tex(frag  land) ctitle("IV") append fmt(fc) dec(2) nor2 e(rkf) 

* Regresión lineal MCO
quietly reg sat SNU edad capital if sexo==0, robust
estimates store A
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Sexo 2018.tex", tex(frag land) ctitle("MCO") append fmt(fc) dec(2)  nor2 

*First Stage
quietly reg SNU internet edad capital if sexo==0, robust
estimates store B
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Sexo 2018.tex", tex(frag  land) ctitle("FS") append fmt(fc) dec(2)  nor2

* IV
quietly ivreg2 sat edad capital (SNU=internet) if sexo==0, robust first
estimates store C
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Sexo 2018.tex", tex(frag  land) ctitle("IV") append fmt(fc) dec(2) nor2 e(rkf) 




***** CIUDAD GRANDE ****
* Regresión lineal MCO
quietly reg sat SNU edad capital if capital==1, robust
estimates store A
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Capital 2018.tex", tex(frag land) ctitle("MCO") replace fmt(fc) dec(2) nor2

*First Stage
quietly reg SNU internet edad capital if capital==1, robust
estimates store B
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Capital 2018.tex", tex(frag land) ctitle("FS") append fmt(fc) dec(2) nor2

* IV
quietly ivreg2 sat edad capital (SNU=internet) if capital==1, robust first
estimates store C
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Capital 2018.tex", tex(frag  land) ctitle("IV") append fmt(fc) dec(2) nor2 e(rkf) 

* Regresión lineal MCO
quietly reg sat SNU edad capital if capital==0, robust
estimates store A
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Capital 2018.tex", tex(frag land) ctitle("MCO") append fmt(fc) dec(2)  nor2 

*First Stage
quietly reg SNU internet edad capital if capital==0, robust
estimates store B
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Capital 2018.tex", tex(frag  land) ctitle("FS") append fmt(fc) dec(2)  nor2

* IV
quietly ivreg2 sat edad capital (SNU=internet) if capital==0, robust first
estimates store C
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Capital 2018.tex", tex(frag  land) ctitle("IV") append fmt(fc) dec(2) nor2 e(rkf) 



***** SENSIBILIDAD ****
quietly ivreg2 sat edad capital sexo (SNU=internet) , robust first
estimates store D
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Sensibilidad.tex", tex(frag  land) ctitle("IV") replace fmt(fc) dec(2) nor2 e(rkf) 

quietly ivreg2 sat edad capital sexo ingresos (SNU=internet) , robust first
estimates store D
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Sensibilidad.tex", tex(frag  land) ctitle("IV") append fmt(fc) dec(2) nor2 e(rkf) 

quietly ivreg2 sat edad sexo estudios (SNU=internet) , robust first
estimates store D
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Sensibilidad.tex", tex(frag  land) ctitle("IV") append fmt(fc) dec(2) nor2 e(rkf) 


**************************** VIEJO *******************************
quietly ivreg2 sat ingresos edad sexo  (SNU=lavg_d_mbps) , robust first
estimates store D
outreg2 using "Irrestricto 2018.tex", tex(frag) ctitle("sexo") append fmt(fc) dec(3) nor2

quietly ivreg2 sat estudios edad  (SNU=lavg_d_mbps) , robust first
estimates store E
outreg2 using "Irrestricto 2018.tex", tex(frag) ctitle("estudios") append fmt(fc) dec(3) nor2


estimates table A B C D E, b(%8.3f) star stats(N) title(Irrestricto 2018)


rename s12m_a Facebook
rename s12m_b Snapchat
rename s12m_c Youtube
rename s12m_d Twitter
rename s12m_e Whatsapp
rename s12m_f Instagram
rename s12m_g TikTok
rename s12m_h LinkedIn

gen red=Facebook
quietly ivreg2 sat ingresos edad sexo  (red=lavg_d_mbps) , robust first
outreg2 using "Redes 2018.tex", tex(frag) ctitle(Facebook) replace fmt(fc) dec(3) nor2
local redes  Youtube Twitter Whatsapp Instagram TikTok 
foreach red in `redes'{
	replace red = `red'
	quietly ivreg2 sat ingresos edad sexo  (red=lavg_d_mbps) , robust first
	outreg2 using "Redes 2018.tex", tex(frag) ctitle(`red') append fmt(fc) dec(3) nor2
	}

