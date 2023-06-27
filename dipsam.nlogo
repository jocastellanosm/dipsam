extensions [gis]

globals [
  period-duration
  dataset
  is-there-space-for-settlement
  prob-death-0-4
  prob-death-5-9
  prob-death-10-14
  prob-death-15-19
  prob-death-20-24
  prob-death-25-29
  prob-death-30-34
  prob-death-35-39
  prob-death-40-44
  prob-death-45-49
  prob-death-50-54
  prob-death-55-59
  prob-death-60-64
  prob-death-65-69
  prob-death-70-74
  prob-death-75-79
  total-fertility-rate
  total-births
  total-deaths
  patchs-available-for-new-settlement
  mean-individuals-by-household
  population
  number-of-households
  patches-with-empirical-occupation
]

patches-own [patch-occupation status is-ok-for-settlement is-too-close-to-other-stlmt]

turtles-own [agent-type role age age-expected-to-die number-of-children expected-number-of-children age-of-last-birth interpregnancy-interval-for-last-birth]

to setup

  clear-all

  show (word "paleodem-data="paleodem-data)

  (ifelse
    ;Jagua - Rodriguez
    paleodem-data = "jagua-rodriguez" [
      set prob-death-0-4  0.3301
      set prob-death-5-9 0.0880
      set prob-death-10-14 0.0225
      set prob-death-15-19 0.0559
      set prob-death-20-24 0.0592
      set prob-death-25-29 0.5248
      set prob-death-30-34 0.4000
      set prob-death-35-39 0.3333
      set prob-death-40-44 0.5217
      set prob-death-45-49 0.8182
      set prob-death-50-54 0.0000
      set prob-death-55-59 1.0000
      set prob-death-60-64 1.0000
      set prob-death-65-69 1.0000
      set prob-death-70-74 1.0000
      set prob-death-75-79 1.0000
      set total-fertility-rate 6.2
    ]
    ;Jagua con crecimiento del 2% - Rodriguez
    paleodem-data = "jagua-2p-rodriguez" [
      set prob-death-0-4  0.2268
      set prob-death-5-9 0.0583
      set prob-death-10-14 0.0159
      set prob-death-15-19 0.0432
      set prob-death-20-24 0.0451
      set prob-death-25-29 0.4762
      set prob-death-30-34 0.3636
      set prob-death-35-39 0.3117
      set prob-death-40-44 0.5283
      set prob-death-45-49 0.9200
      set prob-death-50-54 1.0000
      set prob-death-55-59 0.0000
      set prob-death-60-64 1.0000
      set prob-death-65-69 1.0000
      set prob-death-70-74 1.0000
      set prob-death-75-79 1.0000
      set total-fertility-rate 4.3
    ]
    ;Northern Ache Females - Chamberlain
    paleodem-data = "northern-ache-females-chamberlain" [
      set prob-death-0-4  0.27
      set prob-death-5-9 0.12
      set prob-death-10-14 0.05
      set prob-death-15-19 0.03
      set prob-death-20-24 0.06
      set prob-death-25-29 0.02
      set prob-death-30-34 0.07
      set prob-death-35-39 0.01
      set prob-death-40-44 0.07
      set prob-death-45-49 0.10
      set prob-death-50-54 0.05
      set prob-death-55-59 0.13
      set prob-death-60-64 0.19
      set prob-death-65-69 0.11
      set prob-death-70-74 0.45
      set prob-death-75-79 1.00
      set total-fertility-rate 4.0 ; valor asignado de forma 'aleatoria'
    ]
   )

  setup-world

  create-initial-households

  count-and-save-population

  count-and-save-number-of-households

  calculate-and-save-mean-individuals-by-household

  reset-ticks

end

