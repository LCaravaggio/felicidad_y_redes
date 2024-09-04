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

esttab matrix(A) using "A.tex", replace title(Análisis de Diferencia de Medias - por SNU) postfoot("\label{A} \floatfoot{Nota: Se presentan las medias y desvíos estándar junto con el p-valor para la prueba de diferencia de medias, para las principales variables de interés dónde el primer grupo es el que no usa redes sociales y el segundo grupo es el que sí usa redes sociales.} \end{tabular} \end{table}") nomtitles



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


* Estadísticas por sat
local varlist fel SNU avg_d_mbps edad remoto ingresos estudios capital
matrix C = J(8,4,0)
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
	
	local i = `i' + 1
}

matrix colnames C = SAT1 SAT2 SAT3 SAT4
matrix rownames C = `varlist'

esttab matrix(C) using "EstporSAT.tex", replace title(Estadísticas por Nivel de Satistacción) postfoot("\label{EstporSAT} \floatfoot{Nota: Se presentan las medias de las principales variables de interés por nivel de Satisfacción.} \end{tabular} \end{table}") nomtitles


* Prueba de diferencia de medias por capital
local varlist fel sat avg_d_mbps edad remoto ingresos estudios SNU
matrix D = J(8,5,0)
local i=1
foreach var of local varlist {
    quietly ttest `var', by(capital)	
		 
	matrix D[`i',1] = round(r(mu_1), 0.001)
	matrix D[`i',2] = round(r(mu_2), 0.001)
	matrix D[`i',3] = round(r(sd_1), 0.001)
	matrix D[`i',4] = round(r(sd_2), 0.001)
	matrix D[`i',5] = round(r(p),0.001)
	
	local i = `i' + 1
}

matrix colnames D = No_Capital Capital sd_1 sd_2  P-Value
matrix rownames D = `varlist'

esttab matrix(D) using "Medias_Cap.tex", replace title(Análisis de Diferencia de Medias - por Capital) postfoot("\label{MediasCap} \floatfoot{Nota: Se presentan las medias y desvíos estándar junto con el p-valor para la prueba de diferencia de medias, para las principales variables de interés dónde el primer grupo es el que no vive en una ciudad capital o de más de 100.000 habitantes y el segundo grupo es el que sí.} \end{tabular} \end{table}") nomtitles



* Lista de códigos numéricos de países
local codigos 32 68 76 170 188 152 218 222 320 340 484 558 591 600 604 214 858 862
local nombres Argentina Bolivia "Brasil" "Colombia" "Costa_Rica" "Chile" "Ecuador" "El_Salvador" "Guatemala" "Honduras" "Mexico" "Nicaragua" "Panama" "Paraguay" "Peru" "R_Dominicana" "Uruguay" "Venezuela"

* PAIS
matrix E = J(18,8,0)
local i = 1
foreach codigo in `codigos' {
        
	quietly sum sat if idenpa == `codigo'
	matrix E[`i',1] = round(r(mean), 0.01)
	
	quietly sum fel if idenpa == `codigo'
	matrix E[`i',2] = round(r(mean), 0.01)
	
	quietly sum SNU if idenpa == `codigo'
	matrix E[`i',3] = round(r(mean), 0.01)
	
	quietly sum avg_d_mbps if idenpa == `codigo'
	matrix E[`i',4] = round(r(mean), 0.01)
	
	quietly sum edad if idenpa == `codigo'
	matrix E[`i',5] = round(r(mean), 0.01)
	
	quietly sum remoto if idenpa == `codigo'
	matrix E[`i',6] = round(r(mean), 0.01)
	
	quietly sum estudios if idenpa == `codigo'
	matrix E[`i',7] = round(r(mean), 0.01)
	
	quietly sum ingresos if idenpa == `codigo'
	matrix E[`i',8] = round(r(mean), 0.01)
    
    local i = `i' + 1
}

matrix colnames E = sat fel SNU avg_d_mbps edad remoto estudios ingresos
matrix rownames E = `nombres'
esttab matrix(E) using "Est_por_Pais.tex", replace title(Media de variables por País) postfoot("\label{MediasporPais} \floatfoot{Nota: Se presentan las medias de las principales variables de interés para cada uno de los países de la muestra.} \end{tabular} \end{table}") nomtitles



 forvalues i = 1(1)5 {
gen in
}


* Regresión lineal MCO
* reg sat SNU p78n edad [pw=wt], robust (No es necesario ponderar la muestra)
reg sat SNU ingresos estudios edad, robust

* IV
ivreg2 sat ingresos estudios edad capital (SNU=avg_d_mbps), robust first

* Estimación con IV y Test de Kleibergen-Paap para Velocidad de Internet como IV de SNU en Satisfacción
quietly ivreg2 sat p78n edad (SNU=avg_d_kbps), robust first

* Chequeo Velocidad de Internet como IV de SNU para Felicidad

* Estimación con IV y Test de Kleibergen-Paap
quietly ivreg2 fel SNU p78n edad (SNU=avg_d_kbps), robust first
outreg2 using "c:\data\F.tex", tex(frag) ctitle("ivreg2") replace

* Lista de códigos numéricos de países
local codigos 32 68 76 170 188 152 218 222 320  484 558 591 600 604 214 858 862
local nombres Argentina Bolivia "Brasil" "Colombia" "Costa_Rica" "Chile" "Ecuador" "El_Salvador" "Guatemala"  "Mexico" "Nicaragua" "Panama" "Paraguay" "Peru" "R_Dominicana" "Uruguay" "Venezuela"

* PAIS
matrix G = J(17,4,0)
local i = 1
foreach codigo in `codigos' {
    	quietly reg sat SNU edad remoto estudios ingresos if idenpa == `codigo', robust
		matrix b = e(b)
		matrix G[`i',1] = round(b[1,1], 0.001)
		quietly ivreg2 sat edad remoto estudios ingresos (SNU=avg_d_kbps) if idenpa == `codigo', robust
		matrix b = e(b)
		matrix G[`i',2] = round(b[1,1], 0.001)
		matrix G[`i',3] = round(e(N), 0.1)
		matrix G[`i',4] = round(e(widstat), 0.01)
		
		
	
    
	
    local i = `i' + 1
}

matrix colnames G = Beta Beta_IV N KP 
matrix rownames G = `nombres'
esttab matrix(G) using "B_por_Pais.tex", replace title(IV REG por País) postfoot("\label{IVREGporPais} \floatfoot{Nota: Se presentan el Beta de la relación causal de interés en las estimaciones por país. Se excluye a Honduras de la muestra por colinealidad.} \end{tabular} \end{table}") nomtitles

