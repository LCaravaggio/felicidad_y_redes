* Felicidad IVQREG
* INICIO
clear all
cscript

* qui do c:\data\ivqreg.mata

set more off
set seed 12345

cd C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\2020
use LB2020.dta


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

generate capital=0
replace capital=1 if tamciud==8 | tamciud==7

gen sat=0
replace sat=1 if p1st==4
replace sat=2 if p1st==3
replace sat=3 if p1st==2
replace sat=4 if p1st==1

decode ciudad, generate(city)
merge m:1 city using "a_mano_2020.dta" 
*drop if latitude==0

*Genero una variable en Megabits y con logaritmo para reducir variabilidad y problemas de medición
gen lavg_d_mbps=log(avg_d_kbps/1024)

* Testeo de la Primera Etapa
ttest lavg_d_mbps, by(SNU)
*ttest avg_d_mbps, by(SNU2)

gen remoto=0
replace remoto=1 if p78n==1
gen ingresos=0
replace ingresos = 1 if s5npn==1 |  s5npn==2 |  s5npn==3
replace ingresos = 2 if s5npn==4 |  s5npn==5   
replace ingresos = 3 if s5npn==6 | s5npn==7 
replace ingresos = 4 if s5npn==8 | s5npn==9 | s5npn==10 

gen estudios=s16

*drop if remoto<0 | ingresos<0 | estudios<0


gen smartphone=0
replace smartphone = 1 if s26_l==1
gen internet=lavg_d_mbps

* 0 es Mujer, 1 es hombre
replace sexo=0 if sexo==2


* Prueba de compatibilidad
gen SNU2=0
replace SNU2=1 if s19m_01==1 | s19m_02==1 | s19m_03==1 | s19m_04==1 | s19m_05==1 | s19m_06==1 | s19m_07==1 | s19m_08==1  | s19m_09==1
drop if SNU!=SNU2

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
drop SNU2
gen SNU2=0
replace SNU2=1 if s19m_01==1 | s19m_02==1 | s19m_03==1 | s19m_04==1 | s19m_05==1 | s19m_06==1 | s19m_07==1 | s19m_08==1  | s19m_09==1
ivreg2 sat edad capital (SNU2=internet) , robust



* Regresión lineal MCO
* reg sat SNU p78n edad [pw=wt], robust (No es necesario ponderar la muestra)
quietly reg sat SNU edad capital , robust
estimates store A
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Cuadros.tex", tex(frag  land) ctitle("MCO") append fmt(fc) dec(2)  nor2

*First Stage
quietly reg SNU internet edad capital, robust
estimates store B
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Cuadros.tex", tex(frag  land) ctitle("FS") append fmt(fc) dec(2)  nor2

* IV
quietly ivreg2 sat edad capital (SNU=internet) , robust first
estimates store C
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Cuadros.tex", tex(frag  land) ctitle("IV") append fmt(fc) dec(2) nor2 e(rkf) 

replace sexo=0 if sexo==2


***** SEXO *******
* Regresión lineal MCO
quietly reg sat SNU edad capital if sexo==1, robust
estimates store A
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Sexo 2020.tex", tex(frag land) ctitle("MCO") replace fmt(fc) dec(2) nor2

*First Stage
quietly reg SNU internet edad capital if sexo==1, robust
estimates store B
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Sexo 2020.tex", tex(frag land) ctitle("FS") append fmt(fc) dec(2) nor2

* IV
quietly ivreg2 sat edad capital (SNU=internet) if sexo==1, robust first
estimates store C
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Sexo 2020.tex", tex(frag  land) ctitle("IV") append fmt(fc) dec(2) nor2 e(rkf) 

* Regresión lineal MCO
quietly reg sat SNU edad capital if sexo==0, robust
estimates store A
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Sexo 2020.tex", tex(frag land) ctitle("MCO") append fmt(fc) dec(2)  nor2 

*First Stage
quietly reg SNU internet edad capital if sexo==0, robust
estimates store B
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Sexo 2020.tex", tex(frag  land) ctitle("FS") append fmt(fc) dec(2)  nor2

* IV
quietly ivreg2 sat edad capital (SNU=internet) if sexo==0, robust first
estimates store C
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Sexo 2020.tex", tex(frag  land) ctitle("IV") append fmt(fc) dec(2) nor2 e(rkf) 




***** CIUDAD GRANDE ****
* Regresión lineal MCO
quietly reg sat SNU edad capital if capital==1, robust
estimates store A
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Capital 2020.tex", tex(frag land) ctitle("MCO") replace fmt(fc) dec(2) nor2

