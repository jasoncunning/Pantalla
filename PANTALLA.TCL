#!/usr/bin/wish
# pantalla.tcl

#### procedures ####

proc pan:MeterLasFrases {filename} {
    global frases

    catch {unset frases}

    if [catch {open $filename r} fileID] {
	error "Cannot read $filename: $fileID"
    } else {
	set indice 0
	while {[gets $fileID entry] >= 0} {
	    set frases($indice,palabra) [lindex $entry 0]
	    set frases($indice,frase) [lindex $entry 1]
	    set frases($indice,rank) $indice
	    incr indice 
	}
	close $fileID
	set frases(numero) $indice
    }
}

proc pan:FileNuevo {} {
    global pan

    set fileNuevo [tk_getOpenFile]
    if {![string equal {} $fileNuevo]} {

	if {$pan(enMarcha)} {
	    pan:DetenerPantalla
	}

	set pan(file) $fileNuevo
	set pan(fileMarcado) $pan(file)
	pan:MeterLasFrases $pan(file)
	set pan(modo) original
	set pan(encargadaConFrases) 1
	set pan(indiceDisp) {}
	set pan(indiceTBDisp) {}
	set pan(indiceMarcado) {}
    }
}

proc pan:HacerRandomRank {} {
    global frases

    
    set randomNumberList {}
    for {set indice 0} {$indice < $frases(numero)} {incr indice} {
	set uniqueRN 0
	while {!$uniqueRN} {
	    set randomNumber [expr rand()]
	    if {[lsearch -exact $randomNumberList $randomNumber] == -1} {
		set uniqueRN 1
		lappend randomNumberList $randomNumber
		set frases($indice,rank) $randomNumber
	    }
	}
    }
}

proc pan:HacerOriginalRank {} {
    global frases

    
    for {set indice 0} {$indice < $frases(numero)} {incr indice} {
		set frases($indice,rank) $indice
    }
}

proc pan:ElegirProximoRank {{indiceCorriente {}}} {
    global frases

    if {![string equal {} $indiceCorriente]} {
	for {set indice 0} {$indice < $frases(numero)} {incr indice} {

	    if {$frases($indice,rank) > $frases($indiceCorriente,rank)} {
		# initialize indiceMasPequeno
		if {![info exists indiceMasPequeno]} {
		    set indiceMasPequeno $indice
		}
		if {$frases($indice,rank) < $frases($indiceMasPequeno,rank)} {
		    set indiceMasPequeno $indice
		}
	    }

	}
	if {[info exists indiceMasPequeno]} {return $indiceMasPequeno}
    }

    # either largest rank is at indiceCorriente or indiceCorriente
    # was not specified, either way, hay que empezar de nuevo--
    # find the smallest rank

    set indiceMasPequeno 0
    for {set indice 0} {$indice < $frases(numero)} {incr indice} {
	if {$frases($indice,rank) < $frases($indiceMasPequeno,rank)} {
	    set indiceMasPequeno $indice
	}
    }
    return $indiceMasPequeno

}

proc pan:ElegirUltimoRank {{indiceCorriente {}}} {
    global frases

    if {![string equal {} $indiceCorriente]} {
	for {set indice 0} {$indice < $frases(numero)} {incr indice} {

	    if {$frases($indice,rank) < $frases($indiceCorriente,rank)} {
		# initialize indiceMasGrande
		if {![info exists indiceMasGrande]} {
		    set indiceMasGrande $indice
		}
		if {$frases($indice,rank) > $frases($indiceMasGrande,rank)} {
		    set indiceMasGrande $indice
		}
	    }

	}
	if {[info exists indiceMasGrande]} {return $indiceMasGrande}
    }

    # either smallest rank is at indiceCorriente or indiceCorriente
    # was not specified, either way, hay que empezar de nuevo--
    # find the largest rank

    set indiceMasGrande 0
    for {set indice 0} {$indice < $frases(numero)} {incr indice} {
	if {$frases($indice,rank) > $frases($indiceMasGrande,rank)} {
	    set indiceMasGrande $indice
	}
    }
    return $indiceMasGrande

}

proc pan:CambiarPantalla {indice} {
    global frases pan

    $pan(palabra) configure -text $frases($indice,palabra)

    $pan(frase) configure -state normal
    $pan(frase) delete 0.0 end
    $pan(frase) insert end $frases($indice,frase)
    $pan(frase) configure -state disabled

    update
}