to setup-world

  show (word "archeo-data="archeo-data)

  resize-world -1400 1400 -1000 1000

  (ifelse archeo-data = "san-agustin-isnos-formativo-1" [
    set period-duration 400
    set dataset gis:load-dataset "sig/ajustado/san_agustin_isnos_formativo_1.asc"
  ] archeo-data = "san-agustin-isnos-formativo-2" [
    set period-duration 300
    set dataset gis:load-dataset "sig/ajustado/san_agustin_isnos_formativo_2.asc"
  ] archeo-data = "san-agustin-isnos-formativo-3" [
    set period-duration 300
    set dataset gis:load-dataset "sig/ajustado/san_agustin_isnos_formativo_3.asc"
  ] archeo-data = "san-agustin-isnos-clasico-regional" [
    set period-duration 900
    set dataset gis:load-dataset "sig/ajustado/san_agustin_isnos_clasico_regional.asc"
  ] archeo-data = "san-agustin-isnos-reciente" [
    set period-duration 630
    set dataset gis:load-dataset "sig/ajustado/san_agustin_isnos_reciente.asc"
  ])

  gis:set-world-envelope gis:envelope-of dataset

  gis:apply-raster dataset patch-occupation

  ask patches [
    (
      ifelse patch-occupation = 0 [ ; Fuera de la zona de reconocimiento
        set status "out"
        set pcolor white
      ]
      patch-occupation = 1 [ ; Area sin ocupacion empirica
        set status "disabled"
        set pcolor brown
      ]
      patch-occupation = 2 [ ; Area con ocupacion empirica
        set status "enabled"
        set pcolor green
      ]
      [
        set status nobody ; Valor por defecto
        set pcolor white
      ]
    )
  ]

  set patches-with-empirical-occupation patches with [patch-occupation = 2]

  ask patches-with-empirical-occupation [

    ;valida si todos los parches en un radio dado tienen evidencia de ceramica
    ( ifelse (count other patches in-radius trash-scatter-radius with [ patch-occupation != 2  ] > 0) [
      set is-ok-for-settlement false
      set is-too-close-to-other-stlmt nobody
    ][
      set is-ok-for-settlement true
      set is-too-close-to-other-stlmt false
    ] )

  ]

  ask patches with [ patch-occupation != 2 ][
    set is-ok-for-settlement false
    set is-too-close-to-other-stlmt nobody
  ]

  set patchs-available-for-new-settlement count patches-with-empirical-occupation with [is-too-close-to-other-stlmt = false]

end



to create-initial-households

  set is-there-space-for-settlement true

  create-turtles initial-number-households [
    if (not is-there-space-for-settlement) [stop]

    let patch-available-for-settlement get-patch-available-for-settlement
    ifelse patch-available-for-settlement != nobody [

      move-to patch-available-for-settlement
      set agent-type "house" ; Tipo unidad domestica
      set role "household" ; Rol vivienda
      set color gray
      set size 1
      set shape "house"
      create-initial-household-individuals

    ] [
      set is-there-space-for-settlement false
      show (word "There is no more space for new settlements!")
    ]
  ]

end

to-report get-patch-available-for-settlement

  ; obtiene el parche si es adecuado para asentamiento (segun evidencia empirica y segun evidencia artificial) que no este cerca de otro asentamiento artificial
  let patch-available-for-settlement one-of patches-with-empirical-occupation with [is-too-close-to-other-stlmt = false]

  (ifelse ( patch-available-for-settlement != nobody ) [

    ask patch-available-for-settlement [

      ask patches in-radius trash-scatter-radius [
        set status "occupied" ; Area con ocupacion artificial
        set pcolor red
      ]

      ask patches in-radius (2 * trash-scatter-radius) with [is-ok-for-settlement = true] [

        count-and-save-patchs-available-for-new-settlement is-too-close-to-other-stlmt true
        set is-too-close-to-other-stlmt true

      ]

    ]
  ][
    set is-there-space-for-settlement false
  ])

  report patch-available-for-settlement

end

to-report check-if-other-stlmt-is-too-close [ patch-to-evaluate ]

  let result false

  ask patch-to-evaluate [

    ;valida si en un radio dado hay algun parche con evidencia de asentamiento artificial
    if (count other patches in-radius trash-scatter-radius with [status != "enabled"] > 0) [
      set result true
    ]

  ]

  report result

end


to count-and-save-patchs-available-for-new-settlement [ is-too-close-to-other-stlmt-actual is-too-close-to-other-stlmt-new ]
  if (is-too-close-to-other-stlmt-actual != nobody and is-too-close-to-other-stlmt-actual != is-too-close-to-other-stlmt-new) [
    (ifelse (is-too-close-to-other-stlmt-actual = false and is-too-close-to-other-stlmt-new = true ) [
      set patchs-available-for-new-settlement patchs-available-for-new-settlement - 1
    ][
      set patchs-available-for-new-settlement patchs-available-for-new-settlement + 1
      ]
    )
  ]
end

