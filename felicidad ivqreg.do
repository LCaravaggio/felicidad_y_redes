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

decode ciudad, generate(city)
merge m:1 city using "ciudades_latlon.dta" 

*Histograma de la satisfacción con la vida y felicidad alternativa
histogram fel, discrete normal kdensity plotregion(fcolor(white) style(none) color(gs16)) graphregion(fcolor(white)) xtitle("")
graph export "Graph1.png", as(png) name("Graph") replace
histogram sat, discrete normal kdensity plotregion(fcolor(white) style(none) color(gs16)) graphregion(fcolor(white)) xtitle("")
graph export "Graph2.png", as(png) name("Graph") replace

gen avg_d_mbps=avg_d_kbps/1024

* Testeo de la Primera Etapa
ttest avg_d_mbps, by(SNU)
*ttest avg_d_mbps, by(SNU2)

gen remoto=0
replace remoto=1 if p78n==1
gen ingresos=s5npn
gen estudios=s16

drop if remoto<0 | ingresos<0 | estudios<0

* Prueba de diferencia de medias
local varlist fel sat avg_d_mbps edad remoto ingresos estudios capital
matrix A = J(8,5,0)
local i=1
foreach var of local varlist {
    quietly ttest `var', by(SNU)	
		 
	matrix A[`i',1] = round(r(mu_1), 0.001)
	matrix A[`i',2] = round(r(mu_2), 0.001)
	matrix A[`i',3] = round(r(sd_1), 0.001)
	matrix A[`i',4] = round(r(sd_2), 0.001)
	matrix A[`i',5] = r(p)
	
	local i = `i' + 1
}

matrix colnames A = No_Usa Usa sd_1 sd_2  P-Value
matrix rownames A = `varlist'

esttab matrix(A) using "A.tex", replace title(Análisis de Diferencia de Medias) postfoot("\label{A} \floatfoot{Nota: Se presentan las medias y desvíos estándar junto con el p-valor para la prueba de diferencia de medias, para las principales variables de interés dónde el primer grupo es el que no usa redes sociales y el segundo grupo es el que sí usa redes sociales.} \end{tabular} \end{table}") nomtitles



* Estadísticas básicas
local varlist fel sat SNU avg_d_mbps edad remoto ingresos estudios capital
matrix B = J(9,4,0)
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

esttab matrix(B) using "EstBas.tex", replace title(Estadísticas Básicas) postfoot("\label{EstBas} \floatfoot{Nota: Se presentan las medias, varianzas, mínimos y máximos de las principales variables de interés.} \end{tabular} \end{table}") nomtitles



* Regresión lineal MCO
* reg sat SNU p78n edad [pw=wt], robust (No es necesario ponderar la muestra)
reg sat SNU ingresos estudios edad, robust

* IV
ivreg2 sat ingresos estudios edad capital (SNU=avg_d_mbps), robust first

* Estimación con IV y Test de Kleibergen-Paap para Velocidad de Internet como IV de SNU en Satisfacción
quietly ivreg2 sat p78n edad (SNU=avg_d_kbps), robust first

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
