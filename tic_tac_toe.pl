:- use_module(library(lists)).
:- use_module(library(random)).

% Розраховується крок ШІ для легкого рівня
% bot_move_easy(+Board, +N, +M, -Move)
bot_move_easy(Board, N, M, Move) :-
    findall(Index, nth0(Index, Board, ' '), EmptyIndices),
    ( member(Move, EmptyIndices),
      winning_move(Board, N, M, Move, 'o')
    -> true
    ; ( member(Move, EmptyIndices),
          winning_move(Board, N, M, Move, 'x')
      -> true
      ; random_member(Move, EmptyIndices)
      )
    ).

% Розраховується крок ШІ для важкого рівня
% bot_move_difficult(+Board, +N, +M, -Move)
bot_move_difficult(Board, N, M, Move) :-
    findall(Index, nth0(Index, Board, ' '), EmptyIndices),
    random(R),
    ( R < 0.1 ->
         random_member(Move, EmptyIndices)
    ;
      ( member(Move, EmptyIndices),
        winning_move(Board, N, M, Move, 'o')
      -> true
      ; ( member(Move, EmptyIndices),
               winning_move(Board, N, M, Move, 'x')
         -> true
         ; best_move_evaluation(Board, N, M, Move)
         )
      )
    ).

% Чи наступний крок може бути виграшним
% winning_move(+Board, +N, +M, +Move, +Player)
winning_move(Board, N, M, Move, Player) :-
    set_cell(Board, Move, Player, NewBoard),
    win(NewBoard, N, M, Player).

% Замінює елемент у списку, утворюючи новий
% set_cell(+Board, +Index, +Value, -NewBoard)
set_cell(Board, Index, Value, NewBoard) :-
    same_length(Board, NewBoard),
    append(Prefix, [_|Suffix], Board),
    length(Prefix, Index),
    append(Prefix, [Value|Suffix], NewBoard).

% Перевіряє, чи переміг гравець
% win(+Board, +N, +M, +Player)
win(Board, N, M, Player) :-
    row_win(Board, N, M, Player)
    ;
    col_win(Board, N, M, Player)
    ;
    ( N =:= M, diag_win(Board, M, Player) ).

% Перевіряє, чи є рядок, повністю заповнений символами одного гравця
% row_win(+Board, +N, +M, +Player)
row_win(Board, N, M, Player) :-
    N1 is N - 1,
    between(0, N1, Row),
    Start is Row * M,
    End is Start + M,
    check_line(Board, Start, End, Player).

% Перевіряє, чи є колонка, повністю заповнена символами одного гравця
% col_win(+Board, +N, +M, +Player)
col_win(Board, N, M, Player) :-
    M1 is M - 1,
    between(0, M1, Col),
    col_indices(Col, N, M, Indices),
    check_cells(Board, Indices, Player).

% Перевіряє, чи є одна з діагоналей у квадратному полі, повністю заповнена символами одного гравця
% diag_win(+Board, +M, +Player)
diag_win(Board, M, Player) :-
    diag1_indices(M, Indices1),
    check_cells(Board, Indices1, Player)
    ;
    diag2_indices(M, Indices2),
    check_cells(Board, Indices2, Player).

% Перевіряє лінію
% check_line(+Board, +Start, +End, +Player)
check_line(Board, Start, End, Player) :-
    End1 is End - 1,
    findall(Cell, (
        between(Start, End1, I),
        nth0(I, Board, Cell)
    ), Cells),
    maplist(=(Player), Cells).

% Обчислює список індексів для всіх елементів певного стовпця
% col_indices(+Col, +N, +M, -Indices)
col_indices(Col, N, M, Indices) :-
    N1 is N - 1,
    findall(Index, (
        between(0, N1, Row),
        Index is Row * M + Col
    ), Indices).

% Обчислює індекси для головної діагоналі квадратного поля
% diag1_indices(+M, -Indices)
diag1_indices(M, Indices) :-
    M1 is M - 1,
    findall(Index, (
        between(0, M1, I),
        Index is I * M + I
    ), Indices).