to create-initial-household-individuals

  ask patch-here [

    ; *** madre

    ; se calcula segun la edad maxima que puede tener un individuo
    let max-age nobody
    ( ifelse prob-death-75-79 < 1 [ set max-age 79 ]
      prob-death-70-74 < 1 [ set max-age 74 ]
      prob-death-65-69 < 1 [ set max-age 69 ]
      prob-death-60-64 < 1 [ set max-age 64 ]
      prob-death-55-59 < 1 [ set max-age 59 ]
      prob-death-50-54 < 1 [ set max-age 54 ]
      prob-death-45-49 < 1 [ set max-age 49 ]
      prob-death-40-44 < 1 [ set max-age 44 ]
      prob-death-35-39 < 1 [ set max-age 39 ]
      prob-death-30-34 < 1 [ set max-age 34 ]
      prob-death-25-29 < 1 [ set max-age 29 ]
      prob-death-20-24 < 1 [ set max-age 24 ]
      prob-death-15-19 < 1 [ set max-age 19 ]
      prob-death-10-14 < 1 [ set max-age 14 ]
      prob-death-5-9 < 1 [ set max-age 9 ]
    )
    let mother-age random max-age ;
    if ( mother-age < menarche-age ) [set mother-age menarche-age]

    let mother nobody
    sprout 1 [
      set agent-type "person" ; Tipo individuo
      set role "mother" ; Rol madre
      set shape "person"
      set color violet

      set age mother-age
      calculate-and-set-ihi-age-expected-to-die

      set expected-number-of-children (total-fertility-rate - 1) + (random 3); +/- 1
      set age-of-last-birth 0
      set interpregnancy-interval-for-last-birth (random 2); 0 o 1

      create-links-with other turtles-here with [agent-type = "house"]

      set heading (random 360)
      forward 2

      set mother self

    ]

    ;***** padre

    sprout 1 [

      set agent-type "person" ; Tipo individuo
      set role "father" ; Rol padre
      set shape "person"
      set color cyan

      set age (mother-age - 1) + (random 3) ; La edad del padre en la misma edad de la madre +/- 1
      calculate-and-set-ihi-age-expected-to-die

      create-links-with other turtles-here with [agent-type = "house"]

      set heading (random 360)
      forward 2

    ]

    ;***** hijos

    let temp-age menarche-age + 1 ; se suma 1 debido a que en la simulacion cuando una hija se convierte en madre ya se realizaron previamente los nacimientos
                                  ; por lo tanto en el siguiente anio la madre (antes hija) va a tener la edad de menarquia + 1
                                  ; es decir, en la simulacion en ningun momento las madres van a tener hijos a la edad de menarquia

    let temp-age-of-last-birth 0
    let temp-interpregnancy-interval-for-last-birth 0
    let temp-number-of-children 0

    while [temp-age <= mother-age and temp-age <= menopause-age and temp-number-of-children < [expected-number-of-children] of mother] [

      if ( temp-age > temp-age-of-last-birth + temp-interpregnancy-interval-for-last-birth ) [

        let child-age mother-age - temp-age
        if ( child-age < menarche-age ) [; si la edad a asignar al hijo es mayor a la edad de menarquia este no se se crea, pues se asume que ya abandono la UD

          sprout 1 [
            set agent-type "person" ; Tipo individuo
            set shape "person"
            ifelse  (random 100) < females-proportion [
              set role "daughter" ; Rol hija
              set color violet
            ] [
              set role "son" ; Rol hijo
              set color cyan
            ]
            set size 0.5

            set age child-age
            calculate-and-set-ihi-age-expected-to-die

            create-links-with other turtles-here with [agent-type = "house"]

            set heading random 360
            forward 2

          ]
        ]

        set temp-age-of-last-birth temp-age
        set temp-interpregnancy-interval-for-last-birth (interpregnancy-interval - 1) + (random 3); +/- 1
        set temp-number-of-children temp-number-of-children + 1

      ]

      set temp-age temp-age + 1

    ]

    ask mother [
      set age-of-last-birth temp-age-of-last-birth
      set interpregnancy-interval-for-last-birth temp-interpregnancy-interval-for-last-birth
      set number-of-children temp-number-of-children
    ]

  ]

end

