* Felicidad IVQREG
* INICIO
clear all
cscript

* qui do c:\data\ivqreg.mata

set more off
set seed 12345

cd F:\felicidad_ivqreg2\
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

*Histograma de la satisfacción con la vida y felicidad alternativa
histogram fel, discrete normal kdensity plotregion(fcolor(white) style(none) color(gs16)) graphregion(fcolor(white))
graph export "C:\data\Graph1.png", as(png) name("Graph") replace
histogram p1st, discrete normal kdensity plotregion(fcolor(white) style(none) color(gs16)) graphregion(fcolor(white))
graph export "C:\data\Graph2.png", as(png) name("Graph") replace


*Generar variable SNU (Social Network Use)
generate SNU = 1 
replace SNU = 0 if s19m_10==1


decode ciudad, generate(city)
merge m:1 city using "ciudades_latlon.dta" 

* Prueba de diferencia de medias
local varlist p1st fel p78n avg_d_kbps edad
matrix A = J(5,5,0)
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

matrix colnames A = mu_1 mu_2 sd_1 sd_2  P-Value
matrix rownames A = `varlist'

esttab matrix(A) using "A.tex", replace title(Análisis de Diferencia de Medias) postfoot("\label{A} \floatfoot{Nota: Se presentan las medias y desvíos estándar junto con el p-valor para la prueba de diferencia de medias, para las principales variables de interés dónde el primer grupo es el que no usa redes sociales y el segundo grupo es el que sí usa redes sociales.} \end{tabular} \end{table}") nomtitles


* Estimación con IV y Test de Kleibergen-Paap para Velocidad de Internet como IV de SNU en Satisfacción
quietly ivreg2 p1st p78n edad (SNU=avg_d_kbps), robust first

*Regresión cuantílica usando Velocidad de Internet como IV de SNU
* Cuantíl del 25% más feliz
quietly ivqreg2 p1st  SNU p78n edad  , instruments(p78n edad SNU avg_d_kbps) q(.25)
estimates store tau25
outreg2 using "c:\data\B.tex", tex(frag) ctitle("ivq25") replace
* Cuantíl del 50%
quietly ivqreg2 p1st  SNU p78n edad , instruments(p78n edad SNU avg_d_kbps) q(.5)
estimates store tau50
outreg2 using "c:\data\B.tex", tex(frag) ctitle("ivq50") append
* Cuantíl del 25% menos feliz
quietly ivqreg2 p1st  SNU p78n edad , instruments(p78n edad SNU avg_d_kbps) q(.75)
estimates store tau75
outreg2 using "c:\data\B.tex", tex(frag) ctitle("ivq75") append


* Irrestricto
estimates table tau25 tau50 tau75, b(%9.4f) star stats(N) title(Irrestricto)



*Regresión cuantílica usando Velocidad de Internet como IV de SNU
* Cuantíl del 25% más feliz
quietly ivqreg2 p1st  SNU p78n edad  if sexo==2, instruments(p78n edad SNU avg_d_kbps) q(.25)
estimates store tau25
outreg2 using "c:\data\sexo.tex", tex(frag) ctitle("ivq25") replace
* Cuantíl del 50%
quietly ivqreg2 p1st  SNU p78n edad  if sexo==2, instruments(p78n edad SNU avg_d_kbps) q(.5)
estimates store tau50
outreg2 using "c:\data\sexo.tex", tex(frag) ctitle("ivq50") append
* Cuantíl del 25% menos feliz
quietly ivqreg2 p1st  SNU p78n edad  if sexo==2, instruments(p78n edad SNU avg_d_kbps) q(.75)
estimates store tau75
outreg2 using "c:\data\sexo.tex", tex(frag) ctitle("ivq75") append


* Irrestricto
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
outreg2 using "c:\data\D.tex", tex(frag) ctitle("ivq25") replace
* Cuantíl del 50%
quietly ivqreg2 p1st SNU p78n edad  if (edad>60) , instruments(p78n edad SNU avg_d_kbps) q(.5)
estimates store tau50
outreg2 using "c:\data\D.tex" , tex(frag) ctitle("ivq50") append
* Cuantíl del 25% menos feliz
quietly ivqreg2 p1st SNU p78n edad  if  (edad>60), instruments(p78n edad SNU avg_d_kbps) q(.75)
estimates store tau75
outreg2 using "c:\data\D.tex" , tex(frag) ctitle("ivq75") append


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
quietly ivqreg2 fel  SNU p78n edad , instruments(p78n edad SNU avg_d_kbps) q(.25)
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


local i = 1
forvalues i=1(1)9{
    ivqreg2 fel s19m_0`i' p78n edad, instruments(SNU p78n edad avg_d_kbps) q(.25)
	estimates store tau25
    outreg2 using "por_red.tex", tex(frag) ctitle("ivq25") append
	ivqreg2 fel s19m_0`i' p78n edad, instruments(SNU p78n edad avg_d_kbps) q(.5)
	estimates store tau5
    outreg2 using "por_red.tex", tex(frag) ctitle("ivq25") append
	ivqreg2 fel s19m_0`i' p78n edad, instruments(SNU p78n edad avg_d_kbps) q(.75)
	estimates store tau75
    outreg2 using "por_red.tex", tex(frag) ctitle("ivq25") append
}
