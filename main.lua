display.setStatusBar(display.HiddenStatusBar)
local physics = require('physics')
local storyboard 		= require "storyboard"
local scene 			= storyboard.newScene()
physics.start()
--physics.setGravity( 0, 9.8 )
math.randomseed( os.time() )
local w = display.contentWidth
local h = display.contentHeight
local bg
bg = display.newRect( w/2, h/2, w, h )
bg:setFillColor( 74/255, 57/255, 55/255 )
local background
local logo 
local oLetter
local playBtn
local creditsBtn
local titleView = display.newGroup()
local creditsView
local circles = display.newGroup()
local bar
local left
local right
local bottom
local ins
local score
local alertView
local bounceSnd = audio.loadSound('bounce.wav')
local loseSnd = audio.loadSound('lose.wav')
local circleTimer
local colors = {{255/255, 100/255, 100/255}, {100/255, 255/255, 100/255}, {100/255, 100/255, 255/255},}
local startButtonListeners = {}
local showCredits = {}
local hideCredits = {}
local showGameView = {}
local gameListeners = {}
local moveBar = {}
local addCircle ={}
local onCollision = {}
local alert = {}
local gameBG
local gcButton




background = display.newImage( 'bg.png' )
oLetter = display.newImage( 'oLetter.png', w/2-45, h/2-169)
oLetter.xScale = 0.5
oLetter.yScale = 0.5
logo = display.newImage( 'logo.png', w/2, h/2-180)
logo.xScale = 0.5
logo.yScale = 0.5
playBtn = display.newImage('playBtn.png', w/2, h/2+50 )
playBtn.xScale = 0.3
playBtn.yScale = 0.3
creditsBtn = display.newImage('creditsBtn.png', w/2, h/2+120 )
creditsBtn.xScale = 0.3
creditsBtn.yScale = 0.3
gcBtn = display.newImage('gc.png', w/2, h/2+190)
gcBtn.xScale = 0.3
gcBtn.yScale = 0.3

	-- MENU ANIMATIONS --
    local dir = "up"
    local function transComplete()
     
        if dir == "up" then
            transition.to ( oLetter, { y=oLetter.y-30, time=500, tag="titleAnims", onComplete=transComplete, transition=easing.outQuad } )
            transition.to ( playBtn, { xScale=0.33, time=900, tag="titleAnims", transition=easing.outQuad } )
            transition.to ( creditsBtn, { yScale=0.36, time=900, tag="titleAnims", transition=easing.outQuad } )
			transition.to ( gcBtn, { xScale=0.33, time=900, tag="titleAnims", transition=easing.outQuad } )
            dir = "down"
        elseif dir == "down" then
        	transition.to ( oLetter, { y=oLetter.y+30, time=500, tag="titleAnims", onComplete=transComplete, transition=easing.inQuad } )
            transition.to ( playBtn, { xScale=0.3, time=900, tag="titleAnims", transition=easing.outQuad } )
            transition.to ( creditsBtn, { yScale=0.3, time=500, tag="titleAnims", transition=easing.outQuad } )
			transition.to ( gcBtn, { xScale=0.3, time=500, tag="titleAnims", transition=easing.outQuad } )
            dir = "up"
        end
    end
    transComplete()


function startButtonListeners(action)
	if(action == 'add') then
		playBtn:addEventListener('tap', showGameView)
		creditsBtn:addEventListener('tap', showCredits)
	else
		playBtn:removeEventListener('tap', showGameView)
		creditsBtn:removeEventListener('tap', showCredits)
	end
end

startButtonListeners('add')
titleView:insert(background)
titleView:insert(playBtn)
titleView:insert(logo)
titleView:insert(oLetter)
titleView:insert(creditsBtn)
titleView:insert(gcBtn)




function showCredits:tap(e)
	playBtn.isVisible = false
	creditsBtn.isVisible = false
	gcBtn.isVisible = false
	creditsView = display.newImage('credits.png', w/2, h/2+500)
	
	transition.to(creditsView, {time = 300, y = display.contentHeight - (creditsView.height - 40), transition=easing.inOutExpo, onComplete = function() creditsView:addEventListener('tap', hideCredits) end})
end

function hideCredits:tap(e)
	transition.to(creditsView, {time = 300, y = display.contentHeight + 40, onComplete = function() creditsBtn.isVisible = true playBtn.isVisible = true gcBtn.isVisible = true creditsView:removeEventListener('tap', hideCredits) display.remove(creditsView) creditsView = nil end})
end