to calculate-and-set-ihi-age-expected-to-die

  let prob-death nobody
  let initial-interval nobody
  (ifelse ( 0 <= age and age <= 4 ) [ set prob-death prob-death-0-4 set initial-interval 0]
    ( 5 <= age and age <= 9 ) [ set prob-death prob-death-5-9 set initial-interval 5]
    ( 10 <= age and age <= 14 ) [ set prob-death prob-death-10-14 set initial-interval 10]
    ( 15 <= age and age <= 19 )  [set prob-death prob-death-15-19 set initial-interval 15]
    ( 20 <= age and age <= 24 ) [ set prob-death prob-death-20-24 set initial-interval 20]
    ( 25 <= age and age <= 29 ) [ set prob-death prob-death-25-29 set initial-interval 25]
    ( 30 <= age and age <= 34 ) [ set prob-death prob-death-30-34 set initial-interval 30]
    ( 35 <= age and age <= 39 ) [ set prob-death prob-death-35-39 set initial-interval 35]
    ( 40 <= age and age <= 44 ) [ set prob-death prob-death-40-44 set initial-interval 40]
    ( 45 <= age and age <= 49 ) [ set prob-death prob-death-45-49 set initial-interval 45]
    ( 50 <= age and age <= 54 ) [ set prob-death prob-death-50-54 set initial-interval 50]
    ( 55 <= age and age <= 59 ) [ set prob-death prob-death-55-59 set initial-interval 55]
    ( 60 <= age and age <= 64 ) [ set prob-death prob-death-60-64 set initial-interval 60]
    ( 65 <= age and age <= 69 ) [ set prob-death prob-death-65-69 set initial-interval 65]
    ( 70 <= age and age <= 74 ) [ set prob-death prob-death-70-74 set initial-interval 70]
    ( 75 <= age and age <= 79 ) [ set prob-death prob-death-75-79 set initial-interval 75]
  )

  set-age-expected-to-die prob-death initial-interval

  if ( age-expected-to-die > -1 and age >= age-expected-to-die ) [
    ;NOTA: debido a que la simulacion inicia con unidades domesticas completas, es decir, con madre, padre e hijos (segun total-fertility-rate), se asume que ningun individuo haya muerto antes
    ;de iniciar la simulacion (aunque deba morir en el rango de edad actual y cumpla con la edad). De esta manera, si debio haber muerto antes de iniciar la simulacion, se prefiere cambiar
    ;age-expected-to-die a -1 para que no muera en el rango de edad actual
    set age-expected-to-die -1
  ]

end

to go

  ;si despues de nuevos asentamientos (o, tambien, de la creacion de unidades domesticas iniciales) no hay mas espacio O si se llego al fin del periodo O la poblacion es cero entonces stop
  if (not is-there-space-for-settlement or ticks > period-duration or count turtles with [agent-type = "person"] = 0) [stop] ; va en el comando de finalizacion del experimento y se quita de aca

  ask turtles with [agent-type = "person"][
    set age age + 1
  ]

  birth-of-individuals

  marriage-and-new-household-settlement

  ; si despues del asentamiento de una nueva unidad domestica hay mas espacio entonces continua con la muerte de los individuos lo cual puede dejar parches disponibles para nuevos asentamientos,
  ; en caso contrario (despues del asentamiento de una nueva unidad domestica NO hay mas espacio) entonces no continua con la muerte y pasa directamente al conteo de parches disponibles,
  ; esto se hace para que la muerte no afecte la metrica final de parches disponibles para asentamiento

  if (is-there-space-for-settlement) [
    death-of-individuals
  ]

  count-and-save-population

  count-and-save-number-of-households

  calculate-and-save-mean-individuals-by-household

  tick

  ;user-message (word "Anio " ticks)

end

to count-and-save-population
  set population count turtles with [agent-type = "person"]
end

to count-and-save-number-of-households
  set number-of-households count turtles with [agent-type = "house"]
end

to calculate-and-save-mean-individuals-by-household
  let individuals 0
  let households 0
  ask turtles with [agent-type = "house"] [
    set individuals individuals + (count link-neighbors)
    set households households + 1
  ]
  ifelse (households > 0) [
    set mean-individuals-by-household individuals / households
  ][
    set mean-individuals-by-household 0
  ]
end