proc pan:CambiarDeModo {} {
    global pan

    if {!$pan(encargadaConFrases)} {return}

    set pantallaEstuvoEnMarcha 0
    if {$pan(enMarcha)} {
	pan:DetenerPantalla
	set pantallaEstuvoEnMarcha 1
    }

    if {[string equal $pan(modo) random]} {
	pan:HacerRandomRank
    } else {
	pan:HacerOriginalRank
    }

    if {$pantallaEstuvoEnMarcha} {
	pan:PonerPantallaEnMarcha
    }
}

proc pan:PonerPantallaEnMarcha {} {
    global pan

    # ponla en marcha
    pan:CambiarPantalla $pan(indiceTBDisp)
    set pan(indiceDisp) $pan(indiceTBDisp)
    set pan(indiceMarcado) $pan(indiceDisp)

    set pan(enMarcha) 1
    while {$pan(enMarcha)} {

	set pan(indiceTBDisp) [pan:ElegirProximoRank $pan(indiceDisp)]

	set pan(mandatoID) \
	    [after $pan(plazo) [list eval {
		pan:CambiarPantalla $pan(indiceTBDisp)
		set pan(indiceDisp) $pan(indiceTBDisp)
		set pan(indiceMarcado) $pan(indiceDisp)
		set pan(cambiado) {}}]]

	vwait pan(cambiado)

    }

}


proc pan:DetenerPantalla {} {
    global pan

    if {$pan(enMarcha)} {
	# matar el mandato que habria cambiado pantalla
	after cancel $pan(mandatoID)
	# set enMarcha 0 to bust out of while loop in pan:PonerPantallaEnMarcha
	set pan(enMarcha) 0
	# set cambiado to end vwait in while loop in pan:PonerPantallaEnMarcha
	set pan(cambiado) {}
    }
}

proc pan:PreviousNextEnMarcha {cual} {
    global pan frases

    if {!$pan(encargadaConFrases)} {return}
    if {$pan(enMarcha)} {pan:DetenerPantalla}

    # assure buen indice
    if {![regexp {^\d+$} $pan(indiceMarcado)] || \
	    $pan(indiceMarcado) >= $frases(numero)} {

	# es malo
	switch $cual {
	    previous {set pan(indiceTBDisp) [pan:ElegirUltimoRank]}
	    next {set pan(indiceTBDisp) [pan:ElegirProximoRank]}
	    enMarcha {set pan(indiceTBDisp) [pan:ElegirProximoRank]}
	}

    } else {

	# es bueno
	switch $cual {
	    previous {set pan(indiceTBDisp) [pan:ElegirUltimoRank $pan(indiceMarcado)]}
	    next {set pan(indiceTBDisp) [pan:ElegirProximoRank $pan(indiceMarcado)]}
	    enMarcha {set pan(indiceTBDisp) $pan(indiceMarcado)}
	}

    }

    if {![string equal enMarcha $cual]} {

	pan:CambiarPantalla $pan(indiceTBDisp)
	set pan(indiceDisp) $pan(indiceTBDisp)
	set pan(indiceMarcado) $pan(indiceDisp)

    } else {

	# assure buen plazo, only enMarcha cares
	if {![regexp {^\d+$} $pan(plazoMarcado)]} {
	    set pan(plazo) $pan(defaultPlazo)
	    set pan(plazoMarcado) $pan(plazo)
	} else {
	    set pan(plazo) $pan(plazoMarcado)
	}

	# if frase at indiceTBDisp is already displayed, advance to the next one, note
	# pan(indiceDisp) is not necessarily set...
	if {[string equal $pan(indiceTBDisp) $pan(indiceDisp)]} {
	    set pan(indiceTBDisp) [pan:ElegirProximoRank $pan(indiceDisp)]
	}

	pan:PonerPantallaEnMarcha

    }
}

proc pan:nuevoIndice {} {
    global pan frases

    if {!$pan(encargadaConFrases)} {return}

    # assure buen indice
    if {![regexp {^\d+$} $pan(indiceMarcado)] || \
	    $pan(indiceMarcado) >= $frases(numero)} {
	return
    } else {
	if {$pan(enMarcha)} {pan:DetenerPantalla}
	set pan(indiceTBDisp) $pan(indiceMarcado)
	pan:CambiarPantalla $pan(indiceTBDisp)
	set pan(indiceDisp) $pan(indiceTBDisp)
    }
}

