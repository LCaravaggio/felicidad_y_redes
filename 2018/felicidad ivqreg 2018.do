* Felicidad IVQREG
* INICIO
clear all
cscript

* qui do ivqreg.mata

set more off
set seed 12345

cd C:\Users\lcaravaggio_mecon\Desktop\Doctorado\felicidad_ivqreg2\2018
use LB2018


* Elimino las no respuestas de satisfacción con la vida, smartphone ownership, nivel de estudios, y si posee agua caliente de cañería
keep if p1st>0

gen s12=0
replace s12=1 if s12m_a==1
replace s12=1 if s12m_b==1
replace s12=1 if s12m_c==1
replace s12=1 if s12m_d==1
replace s12=1 if s12m_e==1
replace s12=1 if s12m_f==1
replace s12=1 if s12m_g==1
replace s12=1 if s12m_h==1
replace s12=1 if s12m_i==1

*Generar variable SNU (Social Network Use)
generate SNU = 0
replace SNU = 1 if s12m_j==0

gen sat=0
replace sat=1 if p1st==4
replace sat=2 if p1st==3
replace sat=3 if p1st==2
replace sat=4 if p1st==1

gen ingresos=0
replace ingresos=1 if s1==4
replace ingresos=2 if s1==3
replace ingresos=3 if s1==2
replace ingresos=4 if s1==1

gen capital=0
replace capital =1 if tamciud==8
replace capital =1 if tamciud==7

gen estudios = s10

*histogram sat, discrete normal kdensity plotregion(fcolor(white) style(none) color(gs16)) graphregion(fcolor(white))
*graph export "Graph2.png", as(png) name("Graph") replace

merge m:1 city using "ciudades_latlon_2018.dta" 


gen lavg_d_mbps=log(avg_d_kbps/1024)


* Regresión lineal MCO
* reg sat SNU p78n edad [pw=wt], robust (No es necesario ponderar la muestra)
quietly reg sat SNU ingresos edad , robust
estimates store A
outreg2 using "Irrestricto 2018.tex", tex(frag) ctitle("MCO") replace fmt(fc) dec(3)  nor2

*First Stage
quietly reg SNU lavg_d_mbps ingresos edad , robust
estimates store B
outreg2 using "Irrestricto 2018.tex", tex(frag) ctitle("FS") append fmt(fc) dec(3)  nor2

* IV
quietly ivreg2 sat ingresos edad  (SNU=lavg_d_mbps) , robust first
estimates store C
outreg2 using "Irrestricto 2018.tex", tex(frag) ctitle("IV") append fmt(fc) dec(3) nor2

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