to birth-of-individuals

  ask turtles with [role = "mother" and (menarche-age <= age and age <= menopause-age) and number-of-children < expected-number-of-children] [

    let household nobody
    let father nobody
    ask link-neighbors [
      set household self
      ask link-neighbors with [role = "father"] [ set father self ]
    ]

    if ( father != nobody and age > age-of-last-birth + interpregnancy-interval-for-last-birth ) [
      ask household [
        ask patch-here [
          sprout 1 [
            set agent-type "person" ; Tipo individuo
            set shape "person"
            ifelse  (random 100) < females-proportion [
              set role "daughter" ; Rol hija
              set color violet
            ] [
              set role "son" ; Rol hijo
              set color cyan
            ]
            set size 0.5

            set age 0

            create-link-with household

            set heading random 360
            forward 2

            set total-births total-births + 1
          ]
        ]
      ]

      set age-of-last-birth age
      set interpregnancy-interval-for-last-birth (interpregnancy-interval - 1) + (random 3); +/- 1
      set number-of-children number-of-children + 1

    ]

  ]

end

to marriage-and-new-household-settlement

  ask turtles with [ role = "daughter" and menarche-age <= age ] [

    if ( not is-there-space-for-settlement ) [ stop ]

    let daughter-household nobody
    let son nobody
    let patch-for-new-settlement nobody
    let new-household nobody

    ; ***** obtiene la unidad domestica de la hija

    set daughter-household one-of link-neighbors

    ; ***** obtiene el hijo de otra unidad domestica

    ask daughter-household [

      ask other turtles with [agent-type = "house"] [ ; otras viviendas diferentes a la de la hija

        if ( son != nobody ) [ stop ]; si ya obtuvo el hijo entonces no continua buscando

        ask link-neighbors with [role = "son" and menarche-age <= age] [; por simplicidad el hijo cumple la misma condicion que la hija para ingresar a la vida reproductiva

          set son self

        ]

      ]

    ]

    ; ***** identifica el lugar donde se va a asentar la nueva vivienda

    if ( son != nobody ) [

      ; siempre busca un nuevo sitio aunque la hija o el hijo sean los unicos habitantes de la UD
      ; NOTA: si el reuso de tierra para asentamiento estuviera habilitado se podria usar el sitio natal de los hijos para el nuevo asentamiento,
      ; sin embargo considero que la no implementacion de esta logica no tiene un impacto significativo en los resultados,
      ; pues solo tendria relevancia cuando ya no hay mas espacio para nuevos asentamientos Y se cumple que alguno de los hijos sea el unico habitante de la UD

      set patch-for-new-settlement get-patch-available-for-settlement
      if ( not is-there-space-for-settlement ) [ stop ]

      ; ***** asentamiento de la nueva vivienda

      ; unidad domestica
      ask patch-for-new-settlement [

        sprout 1 [
          set agent-type "house" ; Tipo unidad domestica
          set role "household" ; Rol vivienda
          set shape "house"
          set color gray
          set size 1
          set new-household self

        ]

      ]

      ; hijo a padre
      ask son [

        move-to patch-for-new-settlement
        set role "father" ; Rol padre
        ask my-links [ die ]
        create-link-with new-household
        set color cyan
        set heading (random 360)
        forward 2
        set size 1

      ]

      ; hija a madre
      move-to patch-for-new-settlement

      set role "mother" ; Rol madre
      set color violet
      set size 1

      set expected-number-of-children (total-fertility-rate - 1) + (random 3); +/- 1
      set age-of-last-birth 0
      set interpregnancy-interval-for-last-birth 0

      ask my-links [ die ]
      create-link-with new-household

      set heading (random 360)
      forward 2

    ]

  ]

end

to death-of-individuals

  ask turtles with [agent-type = "person"][

    calculate-and-set-age-expected-to-die

    if ( age-expected-to-die > -1 and age >= age-expected-to-die ) [

      set total-deaths total-deaths + 1
      die ; el individuo muere sin importar su rol o si tiene otros individuos a su cargo

    ]

  ]

  ask turtles with [agent-type = "house"][

    let num-individuals-household count link-neighbors ; cantidad de individuos en la unidad domestica

    if ( num-individuals-household = 0 ) [

      ask patches in-radius trash-scatter-radius [
        ifelse ( land-reuse-for-settlement ) [
          set status "enabled" ; El area queda disponible para nuevo asentamiento
          set pcolor green
        ] [
          set status "discarded" ; Area con ocupacion artificial
          set pcolor orange
        ]
      ]

      if ( land-reuse-for-settlement ) [
        ask patches in-radius (2 * trash-scatter-radius) with [is-ok-for-settlement = true and status = "enabled"] [

          let is-too-close-to-other-stlmt-new check-if-other-stlmt-is-too-close self
          count-and-save-patchs-available-for-new-settlement is-too-close-to-other-stlmt is-too-close-to-other-stlmt-new
          set is-too-close-to-other-stlmt is-too-close-to-other-stlmt-new

        ]
      ]

      die

    ]

  ]

