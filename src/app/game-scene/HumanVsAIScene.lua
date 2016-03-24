----------------------------
--版权:
--作者: liubo (564773807@qq.com)
--时间: 2016-03-18 19:10:20
--作用:
--备注:
----------------------------

local HumanVsAIScene = class("HumanVsAIScene", require("app.game-scene.GameBaseScene"))
local AI = require("app.game-scene.AI")

local computer = WHITE
local human = BLACK

function HumanVsAIScene:onCreate()
    Log.d("人机对弈")

    --设置悔棋步数
    self:setRetractChessStep(2)

    self:isComputerFirst(true)

    self._chessboard:addTouchCallFunc(function(row, col)
        if self._chessboard:getNextTurnChessType() == human then
            -- self._chessboard:addChess(row, col)

            AI.setComputerChessType(human)
            Log.d("aiAddChess() color = " .. human)
            self:aiAddChess()
        end
        if self._chessboard:getNextTurnChessType() == computer then
            AI.setComputerChessType(computer)
            -- self:aiAddChess()
            self:aiAddChessByFeatureStep(0)

        end
    end)

    --重玩
    self:addButton(nil, "计算机下子", 50, display.visiblesizeWidth / 2, display.visibleoriginX + 50, function(sender, eventType)
    end)

end

--必须设置（在下子前设置）
function HumanVsAIScene:isComputerFirst(flag)
    if flag then
        self._chessboard:addChess(8, 8)
        computer = self._chessboard:getFirstChessType()
        human = self._chessboard:getBehindChessType()
    else
        human = self._chessboard:getFirstChessType()
        computer = self._chessboard:getBehindChessType()
    end

    AI.setComputerChessType(computer)
end

function HumanVsAIScene:aiAddChess()
    local position = AI.getMaxSorcePoint(self._chessboard:getChessBoardArray())
    self._chessboard:addChess(position.row, position.col)
end

function HumanVsAIScene:aiAddChessByFeatureStep(depth)
    local position = AI.getNextPlayChessPosition(self._chessboard:getChessBoardArray(), depth)
    self._chessboard:addChess(position.row, position.col)
end

return HumanVsAIScene