*First Stage
quietly reg SNU internet edad capital if capital==1, robust
estimates store B
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Capital 2020.tex", tex(frag land) ctitle("FS") append fmt(fc) dec(2) nor2

* IV
quietly ivreg2 sat edad capital (SNU=internet) if capital==1, robust first
estimates store C
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Capital 2020.tex", tex(frag  land) ctitle("IV") append fmt(fc) dec(2) nor2 e(rkf) 

* Regresión lineal MCO
quietly reg sat SNU edad capital if capital==0, robust
estimates store A
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Capital 2020.tex", tex(frag land) ctitle("MCO") append fmt(fc) dec(2)  nor2 

*First Stage
quietly reg SNU internet edad capital if capital==0, robust
estimates store B
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Capital 2020.tex", tex(frag  land) ctitle("FS") append fmt(fc) dec(2)  nor2

* IV
quietly ivreg2 sat edad capital (SNU=internet) if capital==0, robust first
estimates store C
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Capital 2020.tex", tex(frag  land) ctitle("IV") append fmt(fc) dec(2) nor2 e(rkf) 



quietly ivreg2 sat edad  (SNU=internet) if capital==1, robust first
estimates store A
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Ciudad.tex", tex(frag  land) ctitle(">100000") append fmt(fc) dec(2) nor2 e(rkf) 

quietly ivreg2 sat edad  (SNU=internet) if capital==0, robust first
estimates store B
outreg2 using "C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\Ciudad.tex", tex(frag  land) ctitle("<100000") append fmt(fc) dec(2) nor2 e(rkf) 



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


****** GRAFICOS ******
graph bar (mean) internet, over(SNU) ytitle("Media de Calidad de Internet") plotregion(fcolor(white) style(none) color(gs16)) graphregion(fcolor(white)) 
graph export "Internet por SNU.png", as(png) name("Graph") replace



*Histograma de la satisfacción con la vida y felicidad alternativa
*histogram fel, discrete normal kdensity plotregion(fcolor(white) style(none) color(gs16)) graphregion(fcolor(white)) xtitle("")
*graph export "Graph1.png", as(png) name("Graph") replace
histogram sat, discrete normal kdensity plotregion(fcolor(white) style(none) color(gs16)) graphregion(fcolor(white)) xtitle("")
graph export "Graph2.png", as(png) name("Graph") replace





************************ VIEJO *******************************

* Regresión lineal MCO
* reg sat SNU p78n edad [pw=wt], robust (No es necesario ponderar la muestra)
quietly reg sat SNU edad remoto, robust
estimates store A
outreg2 using "Irrestricto 2020.tex", tex(frag) ctitle("MCO") replace fmt(fc) dec(3)  nor2

*First Stage
quietly reg SNU lavg_d_mbps edad remoto, robust
estimates store B
outreg2 using "Irrestricto 2020.tex", tex(frag) ctitle("FS") append fmt(fc) dec(3)  nor2

* IV
quietly ivreg2 sat edad (SNU=lavg_d_mbps) , robust first
estimates store C
outreg2 using "Irrestricto 2020.tex", tex(frag) ctitle("IV") append fmt(fc) dec(3) nor2

quietly ivreg2 sat edad (SNU=lavg_d_mbps) , robust first
estimates store D
outreg2 using "Irrestricto 2020.tex", tex(frag) ctitle("estudios") append fmt(fc) dec(3) nor2

quietly ivreg2 sat ingresos edad remoto (SNU=lavg_d_mbps) , robust first
estimates store E
outreg2 using "Irrestricto 2020.tex", tex(frag) ctitle("remoto") append fmt(fc) dec(3) nor2

quietly ivreg2 sat ingresos edad capital (SNU=lavg_d_mbps) , robust first
estimates store F
outreg2 using "Irrestricto 2020.tex", tex(frag) ctitle("ciudad grande") append fmt(fc) dec(3) nor2

estimates table A B C D E F, b(%8.3f) star stats(N) title(Irrestricto 2020)



rename s19m_01 Facebook
rename s19m_02 Snapchat
rename s19m_03 Youtube
rename s19m_04 Twitter
rename s19m_05 Whatsapp
rename s19m_06 Instagram
rename s19m_07 TikTok
rename s19m_08 LinkedIn