% Обчислює індекси для побічної діагоналі квадратного поля
% diag2_indices(+M, -Indices)
diag2_indices(M, Indices) :-
    M1 is M - 1,
    findall(Index, (
        between(0, M1, I),
        Index is I * M + (M - 1 - I)
    ), Indices).

% Перевіряє, чи для кожного індексу з списку відповідна клітинка дорівнює гравцеві потрібному
% check_cells(+Board, +Indices, +Player)
check_cells(Board, Indices, Player) :-
    maplist(cell_is(Board, Player), Indices).

% Перевіряє, чи клітинка дорівнює гравцеві потрібному
% cell_is(+Board, +Player, +Index)
cell_is(Board, Player, Index) :-
    nth0(Index, Board, Cell),
    Cell == Player.

% Перебирає всі порожні клітинки, обчислює для кожної її евристичну оцінку, і вибирає ту, що має найбільше значення.
% best_move_evaluation(+Board, +N, +M, -BestMove)
best_move_evaluation(Board, N, M, BestMove) :-
    findall(Score-Move, (
       nth0(Move, Board, ' '),
       evaluate_move(Board, N, M, Move, Score)
    ), ScoreMoves),
    keysort(ScoreMoves, Sorted),
    reverse(Sorted, [ _-BestMove | _ ]).

% Обчислює оцінку для даного ходу.
% evaluate_move(+Board, +N, +M, +Move, -Score)
evaluate_move(Board, N, M, Move, Score) :-
    row_index(Move, M, Row),
    col_index(Move, M, Col),
    row_score(Board, Row, M, ScoreRow),
    col_score(Board, Col, N, M, ScoreCol),
    diag_score(Board, N, M, Row, Col, ScoreDiag),
    Score is ScoreRow + ScoreCol + ScoreDiag.

% Допоміжні предикати для визначення номера рядка та стовпця за індексом:
% row_index(+Index, +M, -Row)
row_index(Index, M, Row) :-
    Row is Index // M.

% col_index(+Index, +M, -Col)
col_index(Index, M, Col) :-
    Col is Index mod M.

% Обчислює оцінку для рядка
% row_score(+Board, +Row, +M, -Score)
row_score(Board, Row, M, Score) :-
    Start is Row * M,
    End is Start + M,
    End1 is End - 1,
    findall(Cell, (between(Start, End1, I), nth0(I, Board, Cell)), Cells),
    ( member('x', Cells) -> Score = 0
    ; include(=('o'), Cells, Os), length(Os, Score)
    ).

% Обчислює оцінку для стовпця
% col_score(+Board, +Col, +N, +M, -Score)
col_score(Board, Col, N, M, Score) :-
    N1 is N - 1,
    findall(Cell, (
       between(0, N1, Row),
       I is Row * M + Col,
       nth0(I, Board, Cell)
    ), Cells),
    ( member('x', Cells) -> Score = 0
    ; include(=('o'), Cells, Os), length(Os, Score)
    ).

% Обчислює оцінку для діагоналей
% diag_score(+Board, +N, +M, +Row, +Col, -Score)
diag_score(Board, N, M, Row, Col, Score) :-
    ( Row =:= Col ->
         N1 is N - 1,
         findall(Cell, (
            between(0, N1, I),
            I < M,
            J is I,
            Index is I * M + J,
            nth0(Index, Board, Cell)
         ), DiagCells),
         ( member('x', DiagCells) -> Score1 = 0
         ; include(=('o'), DiagCells, Os), length(Os, Score1)
         )
    ; Score1 = 0
    ),
    ( Row + Col =:= M - 1 ->
         N1 is N - 1,
         findall(Cell, (
            between(0, N1, I),
            J is M - 1 - I,
            I < N, J >= 0,
            Index is I * M + J,
            nth0(Index, Board, Cell)
         ), AntiDiagCells),
         ( member('x', AntiDiagCells) -> Score2 = 0
         ; include(=('o'), AntiDiagCells, Os), length(Os, Score2)
         )
    ; Score2 = 0
    ),
    Score is Score1 + Score2.
