* Felicidad IVQREG
* INICIO
clear all
cscript

* qui do ivqreg.mata

set more off
set seed 12345

cd C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\2023
use Latinobarometro_2023_Esp_Stata_v1_0


* Elimino las no respuestas de satisfacción con la vida, smartphone ownership, nivel de estudios, y si posee agua caliente de cañería
keep if P1ST>0


gen s14=0
replace s14=1 if (S14M_A==1 | S14M_B==1 | S14M_C==1 | S14M_D==1 |S14M_E==1 | S14M_F==1 | S14M_G==1 |  S14M_H==1 |  S14M_I==1)

*Generar variable SNU (Social Network Use)
*generate SNU = 1 
*replace SNU = 0 if S14M_J==1

gen SNU=s14


gen sat=0
replace sat=1 if P1ST==4
replace sat=2 if P1ST==3
replace sat=3 if P1ST==2
replace sat=4 if P1ST==1

* Regresión lineal MCO
* reg sat SNU p78n edad [pw=wt], robust (No es necesario ponderar la muestra)
*reg sat SNU edad, robust

decode ciudad, gen(city)


merge m:1 city using "a_mano_2023.dta" 
*drop if latitude==0

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
*gen avg_u_mbps=avg_u_kbps/1024
*gen calidad_internet=log((avg_d_mbps+avg_u_mbps)/2)

* Estimación con IV y Test de Kleibergen-Paap para Velocidad de Internet como IV de SNU en Satisfacción
* ivreg2 sat ingresos edad (SNU=lavg_d_mbps), robust first

gen smartphone = 0
replace smartphone = 1 if  S20_D==1


gen internet=lavg_d_mbps

* 0 es Mujer, 1 es hombre
replace sexo=0 if sexo==2


*Prueba de compatibilidad
*gen SNU2=1
*replace SNU2=0 if S14M_J==1
*drop if SNU!=SNU2



* Estadísticas básicas
local varlist sat SNU internet edad capital sexo estudios ingresos
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

esttab matrix(B) using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\EstBas.tex", append title(Estadísticas Básicas) postfoot("\label{EstBas} \floatfoot{Nota: Se presentan las medias, varianzas, mínimos y máximos de las principales variables de interés.} \end{tabular} \end{table}") nomtitles




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

estout matrix(A, fmt(%3.2f)) using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\DefMedias.tex" , style(tex) append


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

esttab matrix(C) using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\EstporSAT.tex", append title(Estadísticas por Nivel de Satistacción) postfoot("\label{EstporSAT} \floatfoot{Nota: Se presentan las medias de las principales variables de interés por nivel de Satisfacción.} \end{tabular} \end{table}") nomtitles


* Prueba por redes
*drop SNU2
*gen SNU2=1
*replace SNU2=0 if S14M_J==1
*ivreg2 sat edad capital (SNU2=internet) , robust


*drop SNU3
*gen SNU3=0
*replace SNU3=1 if (S14M_G==1)
*ivreg2 sat edad capital (SNU3=internet) , robust


* Regresión lineal MCO
* reg sat SNU p78n edad [pw=wt], robust (No es necesario ponderar la muestra)
quietly reg sat SNU edad capital, robust
estimates store A
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Cuadros.tex", tex(frag land) ctitle("MCO") append fmt(fc) dec(2)  nor2

*First Stage
quietly reg SNU internet edad capital, robust
estimates store B
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Cuadros.tex", tex(frag land) ctitle("FS") append fmt(fc) dec(2)  nor2

* IV
quietly ivreg2 sat edad capital (SNU=internet) , robust first
estimates store C
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Cuadros.tex", tex(frag land) ctitle("IV") append fmt(fc) dec(2) nor2 e(rkf) 



**** SEXO ****
* Regresión lineal MCO
quietly reg sat SNU edad capital if sexo==1, robust
estimates store A
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Sexo 2023.tex", tex(frag land) ctitle("MCO") replace fmt(fc) dec(2) nor2

*First Stage
quietly reg SNU internet edad capital if sexo==1, robust
estimates store B
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Sexo 2023.tex", tex(frag land) ctitle("FS") append fmt(fc) dec(2) nor2

* IV
quietly ivreg2 sat edad capital (SNU=internet) if sexo==1, robust first
estimates store C
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Sexo 2023.tex", tex(frag  land) ctitle("IV") append fmt(fc) dec(2) nor2 e(rkf) 

* Regresión lineal MCO
quietly reg sat SNU edad capital if sexo==0, robust
estimates store A
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Sexo 2023.tex", tex(frag land) ctitle("MCO") append fmt(fc) dec(2)  nor2 

