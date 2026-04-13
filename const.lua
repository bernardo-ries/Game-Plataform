local const = {
  games = {
    {
      name = 'Sudoku',
      filename = 'sudoku',
    },
    {
      name = 'Minesweeper',
      filename = 'minesweeper',
      difficulties = {
        { name = 'Easy', rows = 9, columns = 9, mines = 10 },
        { name = 'Medium', rows = 16, columns = 16, mines = 40 },
        { name = 'Hard', rows = 30, columns = 30, mines = 99 }
  }
}
  }
}

return const