gen red=Facebook
quietly ivreg2 sat edad remoto  (red=lavg_d_mbps) , robust first
outreg2 using "Redes 2020.tex", tex(frag) ctitle(Facebook) replace fmt(fc) dec(3) nor2
local redes  Youtube Twitter Whatsapp Instagram TikTok 
foreach red in `redes'{
	replace red = `red'
	quietly ivreg2 sat edad remoto (red=lavg_d_mbps) , robust first
	outreg2 using "Redes 2020.tex", tex(frag) ctitle(`red') append fmt(fc) dec(3) nor2
	} 	

	

/*	
gen sit=0
replace sit = 1 if p7stgbs==5
replace sit = 2 if p7stgbs==4
replace sit = 3 if p7stgbs==3
replace sit = 4 if p7stgbs==2
replace sit = 5 if p7stgbs==1

gen iglesia=0
replace iglesia = 4 if p13st_c==1
replace iglesia = 2 if p13st_c==2
replace iglesia = 3 if p13st_c==3
replace iglesia = 1 if p13st_c==4

gen congreso=0
replace congreso = 4 if p13st_d==1
replace congreso = 2 if p13st_d==2
replace congreso = 3 if p13st_d==3
replace congreso = 1 if p13st_d==4

gen gobierno=0
replace gobierno = 4 if p13st_e==1
replace gobierno = 2 if p13st_e==2
replace gobierno = 3 if p13st_e==3
replace gobierno = 1 if p13st_e==4

gen presidente=0
replace presidente = 4 if p13st_i==1
replace presidente = 2 if p13st_i==2
replace presidente = 3 if p13st_i==3
replace presidente = 1 if p13st_i==4

gen judicial=0
replace judicial = 4 if p13st_f==1
replace judicial = 2 if p13st_f==2
replace judicial = 3 if p13st_f==3
replace judicial = 1 if p13st_f==4

gen casa=0
replace casa=1 if s26_b ==1

gen computadora=0
replace computadora=1 if s26_c ==1

gen lavarropas=0
replace lavarropas=1 if s26_d ==1

gen celular=0
replace celular=1 if s26_f==1

gen auto=0
replace auto=1 if s26_g ==1

ivreg2 sat ingresos edad sit iglesia congreso gobierno presidente judicial casa computadora lavarropas celular auto (SNU=lavg_d_mbps) , robust first
	
							**** CUANTILICA ****
							
*Regresión cuantílica usando Velocidad de Internet como IV de SNU
* Cuantíl del 25% menos feliz
quietly ivqreg2 sat  SNU p78n edad  , instruments(p78n edad SNU avg_d_kbps) q(.25)
estimates store tau25
outreg2 using "c:\data\B.tex", tex(frag) ctitle("ivq25") replace
* Cuantíl del 50%
quietly ivqreg2 sat  SNU p78n edad , instruments(p78n edad SNU avg_d_kbps) q(.5)
estimates store tau50
outreg2 using "c:\data\B.tex", tex(frag) ctitle("ivq50") append
* Cuantíl del 25% más feliz
quietly ivqreg2 sat  SNU p78n edad , instruments(p78n edad SNU avg_d_kbps) q(.75)
estimates store tau75
outreg2 using "c:\data\B.tex", tex(frag) ctitle("ivq75") append

estimates table tau25 tau50 tau75, b(%9.4f) star stats(N) title(Irrestricto)



*Regresión cuantílica usando Velocidad de Internet IV de SNU. ENTRE 18 y 25 AÑOS
* Cuantíl del 25% más feliz
quietly ivqreg2 p1st SNU p78n edad  if (edad>18 & edad<25) , instruments(p78n edad SNU avg_d_kbps) q(.25)
estimates store tau25
outreg2 using "c:\data\C.tex", tex(frag) ctitle("ivq25") replace
* Cuantíl del 50%
quietly ivqreg2 p1st SNU p78n edad  if (edad>18 & edad<25) , instruments(p78n edad SNU avg_d_kbps) q(.5)
estimates store tau50
outreg2 using "c:\data\C.tex" , tex(frag) ctitle("ivq50") append
* Cuantíl del 25% menos feliz
quietly ivqreg2 p1st SNU p78n edad  if (edad>18 & edad<25), instruments(p78n edad SNU avg_d_kbps) q(.75)
estimates store tau75
outreg2 using "c:\data\C.tex"  , tex(frag) ctitle("ivq75") append


* Edad entre 18 y 25
estimates table tau25 tau50 tau75, b(%9.4f) star stats(N) title(Entre 18 y 25)


* Edad más 60
* Cuantíl del 25% más feliz
quietly ivqreg2 p1st SNU p78n edad  if (edad>60) , instruments(p78n edad SNU avg_d_kbps) q(.25)
estimates store tau25
outreg2 using "c:\data\C.tex", tex(frag) ctitle("ivq25") replace
* Cuantíl del 50%
quietly ivqreg2 p1st SNU p78n edad  if (edad>60) , instruments(p78n edad SNU avg_d_kbps) q(.5)
estimates store tau50
outreg2 using "c:\data\C.tex" , tex(frag) ctitle("ivq50") append
* Cuantíl del 25% menos feliz
quietly ivqreg2 p1st SNU p78n edad  if  (edad>60), instruments(p78n edad SNU avg_d_kbps) q(.75)
estimates store tau75
outreg2 using "c:\data\C.tex" , tex(frag) ctitle("ivq75") append


estimates table tau25 tau50 tau75, b(%9.4f) star stats(N) title(Mayores de 60)


* Smoothed IV quantile regression
quietly sivqr p1st p78n edad (SNU=avg_d_kbps), quantile(.25)
estimates store tau25
outreg2 using "c:\data\E.tex", tex(frag) ctitle("siqr25") replace
quietly sivqr p1st p78n edad  (SNU=avg_d_kbps), quantile(.5)
estimates store tau50
outreg2 using "c:\data\E.tex", tex(frag) ctitle("siqr50") append
quietly sivqr p1st p78n edad (SNU=avg_d_kbps), quantile(.75)
estimates store tau75
outreg2 using "c:\data\E.tex", tex(frag) ctitle("siqr75") append

* Smoothed IV quantile regression
estimates table tau25 tau50 tau75, b(%9.4f) star stats(N) title(SIVQR)


* Chequeo Velocidad de Internet como IV de SNU para Felicidad

* Estimación con IV y Test de Kleibergen-Paap
quietly ivreg2 fel SNU p78n edad (SNU=avg_d_kbps), robust first
outreg2 using "c:\data\F.tex", tex(frag) ctitle("ivreg2") replace


*Regresión cuantílica usando Velocidad de Internet como IV de SNU
* Cuantíl del 25% más feliz
quietly ivqreg2 fel SNU p78n edad , instruments(p78n edad SNU avg_d_kbps) q(.25)
estimates store tau25
outreg2 using "c:\data\G.tex", tex(frag) ctitle("ivq25") replace
* Cuantíl del 50%
quietly ivqreg2 fel SNU p78n edad , instruments(p78n edad SNU avg_d_kbps) q(.5)
estimates store tau50
outreg2 using "c:\data\G.tex", tex(frag) ctitle("ivq50") append
* Cuantíl del 25% menos feliz
quietly ivqreg2 fel SNU p78n edad , instruments(p78n edad SNU avg_d_kbps) q(.75)
estimates store tau75
outreg2 using "c:\data\G.tex", tex(frag) ctitle("ivq75") append


* Irrestricto
estimates table tau25 tau50 tau75, b(%9.4f) star stats(N) title(Irrestricto Felicidad)



*Regresión cuantílica usando Velocidad de Internet IV de SNU. ENTRE 18 y 25 AÑOS Felicidad
* Cuantíl del 25% más feliz
quietly ivqreg2 fel SNU p78n edad  if (edad>18 & edad<25) , instruments(p78n edad SNU avg_d_kbps) q(.25)
estimates store tau25
outreg2 using "c:\data\H.tex", tex(frag) ctitle("ivq25 joven") append
* Cuantíl del 50%
quietly ivqreg2 fel SNU p78n edad  if (edad>18 & edad<25) , instruments(p78n edad SNU avg_d_kbps) q(.5)
estimates store tau50
outreg2 using "c:\data\H.tex"  , tex(frag) ctitle("ivq50 joven") append
* Cuantíl del 25% menos feliz
quietly ivqreg2 fel SNU p78n edad if (edad>18 & edad<25) , instruments(p78n edad SNU avg_d_kbps) q(.75)
estimates store tau75
outreg2 using "c:\data\H.tex"  , tex(frag) ctitle("ivq75 joven") append

* Edad entre 18 y 25
estimates table tau25 tau50 tau75, b(%9.4f) star stats(N) title(Entre 18 y 25 Felicidad)

* Edad más 60 Felicidad
* Cuantíl del 25% más feliz
quietly ivqreg2 fel SNU p78n edad  if edad>60 , instruments(p78n edad SNU avg_d_kbps) q(.25)
estimates store tau25
outreg2 using "c:\data\I.tex", tex(frag) ctitle("ivq25 may") append
* Cuantíl del 50%
quietly ivqreg2 fel SNU p78n edad  if edad>60 , instruments(p78n edad SNU avg_d_kbps) q(.5)
estimates store tau50
outreg2 using "c:\data\I.tex", tex(frag) ctitle("ivq25 may") append
* Cuantíl del 25% menos feliz
quietly ivqreg2 fel SNU p78n edad if edad>60 , instruments(p78n edad SNU avg_d_kbps) q(.75)
estimates store tau75
outreg2 using "c:\data\I.tex", tex(frag) ctitle("ivq25 may") append

estimates table tau25 tau50 tau75, b(%9.4f) star stats(N) title(Mayores de 60 Felicidad)


* Smoothed IV quantile regression felicidad
quietly sivqr fel p78n edad (SNU=avg_d_kbps) , quantile(.25)
estimates store tau25
outreg2 using "c:\data\J.tex", tex(frag) ctitle("siqr25") replace
quietly sivqr fel p78n edad  (SNU=avg_d_kbps) , quantile(.5)
estimates store tau50
outreg2 using "c:\data\J.tex", tex(frag) ctitle("siqr50") append
quietly sivqr fel p78n edad (SNU=avg_d_kbps) , quantile(.75)
estimates store tau75
outreg2 using "c:\data\J.tex", tex(frag) ctitle("siqr75") append

* Smoothed IV quantile regression
estimates table tau25 tau50 tau75, b(%9.4f) star stats(N) title(SIVQR Felicidad)


* Gráficos de impacto sobre la distribución cuantílica
ivqreg2 fel p78n edad  SNU, instruments(SNU p78n edad avg_d_kbps)
qregplot SNU, mtitles("Impacto en felicidad") plotregion(fcolor(white) style(none) color(gs16)) graphregion(fcolor(white))
graph export "C:\data\Graph3.png", as(png) name("Graph") replace

ivqreg2 p1st p78n edad  SNU, instruments(SNU p78n edad avg_d_kbps)
qregplot SNU, mtitles("Impacto en p1st") plotregion(fcolor(white) style(none) color(gs16)) graphregion(fcolor(white))
graph export "C:\data\Graph4.png", as(png) name("Graph") replace


* Lista de códigos numéricos de países
local codigos 32 68 76 170 188 152 218 222 320 340 484 558 591 600 604 214 858 862
local nombres "Argentina" "Bolivia" "Brasil" "Colombia" "Costa_Rica" "Chile" "Ecuador" "El_Salvador" "Guatemala" "Honduras" "Mexico" "Nicaragua" "Panama" "Paraguay" "Peru" "R_Dominicana" "Uruguay" "Venezuela"

* PAIS
local i = 1
foreach codigo in `codigos' {
    local pais : word `i' of `nombres'
    
    * Cuantíl del 15% más feliz
    quietly ivqreg2 fel SNU p78n edad if idenpa == `codigo', instruments(SNU p78n edad avg_d_kbps) q(.25)
    estimates store tau25
    outreg2 using "por_paises.tex", tex(frag) ctitle("ivq25") append
    
    * Cuantíl del 50%
    quietly ivqreg2 fel SNU p78n edad if idenpa == `codigo', instruments(SNU p78n edad avg_d_kbps) q(.5)
    estimates store tau50
    outreg2 using "por_paises.tex", tex(frag) ctitle("ivq50") append
    
    * Cuantíl del 15% menos feliz
    quietly ivqreg2 fel SNU p78n edad if idenpa == `codigo', instruments(SNU p78n edad avg_d_kbps) q(.75)
    estimates store tau75
    outreg2 using "por_paises.tex", tex(frag) ctitle("ivq75") append
    
    local i = `i' + 1
}

* RED SOCIAL
local i = 1
forvalues i=1(1)9{
    ivqreg2 fel s19m_0`i' p78n edad, instruments(SNU p78n edad avg_d_kbps) q(.25)
	estimates store tau25
    outreg2 using "por_red.tex", tex(frag) ctitle("ivq25") append
	ivqreg2 fel s19m_0`i' p78n edad, instruments(SNU p78n edad avg_d_kbps) q(.5)
	estimates store tau5
    outreg2 using "por_red.tex", tex(frag) ctitle("ivq5") append
	ivqreg2 fel s19m_0`i' p78n edad, instruments(SNU p78n edad avg_d_kbps) q(.75)
	estimates store tau75
    outreg2 using "por_red.tex", tex(frag) ctitle("ivq75") append
}