*First Stage
quietly reg SNU internet edad capital if sexo==0, robust
estimates store B
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Sexo 2023.tex", tex(frag  land) ctitle("FS") append fmt(fc) dec(2)  nor2

* IV
quietly ivreg2 sat edad capital (SNU=internet) if sexo==0, robust first
estimates store C
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Sexo 2023.tex", tex(frag  land) ctitle("IV") append fmt(fc) dec(2) nor2 e(rkf) 


*Prueba de Wald para sexo
ivreg2 sat edad capital (SNU = internet) if sexo==1, robust
matrix b1 = e(b)
matrix V1 = e(V)

ivreg2 sat edad capital (SNU = internet) if sexo==0, robust
matrix b2 = e(b)
matrix V2 = e(V)

matrix diff = b1 - b2  // Diferencia de coeficientes
matrix Vdiff = V1 + V2 // Suma de las varianzas

matrix chi2 = diff*inv(Vdiff)*diff' // Estadístico de prueba de Wald
display "Chi2(1) = " chi2[1,1]
display "p-value = " chiprob(1, chi2[1,1])


***** CIUDAD GRANDE ****
* Regresión lineal MCO
quietly reg sat SNU edad capital if capital==1, robust
estimates store A
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Capital 2023.tex", tex(frag land) ctitle("MCO") replace fmt(fc) dec(2) nor2

*First Stage
quietly reg SNU internet edad capital if capital==1, robust
estimates store B
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Capital 2023.tex", tex(frag land) ctitle("FS") append fmt(fc) dec(2) nor2

* IV
quietly ivreg2 sat edad capital (SNU=internet) if capital==1, robust first
estimates store C
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Capital 2023.tex", tex(frag  land) ctitle("IV") append fmt(fc) dec(2) nor2 e(rkf) 

* Regresión lineal MCO
quietly reg sat SNU edad capital if capital==0, robust
estimates store A
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Capital 2023.tex", tex(frag land) ctitle("MCO") append fmt(fc) dec(2)  nor2 

*First Stage
quietly reg SNU internet edad capital if capital==0, robust
estimates store B
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Capital 2023.tex", tex(frag  land) ctitle("FS") append fmt(fc) dec(2)  nor2

* IV
quietly ivreg2 sat edad capital (SNU=internet) if capital==0, robust first
estimates store C
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Capital 2023.tex", tex(frag  land) ctitle("IV") append fmt(fc) dec(2) nor2 e(rkf) 



*Prueba de Wald para capital
ivreg2 sat edad  (SNU=internet) if capital==1, robust 
matrix b1 = e(b)
matrix V1 = e(V)

ivreg2 sat edad  (SNU=internet) if capital==0, robust 
matrix b2 = e(b)
matrix V2 = e(V)

matrix diff = b1 - b2  
matrix Vdiff = V1 + V2 

matrix chi2 = diff*inv(Vdiff)*diff' 
display "Chi2(1) = " chi2[1,1]
display "p-value = " chiprob(1, chi2[1,1])

***** SENSIBILIDAD ****
quietly ivreg2 sat edad capital sexo (SNU=internet) , robust first
estimates store D
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Sensibilidad.tex", tex(frag  land) ctitle("IV") append fmt(fc) dec(2) nor2 e(rkf) 

quietly ivreg2 sat edad capital sexo ingresos (SNU=internet) , robust first
estimates store D
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Sensibilidad.tex", tex(frag  land) ctitle("IV") append fmt(fc) dec(2) nor2 e(rkf) 

quietly ivreg2 sat edad sexo estudios (SNU=internet) , robust first
estimates store D
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Sensibilidad.tex", tex(frag  land) ctitle("IV") append fmt(fc) dec(2) nor2 e(rkf) 




*****Gráficos******
histogram sat, discrete normal kdensity plotregion(fcolor(white) style(none) color(gs16)) graphregion(fcolor(white))
graph export "Graph2.png", as(png) name("Graph") replace


******************* VIEJO ***************************



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

quietly ivreg2 sat ingresos edad sexo  (SNU=lavg_d_mbps) , robust first
estimates store D
outreg2 using "Irrestricto 2023.tex", tex(frag) ctitle("sexo") append fmt(fc) dec(3) nor2

quietly ivreg2 sat estudios edad  (SNU=lavg_d_mbps) , robust first
estimates store E
outreg2 using "Irrestricto 2023.tex", tex(frag) ctitle("estudios") append fmt(fc) dec(3) nor2

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