function showGameView:tap(e)
	transition.to(titleView, {time = 300, x = -titleView.height, onComplete = function() startButtonListeners('rmv') display.remove(titleView) titleView = nil end})
	bar = display.newRect(w/2, 400, 70, 8)
	bar.name = 'bar'
	
	-- Instructions Message
	local ins = display.newImage('instructions.png', w/2, h/2-50)
	ins.xScale = 0.45
	ins.yScale = 0.45
	transition.from(ins, {time = 200, alpha = 0.1, onComplete = function() timer.performWithDelay(2000, function() transition.to(ins, {time = 200, alpha = 0.1, onComplete = function() display.remove(ins) ins = nil end}) end) end})
	-- Walls
	left = display.newRect( w-20, h/2, 10, h )
	left.isVisible = false
	right = display.newRect( w-300, h/2, 10, h )
	right.isVisible = false
	bottom = display.newRect( w/2, h+5, w, 10 )
	bottom.isVisible = false

	
	score = display.newText('0', 300, 0, 'GeosansLight', 15)

	physics.addBody(bar, 'static', {filter = {categoryBits = 4, maskBits = 7}})
	bar.isBullet = true
	physics.addBody(left, 'static', {filter = {categoryBits = 4, maskBits = 7}})
	physics.addBody(right, 'static', {filter = {categoryBits = 4, maskBits = 7}})
	physics.addBody(bottom, 'static', {filter = {categoryBits = 4, maskBits = 7}})
	
	gameListeners('add')
end

function gameListeners(action)
	if(action == 'add') then
		bg:addEventListener('touch', moveBar)
		circleTimer = timer.performWithDelay(2000, addCircle, 4)
		bar:addEventListener('collision', onCollision)
		bottom:addEventListener('collision', alert)
	else
		bg:removeEventListener('touch', moveBar)
		timer.cancel(circleTimer)
		circleTimer = nil
		bar:removeEventListener('collision', onCollision)
		bottom:removeEventListener('collision', alert)
	end
end

function moveBar(e)
	if(e.phase == 'moved') then
		bar.x = e.x
	end
	--[[if(bar.x > display.contentWidth - 60) then
		bar.x = display.contentWidth - 60
	elseif(bar.x < display.contentWidth - 260) then
		bar.x = display.contentWidth - 260
	end--]]
end

function addCircle()
	local r = math.floor(math.random() * 8) + 12
	local c = display.newCircle(0, 0, r)
	c.x = math.floor(math.random() * (display.contentWidth - (r * 2)))
	--c.strokeWidth = 1
	--c:setStrokeColor( 0, 0, 0 )
	c.y =  - (r * 2)
	local color = math.floor(math.random(1, 3))
	c.c1 = colors[color][1]
	c.c2 = colors[color][2]
	c.c3 = colors[color][3]
	c:setFillColor(c.c1, c.c2, c.c3)
	physics.addBody(c, 'dynamic', {radius = r, bounce = 0.95, filter = {categoryBits = 2, maskBits = 4}})
	c.isBullet = true
	circles:insert(c)

	--Move Horizontally
	local dir
	if(r < 18) then dir = -1 else dir = 1 end
	c:setLinearVelocity((r*2) * dir, 0 )
end



function onCollision(e)
	if(e.phase == "ended") then
		audio.play(bounceSnd)
		transition.to( e.other, { time = 50, yScale =  0.5, onComplete = function() transition.to( e.other, { time = 50, yScale =  1 } ) end } ) 
		--bar:setFillColor(e.other.c1, e.other.c2, e.other.c3)
		score.text = tostring(tonumber(score.text) + 50)
		score.x = w/2
		score.y = h/2 - 230
	end
end

function alert()
	audio.play(loseSnd)
	gameListeners('rmv')
	local losebg = display.newRect(w/2, h/2, 200, 200)
	local retry = display.newImage('retry.png', w/2, h/2+40)
	retry.xScale = 0.2
	retry.yScale = 0.2
	local gc = display.newImage('gc.png', w/2-60, h/2+79)
	gc.xScale = 0.2
	gc.yScale = 0.2
	local back = display.newImage('back.png', w/2+60, h/2+75)
	back.xScale = 0.2
	back.yScale = 0.2
	losebg.alpha = 0.8
	local scoreTF = display.newText("Score: " .. score.text, w/2, h/2-50, 'GeosansLight', 27)
	scoreTF:setTextColor(0, 0, 0)
	
	timer.performWithDelay(200, function() physics.stop() end, 1)
end





-----------------------------------------------------------------------------------------