end


to calculate-and-set-age-expected-to-die

  let prob-death nobody
  let initial-interval nobody
  (ifelse ( age = 0) [ set prob-death prob-death-0-4 set initial-interval 0]
    ( age = 5 ) [ set prob-death prob-death-5-9 set initial-interval 5]
    ( age = 10 ) [ set prob-death prob-death-10-14 set initial-interval 10]
    ( age = 15 )  [set prob-death prob-death-15-19 set initial-interval 15]
    ( age = 20 ) [ set prob-death prob-death-20-24 set initial-interval 20]
    ( age = 25 ) [ set prob-death prob-death-25-29 set initial-interval 25]
    ( age = 30 ) [ set prob-death prob-death-30-34 set initial-interval 30]
    ( age = 35 ) [ set prob-death prob-death-35-39 set initial-interval 35]
    ( age = 40 ) [ set prob-death prob-death-40-44 set initial-interval 40]
    ( age = 45 ) [ set prob-death prob-death-45-49 set initial-interval 45]
    ( age = 50 ) [ set prob-death prob-death-50-54 set initial-interval 50]
    ( age = 55 ) [ set prob-death prob-death-55-59 set initial-interval 55]
    ( age = 60 ) [ set prob-death prob-death-60-64 set initial-interval 60]
    ( age = 65 ) [ set prob-death prob-death-65-69 set initial-interval 65]
    ( age = 70 ) [ set prob-death prob-death-70-74 set initial-interval 70]
    ( age = 75 ) [ set prob-death prob-death-75-79 set initial-interval 75]
  )

  set-age-expected-to-die prob-death initial-interval

end

