% ============================================================
% WHOlog - Adivina Quién de superhéroes
% Base de conocimiento + motor de preguntas
% ============================================================

% --- Hechos: personaje/11 ---
% personaje(Nombre, Universo, Mascara, Capa, Armas, Vuela, Humano,
%            Genero, Equipo, TipoPoderBase, Habitat)
personaje('Spider-Man',     marvel, true,  false, false, false, true,  masc, vengadores,    fisico,      urbano).
personaje('Batman',         dc,     true,  true,  true,  false, true,  masc, liga_justicia, tecnologico, urbano).
personaje('Wonder Woman',   dc,     false, false, true,  true,  true,  fem,  liga_justicia, fisico,      urbano).
personaje('Iron Man',       marvel, true,  false, true,  true,  true,  masc, vengadores,    tecnologico, urbano).
personaje('Superman',       dc,     false, true,  false, true,  true,  masc, liga_justicia, cosmico,     urbano).
personaje('Black Widow',    marvel, false, false, true,  false, true,  fem,  vengadores,    fisico,      urbano).
personaje('The Joker',      dc,     false, false, true,  false, true,  masc, independiente, fisico,      urbano).
personaje('Hulk',           marvel, false, false, false, false, false, masc, vengadores,    fisico,      urbano).
personaje('Captain America',marvel, true,  false, true,  false, true,  masc, vengadores,    fisico,      urbano).
personaje('Harley Quinn',   dc,     false, false, true,  false, true,  fem,  escuadron_s,   fisico,      urbano).
personaje('Thor',           marvel, false, true,  true,  true,  true,  masc, vengadores,    elemental,   espacio).
personaje('The Flash',      dc,     true,  false, false, false, true,  masc, liga_justicia, fisico,      urbano).
personaje('Black Panther',  marvel, true,  false, false, false, true,  masc, vengadores,    fisico,      urbano).
personaje('Aquaman',        dc,     false, false, true,  false, true,  masc, liga_justicia, elemental,   oceano).
personaje('Storm',          marvel, false, true,  false, true,  true,  fem,  x_men,         elemental,   urbano).
personaje('Green Lantern',  dc,     true,  false, true,  true,  true,  masc, liga_justicia, cosmico,     espacio).
personaje('Scarlet Witch',  marvel, false, false, false, true,  true,  fem,  vengadores,    magico,      dimension).
personaje('Wolverine',      marvel, true,  false, true,  false, true,  masc, x_men,         fisico,      urbano).
personaje('Cyborg',         dc,     false, false, true,  true,  false, masc, liga_justicia, tecnologico, urbano).
personaje('Catwoman',       dc,     true,  false, true,  false, true,  fem,  independiente, fisico,      urbano).
personaje('Deadpool',       marvel, true,  false, true,  false, true,  masc, independiente, fisico,      urbano).
personaje('Raven',          dc,     false, true,  false, true,  true,  fem,  j_titanes,     magico,      dimension).
personaje('Daredevil',      marvel, true,  false, true,  false, true,  masc, vengadores,    fisico,      urbano).
personaje('Starfire',       dc,     false, false, false, true,  false, fem,  j_titanes,     cosmico,     espacio).
personaje('Magneto',        marvel, true,  true,  false, true,  true,  masc, x_men,         elemental,   urbano).
personaje('Dr. Strange',    marvel, false, true,  true,  true,  true,  masc, vengadores,    magico,      dimension).
personaje('Beast Boy',      dc,     false, false, false, false, false, masc, j_titanes,     fisico,      urbano).
personaje('Silver Surfer',  marvel, false, false, false, true,  false, masc, independiente, cosmico,     espacio).

% ============================================================
% Atributos disponibles para preguntar
% Formato: atributo(NombrePregunta, Posicion, Tipo, OpcionesOValor)
% Tipo: booleano | enum
% ============================================================

atributo(universo,    2, enum,     [dc, marvel]).
atributo(mascara,     3, booleano, [true, false]).
atributo(capa,        4, booleano, [true, false]).
atributo(armas,       5, booleano, [true, false]).
atributo(vuela,       6, booleano, [true, false]).
atributo(humano,      7, booleano, [true, false]).
atributo(genero,      8, enum,     [masc, fem]).
atributo(equipo,      9, enum,     [vengadores, liga_justicia, x_men, j_titanes,
                                    escuadron_s, independiente]).
atributo(poder,      10, enum,     [fisico, tecnologico, cosmico, elemental, magico]).
atributo(habitat,    11, enum,     [urbano, espacio, oceano, dimension]).

% ============================================================
% Obtener el valor de un atributo de un personaje por posición
% ============================================================
valor_atributo(Nombre, Pos, Valor) :-
    personaje(Nombre, U, Ma, Ca, Ar, Vl, Hu, Ge, Eq, Po, Ha),
    nth1(Pos, [Nombre, U, Ma, Ca, Ar, Vl, Hu, Ge, Eq, Po, Ha], Valor).

