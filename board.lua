local Board = {}

function Board.create(rows, columns, defaultValue)
  local board = {}
  board.rows = rows
  board.columns = columns
  board.data = {}

  for i=1,rows do
    board.data[i] = {}
    for j=1,columns do
      board.data[i][j] = defaultValue
    end
  end

  setmetatable(board, {
    __index = Board
  })
  return board
end

function Board:draw()
  local lines = {}
  local header = { " " }

  for i = 1, self.columns do
    header[#header + 1] = tostring(i)
  end
  lines[#lines + 1] = table.concat(header, " ")

  for i = 1, self.rows do
    local row = { tostring(i) }
    for j = 1, self.columns do
      row[#row + 1] = tostring(self.data[i][j])
    end
    lines[#lines + 1] = table.concat(row, " ")
  end

  print(table.concat(lines, "\n"))
end

function Board:setValue(row, column, value)
  self.data[row][column] = value
end

function Board:getValue(row, column)
  return self.data[row][column]
end

return Board