to set-age-expected-to-die [prob-death initial-interval]

  if ( prob-death != nobody ) [

    let random-float-temp random-float 1 ; se calcula si va a morir en el rango actual o no

    ifelse ( random-float-temp < prob-death ) [

      set age-expected-to-die initial-interval + random 5 ; se calcula la edad de muerte dentro del rango actual

    ][

      set age-expected-to-die -1 ; no va a morir en el rango de edad actual

    ]

  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
295
282
3104
2292
-1
-1
1.0
1
10
1
1
1
0
0
0
1
-1400
1400
-1000
1000
0
0
1
ticks
30.0

BUTTON
48
18
130
63
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
138
18
217
63
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
9
74
276
107
initial-number-households
initial-number-households
0
500
37.0
1
1
NIL
HORIZONTAL

SLIDER
8
115
276
148
trash-scatter-radius
trash-scatter-radius
1
10
3.0
1
1
NIL
HORIZONTAL

MONITOR
482
14
653
59
Unidades Domesticas
number-of-households
17
1
11

MONITOR
294
14
466
59
Individuos
population
17
1
11

SLIDER
6
215
277
248
females-proportion
females-proportion
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
6
279
277
312
menarche-age
menarche-age
0
20
15.0
1
1
NIL
HORIZONTAL

SLIDER
6
317
277
350
menopause-age
menopause-age
40
60
49.0
1
1
NIL
HORIZONTAL

CHOOSER
6
472
281
517
paleodem-data
paleodem-data
"jagua-rodriguez" "jagua-2p-rodriguez" "northern-ache-females-chamberlain"
1

PLOT
295
75
800
267
Población
Años
Individuos
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot population"

SLIDER
6
355
278
388
interpregnancy-interval
interpregnancy-interval
2
10
2.0
1
1
NIL
HORIZONTAL

PLOT
1270
75
1700
271
Nacimientos vs Muertes
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot total-deaths"
"pen-1" 1.0 0 -10899396 true "" "plot total-births"

PLOT
814
76
1254
268
Parches disponibles para asentamiento
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot patchs-available-for-new-settlement"

SWITCH
38
155
236
188
land-reuse-for-settlement
land-reuse-for-settlement
1
1
-1000

MONITOR
1269
20
1362
65
Nacimientos
total-births
0
1
11

MONITOR
1368
21
1468
66
Muertes
total-deaths
0
1
11

MONITOR
814
20
1041
65
Parches disponibles para asentamiento
patchs-available-for-new-settlement
0
1
11

CHOOSER
6
419
280
464
archeo-data
archeo-data
"san-agustin-isnos-formativo-1" "san-agustin-isnos-formativo-2" "san-agustin-isnos-formativo-3" "san-agustin-isnos-clasico-regional" "san-agustin-isnos-reciente"
4

MONITOR
6
523
125
568
Duracion del Periodo
period-duration
0
1
11

PLOT
1720
75
2077
271
Promedio individuos por unidad doméstica
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean-individuals-by-household"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="v1.2-sai-form2-j2p-min-2to48-x200" repetitions="200" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>not is-there-space-for-settlement or ticks = period-duration or population = 0</exitCondition>
    <metric>patchs-available-for-new-settlement</metric>
    <metric>population</metric>
    <metric>number-of-households</metric>
    <metric>total-deaths</metric>
    <metric>mean-individuals-by-household</metric>
    <enumeratedValueSet variable="initial-number-households">
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
      <value value="12"/>
      <value value="13"/>
      <value value="14"/>
      <value value="15"/>
      <value value="16"/>
      <value value="17"/>
      <value value="18"/>
      <value value="19"/>
      <value value="20"/>
      <value value="21"/>
      <value value="22"/>
      <value value="23"/>
      <value value="24"/>
      <value value="25"/>
      <value value="26"/>
      <value value="27"/>
      <value value="28"/>
      <value value="29"/>
      <value value="30"/>
      <value value="31"/>
      <value value="32"/>
      <value value="33"/>
      <value value="34"/>
      <value value="35"/>
      <value value="36"/>
      <value value="37"/>
      <value value="38"/>
      <value value="39"/>
      <value value="40"/>
      <value value="41"/>
      <value value="42"/>
      <value value="43"/>
      <value value="44"/>
      <value value="45"/>
      <value value="46"/>
      <value value="47"/>
      <value value="48"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trash-scatter-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="land-reuse-for-settlement">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="females-proportion">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="menarche-age">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="menopause-age">
      <value value="49"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interpregnancy-interval">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="archeo-data">
      <value value="&quot;san-agustin-isnos-formativo-2&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="paleodem-data">
      <value value="&quot;jagua-2p-rodriguez&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="v1.3-sai-form2-j2p-max-2to60-x100" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>not is-there-space-for-settlement or ticks = period-duration or population = 0</exitCondition>
    <metric>patchs-available-for-new-settlement</metric>
    <metric>population</metric>
    <metric>number-of-households</metric>
    <metric>total-deaths</metric>
    <metric>mean-individuals-by-household</metric>
    <enumeratedValueSet variable="initial-number-households">
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
      <value value="12"/>
      <value value="13"/>
      <value value="14"/>
      <value value="15"/>
      <value value="16"/>
      <value value="17"/>
      <value value="18"/>
      <value value="19"/>
      <value value="20"/>
      <value value="21"/>
      <value value="22"/>
      <value value="23"/>
      <value value="24"/>
      <value value="25"/>
      <value value="26"/>
      <value value="27"/>
      <value value="28"/>
      <value value="29"/>
      <value value="30"/>
      <value value="31"/>
      <value value="32"/>
      <value value="33"/>
      <value value="34"/>
      <value value="35"/>
      <value value="36"/>
      <value value="37"/>
      <value value="38"/>
      <value value="39"/>
      <value value="40"/>
      <value value="41"/>
      <value value="42"/>
      <value value="43"/>
      <value value="44"/>
      <value value="45"/>
      <value value="46"/>
      <value value="47"/>
      <value value="48"/>
      <value value="49"/>
      <value value="50"/>
      <value value="51"/>
      <value value="52"/>
      <value value="53"/>
      <value value="54"/>
      <value value="55"/>
      <value value="56"/>
      <value value="57"/>
      <value value="58"/>
      <value value="59"/>
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trash-scatter-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="land-reuse-for-settlement">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="females-proportion">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="menarche-age">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="menopause-age">
      <value value="49"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interpregnancy-interval">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="archeo-data">
      <value value="&quot;san-agustin-isnos-formativo-2&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="paleodem-data">
      <value value="&quot;jagua-2p-rodriguez&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="v1.2-sai-clare-j2p-min-2to23-x300" repetitions="300" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>not is-there-space-for-settlement or ticks = period-duration or population = 0</exitCondition>
    <metric>patchs-available-for-new-settlement</metric>
    <metric>population</metric>
    <metric>number-of-households</metric>
    <metric>total-deaths</metric>
    <metric>mean-individuals-by-household</metric>
    <enumeratedValueSet variable="initial-number-households">
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
      <value value="12"/>
      <value value="13"/>
      <value value="14"/>
      <value value="15"/>
      <value value="16"/>
      <value value="17"/>
      <value value="18"/>
      <value value="19"/>
      <value value="20"/>
      <value value="21"/>
      <value value="22"/>
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trash-scatter-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="land-reuse-for-settlement">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="females-proportion">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="menarche-age">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="menopause-age">
      <value value="49"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interpregnancy-interval">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="archeo-data">
      <value value="&quot;san-agustin-isnos-clasico-regional&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="paleodem-data">
      <value value="&quot;jagua-2p-rodriguez&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="v1.2-sai-reci-j2p-min-2to50-x100" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>not is-there-space-for-settlement or ticks = period-duration or population = 0</exitCondition>
    <metric>patchs-available-for-new-settlement</metric>
    <metric>population</metric>
    <metric>number-of-households</metric>
    <metric>total-deaths</metric>
    <metric>mean-individuals-by-household</metric>
    <enumeratedValueSet variable="initial-number-households">
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
      <value value="12"/>
      <value value="13"/>
      <value value="14"/>
      <value value="15"/>
      <value value="16"/>
      <value value="17"/>
      <value value="18"/>
      <value value="19"/>
      <value value="20"/>
      <value value="21"/>
      <value value="22"/>
      <value value="23"/>
      <value value="24"/>
      <value value="25"/>
      <value value="26"/>
      <value value="27"/>
      <value value="28"/>
      <value value="29"/>
      <value value="30"/>
      <value value="31"/>
      <value value="32"/>
      <value value="33"/>
      <value value="34"/>
      <value value="35"/>
      <value value="36"/>
      <value value="37"/>
      <value value="38"/>
      <value value="39"/>
      <value value="40"/>
      <value value="41"/>
      <value value="42"/>
      <value value="43"/>
      <value value="44"/>
      <value value="45"/>
      <value value="46"/>
      <value value="47"/>
      <value value="48"/>
      <value value="49"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trash-scatter-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="land-reuse-for-settlement">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="females-proportion">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="menarche-age">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="menopause-age">
      <value value="49"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interpregnancy-interval">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="archeo-data">
      <value value="&quot;san-agustin-isnos-reciente&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="paleodem-data">
      <value value="&quot;jagua-2p-rodriguez&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="v1.2-sai-form3-j2p-min-2to47-x200" repetitions="200" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>not is-there-space-for-settlement or ticks = period-duration or population = 0</exitCondition>
    <metric>patchs-available-for-new-settlement</metric>
    <metric>population</metric>
    <metric>number-of-households</metric>
    <metric>total-deaths</metric>
    <metric>mean-individuals-by-household</metric>
    <enumeratedValueSet variable="initial-number-households">
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
      <value value="12"/>
      <value value="13"/>
      <value value="14"/>
      <value value="15"/>
      <value value="16"/>
      <value value="17"/>
      <value value="18"/>
      <value value="19"/>
      <value value="20"/>
      <value value="21"/>
      <value value="22"/>
      <value value="23"/>
      <value value="24"/>
      <value value="25"/>
      <value value="26"/>
      <value value="27"/>
      <value value="28"/>
      <value value="29"/>
      <value value="30"/>
      <value value="31"/>
      <value value="32"/>
      <value value="33"/>
      <value value="34"/>
      <value value="35"/>
      <value value="36"/>
      <value value="37"/>
      <value value="38"/>
      <value value="39"/>
      <value value="40"/>
      <value value="41"/>
      <value value="42"/>
      <value value="43"/>
      <value value="44"/>
      <value value="45"/>
      <value value="46"/>
      <value value="47"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trash-scatter-radius">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="land-reuse-for-settlement">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="females-proportion">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="menarche-age">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="menopause-age">
      <value value="49"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interpregnancy-interval">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="archeo-data">
      <value value="&quot;san-agustin-isnos-formativo-3&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="paleodem-data">
      <value value="&quot;jagua-2p-rodriguez&quot;"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