% ============================================================
% Obtener todos los nombres de personajes
% ============================================================
todos_los_personajes(Lista) :-
    findall(N, personaje(N, _, _, _, _, _, _, _, _, _, _), Lista).

% ============================================================
% Filtrar personajes según restricciones acumuladas
% Restriccion: attr(Pos, Valor)
% ============================================================
personaje_cumple(_, []).
personaje_cumple(Nombre, [attr(Pos, Valor)|Resto]) :-
    valor_atributo(Nombre, Pos, Valor),
    personaje_cumple(Nombre, Resto).
personaje_cumple(Nombre, [not_attr(Pos, Valor)|Resto]) :-
    valor_atributo(Nombre, Pos, V),
    V \= Valor,
    personaje_cumple(Nombre, Resto).

personajes_activos(Restricciones, Lista) :-
    findall(N,
        (personaje(N, _, _, _, _, _, _, _, _, _, _),
         personaje_cumple(N, Restricciones)),
        Lista).

personajes_descartados(Restricciones, Descartados) :-
    todos_los_personajes(Todos),
    personajes_activos(Restricciones, Activos),
    subtract(Todos, Activos, Descartados).

% ============================================================
% Motor de puntuación de preguntas (elige la mejor)
% Puntaje = Descartes - 0.5 * Equilibrio
% ============================================================
puntaje_pregunta(Atributo, Valor, Activos, Puntaje) :-
    atributo(Atributo, Pos, _, _),
    length(Activos, Total),
    include(tiene_valor(Pos, Valor), Activos, ConSi),
    length(ConSi, NSi),
    NNo is Total - NSi,
    MaxSiNo is max(NSi, NNo),
    Descartes is Total - MaxSiNo,
    Equilibrio is abs(NSi - NNo),
    Puntaje is Descartes - 0.5 * Equilibrio.

tiene_valor(Pos, Valor, Nombre) :-
    valor_atributo(Nombre, Pos, Valor).

% Pos está determinada si ya tiene un attr positivo O si solo queda
% una opción posible (todas las demás tienen not_attr).
pos_determinada(Pos, Restricciones) :-
    member(attr(Pos, _), Restricciones).
pos_determinada(Pos, Restricciones) :-
    atributo(_, Pos, _, Opciones),
    length(Opciones, Total),
    findall(V, member(not_attr(Pos, V), Restricciones), Negados),
    length(Negados, NNeg),
    Restantes is Total - NNeg,
    Restantes =< 1.

% Genera pares (Puntaje, atributo(Atributo,Valor)) para todos los
% atributos y opciones NO determinados, dado el conjunto de activos actual.
todas_preguntas_puntuadas(Activos, Restricciones, Pares) :-
    findall(P-attr(At, Val),
        (atributo(At, Pos, _, Opciones),
         \+ pos_determinada(Pos, Restricciones),
         member(Val, Opciones),
         \+ member(not_attr(Pos, Val), Restricciones),
         puntaje_pregunta(At, Val, Activos, P),
         P > 0),
        Pares).

mejor_pregunta(Activos, Restricciones, MejorAtributo, MejorValor, MejorPuntaje) :-
    todas_preguntas_puntuadas(Activos, Restricciones, Pares),
    Pares \= [],
    max_member(MejorPuntaje-attr(MejorAtributo, MejorValor), Pares).

% ============================================================
% Listar todos los puntajes (para depuración / API)
% ============================================================
listar_puntajes(Restricciones) :-
    personajes_activos(Restricciones, Activos),
    todas_preguntas_puntuadas(Activos, Restricciones, Pares),
    msort(Pares, Ordenados),
    reverse(Ordenados, Desc),
    maplist(print_par, Desc).

print_par(P-attr(At, Val)) :-
    format("~w (~w): ~2f~n", [At, Val, P]).

% ============================================================
% Punto de entrada para la API (llamado desde el servidor)
% Recibe restricciones como término, imprime JSON-like result
% ============================================================

% estado_json(+Restricciones)
% Imprime en stdout JSON válido: activos, descartados y mejor pregunta.
estado_json(Restricciones) :-
    personajes_activos(Restricciones, Activos),
    personajes_descartados(Restricciones, Descartados),
    (   mejor_pregunta(Activos, Restricciones, MejAt, MejVal, MejPunt)
    ->  true
    ;   MejAt = null, MejVal = null, MejPunt = 0
    ),
    length(Activos, NA),
    length(Descartados, ND),
    write('{"activos":'),
    lista_json(Activos),
    write(',"descartados":'),
    lista_json(Descartados),
    format(',"total_activos":~w,"total_descartados":~w,"mejor_pregunta":{"atributo":"~w","valor":"~w","puntaje":~2f}}~n',
           [NA, ND, MejAt, MejVal, MejPunt]).

% Imprime una lista Prolog como array JSON de strings
lista_json(Lista) :-
    write('['),
    lista_json_items(Lista),
    write(']').

lista_json_items([]).
lista_json_items([X]) :-
    !,
    format('"~w"', [X]).
lista_json_items([X|Xs]) :-
    format('"~w",', [X]),
    lista_json_items(Xs).