proc pan:nuevoPlazo {} {
    global pan

    if {!$pan(encargadaConFrases)} {return}
    if {!$pan(enMarcha)} {return}

    # assure buen plazo, only enMarcha cares
    if {![regexp {^\d+$} $pan(plazoMarcado)]} {
	set pan(plazo) $pan(defaultPlazo)
	set pan(plazoMarcado) $pan(plazo)
    } else {
	set pan(plazo) $pan(plazoMarcado)
    }
}

proc pan:Control {} {
    global pan

    if {![winfo exists .control]} {

	toplevel .control
	wm title .control "Control De Pantalla"

	# file frame
	set file [frame .control.file]
	label $file.lb -text File:
	entry $file.en -textvariable pan(fileMarcado)
	button $file.bn -text Browse -command pan:FileNuevo

	pack $file.lb -padx 2 -pady 2 -side left -anchor w
	pack $file.en -pady 2 -side left -expand true -fill x
	pack $file.bn -padx 2 -pady 2 -side left -anchor e

	# enMarcha frame
	set enMarcha [frame .control.enMarcha]

	set modo [frame $enMarcha.m]
	label $modo.lb -text "Modo cuando en marcha"
	radiobutton $modo.random -variable pan(modo) -text Random -value random \
	    -command pan:CambiarDeModo
	radiobutton $modo.original -variable pan(modo) -text Original -value original \
	    -command pan:CambiarDeModo

	pack $modo.lb -pady 2 -padx 2 -expand true
	pack $modo.random $modo.original -pady 2 -padx 2 -side left -expand true

	set indicePlazo [frame $enMarcha.indicePlazo]
	label $indicePlazo.ilb -text "Marcar el indice:"
	entry $indicePlazo.ien -textvariable pan(indiceMarcado)
	label $indicePlazo.plb -text "Marcar el plazo de espera:"
	entry $indicePlazo.pen -textvariable pan(plazoMarcado)

	grid $indicePlazo.ilb $indicePlazo.ien
	grid $indicePlazo.plb $indicePlazo.pen
	grid $indicePlazo.ilb -sticky w
	grid $indicePlazo.ien -sticky news
 	grid $indicePlazo.plb -sticky w
	grid $indicePlazo.pen -sticky news

	pack $modo $indicePlazo -pady 2 -padx 2 -side left -expand true -fill x

	# controlBtns frame
	set controlBtns [frame .control.controlBtns]
	button $controlBtns.prev -text - -command "pan:PreviousNextEnMarcha previous"
	button $controlBtns.next -text + -command "pan:PreviousNextEnMarcha next"
	button $controlBtns.enMarcha -text >> -command "pan:PreviousNextEnMarcha enMarcha"
	button $controlBtns.detener -text {[ ]} -command pan:DetenerPantalla
	button $controlBtns.acp -text "Acabar Con Pantalla" -command exit

	pack $controlBtns.prev $controlBtns.next $controlBtns.enMarcha $controlBtns.detener \
	    $controlBtns.acp -side left -expand true -fill x

	# packing of main control frames...
	pack $file $enMarcha -expand true -fill x
	pack $controlBtns -expand true -fill x -anchor s

	# bindings
	bind $indicePlazo.ien <Return> pan:nuevoIndice
	bind $indicePlazo.pen <Return> pan:nuevoPlazo

    }
}

#### Main ####

# initialize...

set pan(control) 0
set pan(enMarcha) 0
set pan(encargadaConFrases) 0
set pan(indice) {}
set pan(defaultPlazo) 20000
set pan(plazo) $pan(defaultPlazo)
set pan(plazoMarcado) $pan(plazo)

option add *background #0088cc
option add *Entry.background cyan
option add *Text.background cyan
option add *Button.foreground black
option add *Button.activeBackground #0088cc
option add *Button.activeForeground green

set seed [clock format [clock seconds] -format %S%M%H]
regsub {^0} $seed {} seed
expr srand($seed)

# main gui construction

wm title . "La Pantalla"
. configure -height 36
. configure -width 560
. configure -background #0088cc

set pan(palabra) [label .palabra -text {    }]
set pan(frase) [text .frase -relief raised]
$pan(frase) configure -state disabled

pack $pan(palabra) -side left -anchor w
pack $pan(frase) -side left -expand true -fill x
pack propagate . false

# bindings
bind . <ButtonRelease-1> pan:Control

