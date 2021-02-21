(clear-all)

(define-model confused-lost-player

(sgp 	:egs 0.2)  ; this model uses utility, you might want to disable noise by setting this parameter to 0
(sgp 	:esc t)    ; or change this to nil
(sgp 	:v t 
		:show-focus t 
		:visual-num-finsts 10 
		:trace-detail high)

(chunk-type goal agendColor state intention searching goalX1 goalX2 goalY1 goalY2 dimension-lx dimension-rx dimension-ly dimension-ry) 
(chunk-type control intention button)
(chunk-type counter actual-count)				;Punktestand			;Positionen
(chunk-type whoAmI color visual-range screen-x screen-y)	;Agent 
(chunk-type object type color)				;Bloecke


(add-dm
    (observe)
    (start-action)
	(call-for-action)
	; -------------------- Agent finden
	(lost)(found)(compare-locs)(LEFT_LINE)(TOP_LINE)
	(track-agend)(attend-agend)
	(moved)(attend)
	(find_oval)
	(remember_pos)
	; -------------------- Mitte suchen
		(aligned-center)(walk-to-target)(TRUE)(FALSE)(centered-Y)
	(approach-center) (approach-bottom)	;Auswahl der Heuristik
	; -------------------- Route ablaufen
		(observe-target)(goto-target)(ALIGNED-CENTERED)(CATCHED)(STOPPED)(MOVED-DOWN)(FINISH)
		(target-visible)(target-nonvisible) 
	; -------------------- Controlls
	(move-left) (move-right)
    (move-up)  (move-down)
    (w) (a) (s) (d)
    (up-control isa control intention move-up button w)
    (down-control isa control intention move-down button s)
    (left-control isa control intention move-left button a)
    (right-control isa control intention move-right button d)
	; -------------------- Sonstige
	(obstacle-object)(plus-object)(minus-object)(target-object)		;Objekte
	(agent isa whoAmI) ;placeholder
    (first-goal isa goal state nil goalX1 nil goalX2 nil goalY1 nil goalY2 nil)
)

(goal-focus first-goal)
; --------------------  Feld einlesen
(p analyze_field_left
	=goal>
		state			nil
	?visual-location>
		state			free
==>
	=goal>			
		state			left_line
	+visual-location>
		kind			line
		color			yellow
		screen-x		lowest
		width			0
		:attended		nil
)
(p analyze_field__top
	=goal>
		state			left_line
	=visual-location>
	?retrieval>
		state			free
==>
	=goal>			
		state			top_line
	+visual-location>
		kind			line
		color			yellow
		height			0
		screen-y		lowest
		:attended		nil
	+retrieval>
		kind			line
		color			yellow
		width			0
)		
 
(p analyze_field_size
	=goal>
		state			top_line
	=retrieval>
		screen-x		=lowX
		height			=height
	=visual-location>
		screen-y		=lowY
		width			=width
	?imaginal>
		state free
		buffer empty
==>
	!bind! =X (+ =lowX 12)
	!bind! =Y (+ =lowY 12)
	!bind! =X1 (-(+(* (- (round (/ =width 25) 2) 1) 25) =X) 25)
	!bind! =X2 (-(+(* (+ (round (/ =width 25) 2) 1) 25) =X) 25)
	!bind! =Y1 (-(+(* (round (/ =height 25) 2) 25) =Y) 25)
	!bind! =Y2 (-(+(* (+ (round (/ =height 25) 2) 1) 25) =Y) 25)
	!bind! =rX  (- (+ =X =width) 25)
	!bind! =rY  (- (+ =Y =height) 25)
	=goal>			
		state			find_oval
		goalX1			=X1
		goalX2			=X2
		goalY1			=Y1
		goalY2			=Y2
		dimension-lx	=X
		dimension-rx	=rX
		dimension-ly	=Y
		dimension-ry	=rY
)


; -------------------- 	Agent suchen
(p attend_oval_left
	=goal>
		state 		find_oval
	?manual>
		state 		free
==>
	=goal>
		state 		attend
	+manual>
        cmd 		press-key
        key 		a
)
(p attend_oval_right
	=goal>
		state 		find_oval
	?manual>
		state 		free
==>
	=goal>
		state 		attend
	+manual>
        cmd 		press-key
        key 		d
)

(p scene-change
	=goal>
		state	attend
	?manual>
		state	free
	?visual>
		scene-change nil
==>
	=goal>
		state		find_oval
)

; -------------------- warten bis die Eingabe erfolgt ist
; -------------------- TODO: Allgemeiner Pfad noch vebessern -Produktion compare-unsuccsesfull feuert sehr häufig
(p change
	=goal>
		state 		attend	
==>
	=goal>
		state 		remember_pos
	+visual-location>
		ISA			visual-location
		kind 		oval
		screen-y	lowest
		:attended 	nil 
)

(p find-change
	=goal>
		state 		remember_pos
	?manual>
		state 		free
	=visual-location>
==>
	=goal>
		state moved
	+visual-location>
		ISA			visual-location
		kind 		oval
		screen-y	lowest
		:attended 	nil 
)

(p find-locations
	=goal>
		state 		moved
	?retrieval>
		state 		free
==>
	=goal>
		state compare-locs
	+retrieval>
		ISA 		visual-location
		kind 		oval
		height		25
		width		25
)
; -------------------- Erkenne Anderung bei screen-x 
(p compare-locations
	=goal>
		state 		compare-locs
	=visual-location>
		screen-x	=xWert
		screen-y	=yWert
		color		=agentColor
	=retrieval>
		-	screen-x	=xWert
		screen-y	=yWert
		color		=agentColor
	?imaginal>
		state free
==>
	+imaginal>
		Isa whoAmI
		screen-x	=xWert
		screen-y	=yWert	
		color		=agentColor
	=goal>
		state 		attend-agend
		agendColor	=agentColor
)

(p compare-unsuccsesfull
	=goal>
		state		compare-locs
	=visual-location>
		kind		oval
		color 		=currentColor
		screen-x	=wert1
		screen-y	=wert2
	?retrieval>
		state free
==>
	+visual-location>
		ISA			visual-location
		kind 		oval
	 -  color		=currentColor
	 -	screen-x	=wert1
		screen-y	=wert2	 
		:attended 	nil
)

(p attend-agend
	=goal>
		state 		attend-agend
	?visual>
		state free
	=imaginal>
		screen-x	=xWert
		screen-y	=yWert
==>
	+visual>
		cmd 		move-attention
		screen-pos 	=imaginal
	=goal>
		state 		track-agend
)
; -------------------- Tracking
(p tracking-agend
	=goal>
		state 		track-agend
		searching	nil
		agendColor	=agendColor
	?visual>
		buffer 		full
	?visual-location>
		state 		free
==>
	=goal>
	state			walk-to-target
	searching		true
	intention		down
	+visual>
		cmd 		start-tracking
	+visual-location>
		kind		oval
		color 	=agendColor
)
; -------------------- Weg ablaufen nachdem Mitte erkannt wurde
(p initialize-walking-down
	=goal>
		state		walk-to-target
		searching	false
==>
	=goal>
		intention	down
		searching	true
)

(p walk-down
	=goal>
		state		walk-to-target
		searching	false
		intention	down
		agendColor	=agendColor
	?manual>
		state		free	
	?visual-location>
		state		free		
==>
	+manual>
		cmd			press-key
		key			s	
	+visual-location>
		kind		oval
		color		=agendColor
	=goal>
		searching	true

)

(p stop-walking-down
	=goal>
		state		walk-to-target
		goalY1		=Y1
		agendColor	=agendColor
	=visual-location>
	>=	screen-y	=Y1
		kind		oval
		color		=agendColor
==>
	=goal>
		state		centered-Y
	+visual-location>
		kind		oval
		color		=agendColor
		
)

(p walk-sideways-left
	=goal>
		state		centered-Y ; Können wir auch in centered schreiben sodass X und Y Bewegung flexibel
		goalX2		=X2
		searching	false
	=visual-location>
	>	screen-X	=X2
		kind		oval
	?manual>
		state		free
==>
	+manual>
		cmd			press-key
		key			a
	=goal>
		state		centered-Y
		intention	left
		searching	true
)

(p walk-sideways-right
	=goal>
		state		centered-Y ; Können wir auch in centered schreiben sodass X und Y Bewegung flexibel
		goalX1		=X1
		searching	false
	=visual-location>
	<	screen-X	=X1
		kind		oval
	?manual>
		state		free
==>
	+manual>
		cmd			press-key
		key			d
	=goal>
		state		centered-Y
		intention	right
		searching	true
)

(p stop-walking-sideways
	=goal>
		state		centered-Y
		goalX1		=X1
		goalX2		=X2
	=visual-location>
	>=	screen-X	=X1
	<=	screen-X    =X2
		kind		oval
		;:attended	t
==>
		!bind! =X 	(+ =X1 25)
	=goal>
		state		aligned-centered
		searching	true
		goalX1		=X
		goalY1		nil
)

; -------------------- Explorationsroute
(p initialize-intention-left
	=goal>
		state		aligned-centered
		goalX1		=X1
	=visual-location>
		kind		oval
	>	screen-X	=X1	
		- color		green
	
==>
	=goal>
		state		initialized
		intention	left
		goalX1		nil
		searching	true

)
(p initialize-intention-right
	=goal>
		state		aligned-centered
		goalX1		=X1
	=visual-location>
		kind		oval
	<=	screen-X	=X1	
		- color		green
==>
	=goal>
		state		initialized
		intention	right
		goalX1		nil
		searching	true
)
(p move-along-left
	=goal>
		state		initialized
		intention	left
		searching	false
	?manual>
		state		free	
	?visual-location>
		state		free
	
==>
	+manual>
		cmd			press-key
		key			a
	+visual-location>
		kind		oval
		:attended	t
	=goal>
		searching	true
		intention	left
)


(p walking-down_fromcenter
	=goal>
		state		stopped
	?manual>
		state 	free
==>
	+manual>
		cmd	press-key
		key	s
	=goal>
		state		moved-down
		searching	true
)

(p change-direction-right-to-left
	=goal>
		state 		moved-down
		intention	right
	?manual>
		state 	free
==>
	=goal>
		state 		initialized
		intention	left
)
(p change-direction-left-to-right
	=goal>
		state 		moved-down
		intention	left
	?manual>
		state 	free
==>
	=goal>
		state 		initialized
		intention	right
)

(p move-along-right
	=goal>
		state		initialized
		intention	right
		searching	false
	?manual>
		state		free
	?visual-location>
		state		free
==>
	=goal>
		searching	true
	+manual>
		cmd			press-key
		key			d
	+visual-location>
		kind		oval
		:attended	t
)
; --------------- Abbruch
(p stop-right-centered
	=goal>
		state		initialized
		intention	right
		dimension-rx =Wert1
	?manual>
		state 		free
	=visual-location>
		screen-X		=Wert1
==>
	=goal>
		state	stopped
)

(p stop-left-centered
	=goal>
		state		initialized
		intention	left
		dimension-lx =Wert1
	?manual>
		state 		free
	=visual-location>
		screen-X		=Wert1
==>
	=goal>
		state	stopped
		
)
;########## Zielerkennung gruen
(p find-green-target
	=goal>
		state		initialized
		searching	target
	?visual-location>
		state free
	?manual>
		execution	free
==>
	+visual-location>
		kind 		oval
		color   	green
	=goal>
		searching	target
)
(p find-green-target-again
	=goal>
		state		walk-to-target
		searching	target
	?visual-location>
		state free
	?manual>
		execution	free
==>
	+visual-location>
		kind 		oval
		color   	green
	=goal>
		searching	target
)
(p find-green-target-again-and-again
	=goal>
		state		centered-Y
		searching	target
	?visual-location>
		state free
	?manual>
		execution	free
==>
	+visual-location>
		kind 		oval
		color   	green
	=goal>
		searching	target
)

(p target-visible
	=goal>
	;	state		catched	
		searching	target
	=visual-location>
		ISA 		visual-location
		kind 		oval
		color   	green
		screen-X	=goalX-Wert
		screen-Y	=goalY-Wert
	?manual>
		execution	free
==>
	=goal>
		state 		walk-to-target
		goalX1		=goalX-Wert
		goalY1		=goalY-Wert
		searching	false
)
(p target-visible-again
	=goal>
		state		walk-to-target	
		searching	target
	=visual-location>
		ISA 		visual-location
		kind 		oval
		color   	green
		screen-X	=goalX-Wert
		screen-Y	=goalY-Wert
	?manual>
		execution	free
==>
	=goal>
		state 		walk-to-target
		goalX1		=goalX-Wert
		goalY1		=goalY-Wert
		searching	false
)
(p target-failure
	=goal>
		searching	target
	?visual-location>
		buffer	failure
==>
	=goal>
		searching	false
)

;########## Objekterkennung

(p find-relevant-obstacles-bottom
	=goal>
		searching	true	
		intention	down
		agendColor	=agendColor
	?visual-location>
		state free
	=visual-location>
		kind 		oval
		screen-X	=wert1
		screen-Y	=wert2
		color		=agendColor
	?manual>
		execution	free
		state		free
	?imaginal>
		state free
==>
	!bind! =down (+ =wert2	25) 
	+visual-location>
		kind 		oval
		- color   	green
		- color		=agendColor
		screen-X	=wert1
		screen-Y	=down
	=goal>
		searching	find-color
)
(p find-relevant-obstacles-left
	=goal>
		searching	true	
		intention	left
		agendColor	=agendColor
	?visual-location>
		state free
	=visual-location>
		kind 		oval
		screen-X	=wert1
		screen-Y	=wert2
		
	?manual>
		execution	free
==>
	!bind! =left (- =wert1	25)
	+visual-location>
		kind 		oval
		- color   	green
		- color		=agendColor
		screen-X	=left
		screen-Y	=wert2
	=goal>
		searching	find-color
)
(p find-relevant-obstacles-right
	=goal>
		searching	true	
		intention	right
		agendColor	=agendColor
	?visual-location>
		state free
	=visual-location>
		kind 		oval
		screen-X	=wert1
		screen-Y	=wert2
		
	?manual>
		execution	free
==>
	!bind! =right (+ =wert1	25)
	+visual-location>
		kind 		oval
		- color   	green
		- color		=agendColor
		screen-X	=right
		screen-Y	=wert2
	=goal>
		searching	find-color
)
; ----------------
(p find-color-object
	=goal>
		searching	find-color
		agendColor	=Agendcolor
	=visual-location>
		kind 		oval
		color		=color
	  - color		=AgendColor
	?retrieval>
		state 	free
		buffer	empty
	?imaginal>
	 state	free
	?manual>
		execution	free
==>
	+retrieval>
		isa		object
		color	=color
		- type	nil
	=visual-location>
)

(p extract-color
	=goal>
		searching	find-color
	=visual-location>
		kind	oval
		color	=color
	?retrieval>
		buffer	failure
	?imaginal>
		state	free
==>
	+imaginal>
		isa		object
		color	=color
		type	nil	
	=visual-location>
)
(p color-known-whatabout-the-type
	=goal>
		searching	find-color
	=retrieval>
		isa 	object
		- color	nil
		type nil
	=visual-location>
==>
	=goal>
		searching	running
	=retrieval>
	=visual-location>	
)
; ####### Objekt erlaufen

(p walk-against-object-down
	=goal>
		intention	down
		searching	running
	=visual-location>
	=imaginal>
	?manual>
		state	free
==>
	+manual>
		cmd			press-key
		key			s	
	=goal>
		searching	check
	=imaginal>
	
)
(p walk-against-object-left
	=goal>
		intention	left
		searching	running
	=visual-location>
	=imaginal>
	?manual>
		state	free
==>
	+manual>
		cmd			press-key
		key			a	
	=goal>
		searching	check
	=imaginal>
	
)
(p walk-against-object-right
	=goal>
		intention	right
		searching	running
	=visual-location>
	=imaginal>
	?manual>
		state	free
==>
	+manual>
		cmd			press-key
		key			d	
	=goal>
		searching	check
	=imaginal>
)

(p supervised-color-negative
	=goal>
		searching	check
	=visual-location>
		color		=oldColor
	=imaginal>
		color		=oldColor
	?manual>
		execution	free
		state		free ;möglich ohne?
		
==>
	+imaginal>
		type	negative
		color	=oldColor
	-imaginal>
	=goal>
		searching	true
)
(p supervised-color-positive
	=goal>
		searching	check
	=visual-location>
		- color		=oldColor
	=imaginal>
		 color		=oldColor
	?manual>
		execution	free
		state		free ;möglich ohne?
		
==>
	+imaginal>
		type	positive
		color	=oldColor
	=goal>
		searching	true
)
(p object-known-positive
	=goal>
		searching	deciding
	=retrieval>
		isa object
		color	=color
		type	positive
		
==>
	=goal>
		searching	target	
)
(p object-known-negative
	=goal>
		searching	deciding
	=retrieval>
		isa object
		color	=color
		type	negative
		
==>
	=goal>
		searching	avoid	
)



(p avoid-obstacle-down
	=goal>
		searching	avoid
		intention	down
	=visual-location>
		kind 		oval
		- color   	green
		
	?manual>
		state free
==>
	=goal>
		searching		target
	+manual>
		cmd 	press-key
		key		d
)
(p avoid-obstacle-left
	=goal>
		searching	avoid
		intention	left
	=visual-location>
		kind 		oval
		- color   	green
		
	?manual>
		state free
==>
	=goal>
		searching		target
	+manual>
		cmd 	press-key
		key		s
)
(p avoid-obstacle-right
	=goal>
		searching	avoid
		intention	right
	=visual-location>
		kind 		oval
		- color   	green
		
	?manual>
		state free
==>
	=goal>
		searching		target
	+manual>
		cmd 	press-key
		key		s
)
(p	avoid-obstacle-failure
	=goal>
		searching	deciding
	?visual-location>
		buffer	failure
==>
	=goal>
		searching	target
)




; -------------------- Old Stuff
(p move
    =retrieval>
        button 		=button
    ?manual>
        state 		free
==>
    +manual>
        cmd 		press-key
        key 		=button
)

(p retrieval-failure
    =goal>
        state 		observe
    ?retrieval>
        buffer 		failure
==>
    =goal>
        state 		lost
)

(p maybe-down
    =goal>
        state 		call-for-action
    ?manual>
        state 		free
==>
    =goal>
        state 		start-action
        intention 	move-down
)

(spp stop-left-centered :u 10)
(spp stop-right-centered :u 10)
(spp compare-locations :u 10)
;(spp scene-change :u 10)

;(spp find-green-target :u 100)
;(spp target-visible :u 100)

)