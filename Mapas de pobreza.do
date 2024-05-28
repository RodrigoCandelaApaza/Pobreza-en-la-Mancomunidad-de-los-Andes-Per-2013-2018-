*==========
* MAPAS
*==========
clear

cd "C:\Users\LENOVO\OneDrive\Escritorio\Mapas pobreza"

global main 		"C:\Users\LENOVO\OneDrive\Escritorio\Mapas pobreza"
global data     	"$main/Datos"
global procesadas 	"$main/Procesadas"
global graf 		"$main/Gráficos"
global shp 			"$main/Shapes"

* Instalamos
*------------

ssc install shp2dta, replace
grmap, activate
ssc install spmap, replace   // Si no funciona spmap, usar grmap

*-----------------
* Jalamos la data
*-----------------

shp2dta using "$shp\distrital.shp", database(distritos) coordinates(coords_distritos) genid(id) genc(centro) replace

shp2dta using "$shp\departamental.shp", database(departamentos) coordinates(coords_departamentos) genid(id) genc(centro) replace

use coords_departamentos, clear
drop if _ID != 5 & _ID != 3 & _ID != 8 & _ID != 9 & _ID != 11 & _ID != 12
save "$data/coords_departamentos.dta", replace

*---------------
*Veamos la data
*--------------
use "$data/distritos", clear
br
rename Departamen Departamento
replace Departamento = "Apurímac" if substr(Departamento, 1, 3) == "Apu"
replace Departamento = "Junín" if substr(Departamento, 1, 3) == "Jun"
save "$data/distritos.dta", replace
// Vemos que es solo info cartográfica


*-------------------------------
* Importo la base en formato csv

import delimited using "$data/base_nueva.csv", delimiter(",") varnames(1) case(preserve) clear

save "$data/base.dta", replace

* Creo una base para 2013
preserve // guardo la base en la memoria para poder usarla después sin tener que importarla de nuevo
keep if Anio == 2013
save "$data/base2013.dta", replace
restore // restauro la base

* Creo una base para 2018
preserve
keep if Anio == 2018
save "$data/base2018.dta", replace
restore

*-------------------------------------------


*----------
* Merge
*----------

// Juntamos los shapefiles con la información de pobreza por departamento
use "$data/distritos.dta", clear
merge m:m Ubigeo using "$data/base2013.dta", nogen
generate numero = 1 if Departamento == "Ica"
replace numero = 2 if Departamento == "Huancavelica"
replace numero = 3 if Departamento == "Junín"
replace numero = 4 if Departamento == "Ayacucho"
replace numero = 5 if Departamento == "Apurímac"
replace numero = 6 if Departamento == "Cusco"
drop if Distrito == "Huancayo" & Provincia == "Huancayo"
save "$data/base_pobreza2013.dta", replace

use "$data/distritos.dta", clear
merge 1:m Ubigeo using "$data/base2018.dta", nogen
generate numero = 1 if Departamento == "Ica"
replace numero = 2 if Departamento == "Huancavelica"
replace numero = 3 if Departamento == "Junín"
replace numero = 4 if Departamento == "Ayacucho"
replace numero = 5 if Departamento == "Apurímac"
replace numero = 6 if Departamento == "Cusco"
save "$data/base_pobreza2018.dta", replace

// Ya tenemos un cuadro con una ubicación y una información para dibujar

*------------------
*Generando etiquetas
*-------------------
use "$data/base_pobreza2013.dta", clear

* Creando base de etiquetas: 
preserve
generate label = numero
keep id x_c y_c label
save "$data/Label2013.dta", replace
restore

use "$data/base_pobreza2018.dta", clear

* Creando base de etiquetas: 
preserve
generate label = numero
keep id x_c y_c label
save "$data/Label2018.dta", replace
restore

*-------
* Mapa 2013
*-------
use "$data/base_pobreza2013.dta", clear 
gen pobreza_red = round(pobreza, 0.1)

spmap pobreza_red using "$data/perucoord.dta", id(id) ocolor(Greys) fcolor(Blues2) ///
	clmethod(stdev) ///
	polygon(data(coords_departamentos.dta) ocolor(black)) ///
	title("Pobreza en la Mancomunidad de los Andes (nivel distrital)") ///
	subtitle("2013") ///
	legend (pos (1) title ("Porcentaje de pobreza", size(*0.5))) ///
	note("Fuente: INEI 2013")

graph export "$graf/mapa2013_azul_stdv.png", as(png) replace

*-------
* Mapa 2018
*-------
use "$data/base_pobreza2018.dta", clear
gen pobreza_red = round(pobreza, 0.1)

spmap pobreza_red using "$data/perucoord.dta", id(id) ocolor(Greys) fcolor(Blues2) ///
	clmethod(stdev) ///
	polygon(data(coords_departamentos.dta) ocolor(black)) ///
	title("Pobreza en la Mancomunidad de los Andes (nivel distrital)") ///
	subtitle("2018") ///
	legend (pos (1) title ("Porcentaje de pobreza", size(*0.5))) ///
	note("Fuente: INEI 2018")


graph export "$graf/mapa2018_azul_stdv.png", as(png) replace