import tkinter as tk
from tkinter import simpledialog
from pyswip import Prolog

def get_bot_move(board, n, m, difficulty):
    """
    Отримує найкращий хід для ШІ
    """
    prolog = Prolog()
    prolog.consult("tic_tac_toe.pl")

    board_str = "[" + ",".join(f"'{cell}'" for cell in board) + "]"

    if difficulty.lower() == "easy":
        predicate = "bot_move_easy"
    else:
        predicate = "bot_move_difficult"

    query = f"{predicate}({board_str}, {n}, {m}, Move)"
    results = list(prolog.query(query))
    move = results[0]["Move"]
    return move

def potential_line(line):
    """
    Визначає, чи може дана лінія (ряд, стовпець чи діагональ) бути заповнена одним символом (тобто, вона ще не «заблокована» обома символами).
    """
    s = set(line)
    if ' ' in s:
        s.remove(' ')
    return len(s) <= 1

def check_draw():
    """
    Проходить по всіх потенційних виграшних лініях (рядках, стовпцях, діагоналях для квадратного поля).
    Якщо кожна з них заблокована (тобто у кожній вже є обидва символи), вона повертає True, сигналізуючи про нічию.
    """
    global n, m, board

    for row in range(n):
        line = [board[row * m + col] for col in range(m)]
        if potential_line(line):
            return False

    for col in range(m):
        line = [board[row * m + col] for row in range(n)]
        if potential_line(line):
            return False

    if n == m:
        diag1 = [board[i * m + i] for i in range(n)]
        if potential_line(diag1):
            return False
        diag2 = [board[i * m + (m - 1 - i)] for i in range(n)]
        if potential_line(diag2):
            return False
    return True

def make_move(index):
    """
    Робить хід
    """
    if board[index] == ' ':
        board[index] = 'x'
        buttons[index].config(text='X')
        if check_winner('x'):
            label.config(text="Гравець виграв!")
            disable_buttons()
            return
        elif all(cell != ' ' for cell in board) or check_draw():
            label.config(text="Нічия!")
            disable_buttons()
            return

        ai_move = get_bot_move(board, n, m, difficulty)
        if ai_move is not None:
            board[ai_move] = 'o'
            buttons[ai_move].config(text='O')
            if check_winner('o'):
                label.config(text="AI виграв!")
                disable_buttons()
            elif all(cell != ' ' for cell in board) or check_draw():
                label.config(text="Нічия!")
                disable_buttons()
            else:
                label.config(text="Хід гравця")
        else:
            label.config(text="Нічия!")

def check_winner(player):
    """
    Перевіряє, чи гравець переміг
    """
    for row in range(n):
        if all(board[row * m + col] == player for col in range(m)):
            return True

    for col in range(m):
        if all(board[row * m + col] == player for row in range(n)):
            return True

    if n == m:
        if all(board[i * m + i] == player for i in range(n)):
            return True
        if all(board[i * m + (m - 1 - i)] == player for i in range(n)):
            return True
    return False

def disable_buttons():
    """
    Блокує всі кнопки ігрової дошки.
    """
    for button in buttons:
        button.config(state='disabled')

def start_game():
    """
    Початок гри
    """
    global n, m, board, buttons, label, difficulty

    n = simpledialog.askinteger("Розмір поля", "Введіть кількість рядків (n > 10):", minvalue=11)
    m = simpledialog.askinteger("Розмір поля", "Введіть кількість стовпців (m > 10):", minvalue=11)

    difficulty = simpledialog.askstring("Складність", "Введіть рівень складності (easy/difficult):")
    if difficulty is None:
        difficulty = "easy"

    board = [' ' for _ in range(n * m)]
    buttons = []

    for widget in root.winfo_children():
        widget.destroy()

    for i in range(n * m):
        button = tk.Button(root, text=' ', width=3, height=1, font=("Arial", 10),
                           command=lambda i=i: make_move(i))
        button.grid(row=i // m, column=i % m)
        buttons.append(button)

    label = tk.Label(root, text="Хід гравця", font=("Arial", 14))
    label.grid(row=n, column=0, columnspan=m)

root = tk.Tk()
root.title("Хрестики-нулики AI")

start_button = tk.Button(root, text="Почати гру", font=("Arial", 14), command=start_game)
start_button.pack(padx=20, pady=20)

root.mainloop()
