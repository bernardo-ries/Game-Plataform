local Board = require('board')
local Minesweeper = {}

function Minesweeper.create(config)
  local game = {}
  game.config = config
  game.difficulty = nil
  game.board = nil
  game.visible = nil
  game.rows = 0
  game.columns = 0
  game.mines = 0
  game.flags = 0
  game.maxFlags = 0
  game.revealedCells = 0
  game.gameRunning = false
  game.startTime = 0
  game.cheat = false
  game.maxSolutions = 2000
  game.debug = false
  game.firstMove = true

  setmetatable(game, {
    __index = Minesweeper
  })

  return game
end

function Minesweeper:selectDifficulty()
  print("Select difficulty:")
  for i, difficulty in ipairs(self.config.difficulties) do
    print(i .. " - " .. difficulty.name)
  end
  print("0 - Cheat mode")
  local choice = readNumber("Choose the difficulty: ", 0, #self.config.difficulties, "Invalid choice. Try again.")
  if choice == 0 then
    print("Cheat mode activated")
    choice = readNumber("Select difficulty for cheat: ", 1, #self.config.difficulties, "Invalid choice. Try again.")
    self.cheat = true
  end

  self.difficulty = self.config.difficulties[choice]
  self.rows = self.difficulty.rows
  self.columns = self.difficulty.columns
  self.mines = self.difficulty.mines
  self.maxFlags = self.mines
end

function Minesweeper:startGame()
  self.flags = 0
  self.revealedCells = 0
  self.firstMove = true
  self:selectDifficulty()
  self.visible = Board.create(self.rows, self.columns, "#")
  self.board = nil
  self.gameRunning = true
  self.startTime = os.time()
end

function Minesweeper:generateBoard(firstRow, firstColumn)
  self.board = Board.create(self.rows, self.columns, 0)
  local placedMines = 0
  while placedMines < self.mines do
    local row = math.random(1, self.rows)
    local column = math.random(1, self.columns)
    if not (row == firstRow and column == firstColumn) then
      if self.board:getValue(row, column) ~= "X" then
        self.board:setValue(row, column, "X")
        placedMines = placedMines + 1
      end
    end
  end
end

function Minesweeper:countMinesAround(row, column)
  local count = 0
  for i = -1, 1 do
    for j = -1, 1 do
      local currentRow = row + i
      local currentColumn = column + j
      if not (i == 0 and j == 0) then
        if currentRow >= 1 and currentRow <= self.rows and currentColumn >= 1 and currentColumn <= self.columns then
          if self.board:getValue(currentRow, currentColumn) == "X" then
            count = count + 1
          end
        end
      end
    end
  end
  return count
end

function Minesweeper:calculateNumbers()
  for row = 1, self.rows do
    for column = 1, self.columns do
      if self.board:getValue(row, column) ~= "X" then
        local count = self:countMinesAround(row, column)
        self.board:setValue(row, column, count)
      end
    end
  end
end

function Minesweeper:getTime()
  return os.time() - self.startTime
end

function Minesweeper:printStatus()
  print("Time: " .. self:getTime() .. "s")
  print("Flags: " .. self.flags .. "/" .. self.maxFlags)
  print("Mines: " .. self.mines)
  print("Revealed cells: " .. self.revealedCells)
end

function Minesweeper:printGameScreen()
  self:printStatus()
  print("Game board:")
  self.visible:draw()
end

function Minesweeper:showCell(row, column)
  if self.visible:getValue(row, column) ~= "#" then
    return false
  end
  local value = self.board:getValue(row, column)
  self.visible:setValue(row, column, value)
  self.revealedCells = self.revealedCells + 1
  return true
end

function Minesweeper:checkVictory()
  local safeCells = self.rows * self.columns - self.mines
  return self.revealedCells == safeCells
end

function Minesweeper:putFlag(row, column)
  local currentValue = self.visible:getValue(row, column)
  if currentValue == "#" then
    if self.flags < self.maxFlags then
      self.visible:setValue(row, column, "F")
      self.flags = self.flags + 1
    else
      print("No flags left")
    end
  elseif currentValue == "F" then
    self.visible:setValue(row, column, "#")
    self.flags = self.flags - 1
  end
end

function Minesweeper:floodFill(row, column)
  for i = -1, 1 do
    for j = -1, 1 do
      local currentRow = row + i
      local currentColumn = column + j
      if not (i == 0 and j == 0) then
        if currentRow >= 1 and currentRow <= self.rows and currentColumn >= 1 and currentColumn <= self.columns then
          if self.visible:getValue(currentRow, currentColumn) == "#" then
            local value = self.board:getValue(currentRow, currentColumn)
            if value ~= "X" then
              local opened = self:showCell(currentRow, currentColumn)
              if opened and value == 0 then
                self:floodFill(currentRow, currentColumn)
              end
            end
          end
        end
      end
    end
  end
end

function Minesweeper:reveal(row, column)
  if self.visible:getValue(row, column) == "F" then
    print("Can't reveal a flagged cell, first remove the flag")
    return
  end
  if self.visible:getValue(row, column) ~= "#" then
    return
  end
  if self.firstMove then
    self:generateBoard(row, column)
    self:calculateNumbers()
    self.firstMove = false
  end
  local value = self.board:getValue(row, column)
  if value == "X" then
    self.visible:setValue(row, column, "X")
    self.gameRunning = false
    print("Game over, you hit a mine")
    return
  end
  self:showCell(row, column)
  if value == 0 then
    self:floodFill(row, column)
  end
  if self:checkVictory() then
    self.visible:draw()
    print("You win!")
    self.gameRunning = false
  end
end

function Minesweeper:isValid(row, column)
  return row >= 1 and row <= self.rows and column >= 1 and column <= self.columns
end

function Minesweeper:getNeighbors(row, column)
  local neighbors = {}
  for i = -1, 1 do
    for j = -1, 1 do
      local currentRow = row + i
      local currentColumn = column + j
      if not (i == 0 and j == 0) then
        if self:isValid(currentRow, currentColumn) then
          neighbors[#neighbors + 1] = { currentRow, currentColumn }
        end
      end
    end
  end
  return neighbors
end

function Minesweeper:getCellKey(row, column)
  return row .. ":" .. column
end

function Minesweeper:isNumberCell(row, column)
  local value = self.visible:getValue(row, column)
  return type(value) == "number" and value > 0
end

function Minesweeper:getFrontier()
  local frontier = {}
  local addedCells = {}
  for row = 1, self.rows do
    for column = 1, self.columns do
      if self:isNumberCell(row, column) then
        local neighbors = self:getNeighbors(row, column)
        for i = 1, #neighbors do
          local neighbor = neighbors[i]
          local currentRow = neighbor[1]
          local currentColumn = neighbor[2]
          if self.visible:getValue(currentRow, currentColumn) == "#" then
            local key = self:getCellKey(currentRow, currentColumn)
            if not addedCells[key] then
              frontier[#frontier + 1] = { currentRow, currentColumn }
              addedCells[key] = true
            end
          end
        end
      end
    end
  end
  return frontier
end

function Minesweeper:isValidSolution(testBoard)
  for row = 1, self.rows do
    for column = 1, self.columns do
      if self:isNumberCell(row, column) then
        local expected = self.visible:getValue(row, column)
        local neighbors = self:getNeighbors(row, column)
        local count = 0
        for i = 1, #neighbors do
          local neighbor = neighbors[i]
          local currentRow = neighbor[1]
          local currentColumn = neighbor[2]
          local key = self:getCellKey(currentRow, currentColumn)
          if self.visible:getValue(currentRow, currentColumn) == "F" then
            count = count + 1
          elseif testBoard[key] == "X" then
            count = count + 1
          end
        end
        if count ~= expected then
          return false
        end
      end
    end
  end

  return true
end

function Minesweeper:copyTable(original)
  local copy = {}
  for key, value in pairs(original) do
    copy[key] = value
  end
  return copy
end

function Minesweeper:dfs(frontier, index, testBoard, solutions)
  if #solutions >= self.maxSolutions then
    return
  end
  if index > #frontier then
    if self:isValidSolution(testBoard) then
      solutions[#solutions + 1] = self:copyTable(testBoard)
    end
    return
  end
  local cell = frontier[index]
  local row = cell[1]
  local column = cell[2]
  local key = self:getCellKey(row, column)
  testBoard[key] = "X"
  self:dfs(frontier, index + 1, testBoard, solutions)
  testBoard[key] = "S"
  self:dfs(frontier, index + 1, testBoard, solutions)
  testBoard[key] = nil
end

function Minesweeper:runDFS()
  local frontier = self:getFrontier()
  local solutions = {}
  local testBoard = {}
  if #frontier == 0 then
    return frontier, solutions
  end
  self:dfs(frontier, 1, testBoard, solutions)
  return frontier, solutions
end

function Minesweeper:analyzeSolutions(frontier, solutions)
  local certainMines = {}
  local certainSafe = {}
  if #solutions == 0 then
    return certainMines, certainSafe
  end
  for i = 1, #frontier do
    local cell = frontier[i]
    local row = cell[1]
    local column = cell[2]
    local key = self:getCellKey(row, column)
    local alwaysMine = true
    local alwaysSafe = true
    for j = 1, #solutions do
      if solutions[j][key] ~= "X" then
        alwaysMine = false
      end
      if solutions[j][key] ~= "S" then
        alwaysSafe = false
      end
    end
    if alwaysMine then
      certainMines[#certainMines + 1] = { row, column }
    elseif alwaysSafe then
      certainSafe[#certainSafe + 1] = { row, column }
    end
  end
  return certainMines, certainSafe
end

function Minesweeper:makeDFSMove()
  local frontier, solutions = self:runDFS()
  if not frontier or #frontier == 0 then
    return false
  end
  if #solutions == 0 then
    print("No valid solution found")
    return false
  end
  local certainMines, certainSafe = self:analyzeSolutions(frontier, solutions)
  local changed = false
  for i = 1, #certainMines do
    local row = certainMines[i][1]
    local column = certainMines[i][2]
    if self.visible:getValue(row, column) == "#" then
      print("Flagging cell: " .. row .. ", " .. column)
      self:putFlag(row, column)
      changed = true
    end
  end
  if not self.gameRunning then
    return changed
  end
  for i = 1, #certainSafe do
    local row = certainSafe[i][1]
    local column = certainSafe[i][2]
    if self.visible:getValue(row, column) == "#" then
      print("Opening cell: " .. row .. ", " .. column)
      self:reveal(row, column)
      changed = true
      if not self.gameRunning then
        return changed
      end
    end
  end
  if not changed then
    print("DFS found no certain move")
  end
  return changed
end

function Minesweeper:getHiddenCells()
  local hiddenCells = {}
  for row = 1, self.rows do
    for column = 1, self.columns do
      if self.visible:getValue(row, column) == "#" then
        hiddenCells[#hiddenCells + 1] = { row, column }
      end
    end
  end
  return hiddenCells
end

function Minesweeper:guessMove()
  local hiddenCells = self:getHiddenCells()
  if #hiddenCells == 0 then
    return false
  end
  local randomIndex = math.random(1, #hiddenCells)
  local cell = hiddenCells[randomIndex]
  local row = cell[1]
  local column = cell[2]
  print("No certain move found. Guessing cell: " .. row .. ", " .. column)
  self:reveal(row, column)
  return true
end

function Minesweeper:cheatTurn()
  local changed = self:makeDFSMove()
  if not self.gameRunning then
    return
  end
  if not changed then
    local guessed = self:guessMove()
    if not guessed then
      print("No move available")
      self.gameRunning = false
    end
  end
end

function Minesweeper:playerTurn()
  if self.debug then
    print("1 - Open cell")
    print("2 - Toggle flag")
    print("3 - DFS move")
  else
    print("1 - Open cell")
    print("2 - Toggle flag")
  end

  local maxOption = 2
  if self.debug then
    maxOption = 3
  end
  local action = readNumber("Choose action: ", 1, maxOption, "Invalid choice. Try again.")
  if action == 3 then
    self:makeDFSMove()
    return
  end
  local row = readNumber("Row: ", 1, self.rows, "Invalid row. Try again.")
  local column = readNumber("Column: ", 1, self.columns, "Invalid column. Try again.")
  self:handleAction(action, row, column)
end

function Minesweeper:handleAction(action, row, column)
  if action == 1 then
    self:reveal(row, column)
  else
    self:putFlag(row, column)
  end
end

function Minesweeper:runCheat()
  while self.gameRunning do
    self:printGameScreen()
    self:cheatTurn()
  end
end

function Minesweeper:run()
  print("Minesweeper is starting...")
  self:startGame()
  if self.cheat then
    print("Cheat mode is running...")
    self:runCheat()
    return
  end
  while self.gameRunning do
    self:printGameScreen()
    self:playerTurn()
  end
end

return Minesweeper