local composer = require("composer")
local scene = composer.newScene()

---------------------------------------------------------------------------

-- Common plugins, modules, libraries & classes.
local screen = require("classes.screen")
local bubble = require("classes.bubble")
local loadsave, savedata

---------------------------------------------------------------------------

-- Forward declarations & variables.
local title, instructions, startButton, buttonAudio, buttonRestart
local timerBubble
local highscore = 0
local gameActive = false


local container = display.newContainer( screen.width - 105, screen.height - 24 )
container.x, container.y = screen.centerX, screen.centerY + 2

-- local groupBubble = display.newGroup()
local bubblePiece = {}
-- Checking container bounds.
-- local rect = display.newRect( container, 0, 0, screen.width, screen.height )
-- rect:setFillColor( 1, 0, 0, 0.5 )

---------------------------------------------------------------------------

-- Set up letter distribution and word list.
local dataLetters = require("data.letters")
local gameLetter = {}

for letter, data in pairs( dataLetters ) do
	for _ = 1, data.count do
		gameLetter[#gameLetter+1] = letter
	end
end


-- Original word list iswords_alpha.txt from https://github.com/dwyl/english-words.
-- The file has been modified to only include words consisting of 3-7 characters.
local path = system.pathForFile( "data/words.txt", system.ResourceDirectory )
local file = io.open( path, "r" )

local wordList = {}
-- List of approved words.
for line in file:lines() do
	wordList[line] = true
end
io.close( file )
path, file = nil, nil -- luacheck: ignore

---------------------------------------------------------------------------



---------------------------------------------------------------------------

-- Functions.
-- local function

local function createBubble()
	bubblePiece[#bubblePiece+1] = bubble.new( container, gameLetter[#bubblePiece+1] )
end

local function gameover()
	if gameActive then
		gameActive = false

		timer.cancel( timerBubble )

		for i = 1, #gameLetter do
			if bubblePiece[i] then
				bubblePiece[i]:pop()
			end
		end

		timer.performWithDelay( 500, function()
			for i = 1, #bubblePiece do
				bubblePiece[i] = nil
			end

			title.isVisible, instructions.isVisible, startButton.isVisible = true, true, true
			buttonRestart.isVisible = false
		end )
	end
end



local function startGame( event )
	if not gameActive and event.phase == "ended" then
		gameActive = true

		title.isVisible, instructions.isVisible, startButton.isVisible = false, false, false
		buttonRestart.isVisible = true
		audio.play( "assets/audio/pop" .. math.random(4) .. ".wav" )

		-- local lettersInGame = letterData
		table.shuffle( gameLetter )

		timerBubble = timer.performWithDelay( 750, createBubble, #gameLetter)
	end
end


---------------------------------------------------------------------------


function scene:create( event )
	local sceneGroup = self.view
	-- If the project uses savedata, then load existing data or set it up.
	if event.params and event.params.usesSavedata then
		loadsave = require("classes.loadsave")
		savedata = loadsave.load("data.json")

		if not savedata then
			-- Assign initial values for save data.
			savedata = {
				highscore = 0,
				audio = true,
			}
			loadsave.save( savedata, "data.json" )
		end

		-- Assign/update variables based on save data, e.g. volume, highscores, etc.

	end

	highscore = savedata.highscore or 0

	audio.loadStream( "assets/audio/Gymnopedie No 1.mp3" )

	local background = display.newImageRect( sceneGroup, "assets/images/background.png", screen.width, screen.height )
	background.x, background.y = screen.centerX, screen.centerY

	---------------------------------------------------------------------------
	-- Title text, instructions and start button.

	title = display.newText({
		parent = sceneGroup,
		text = "Scribble",
		x = screen.centerX,
		y = screen.minY + 100,
		font = "assets/fonts/ff-comma-trial.regular.ttf",
		fontSize = 92
	})
	title:setFillColor( 0 )


	instructions = display.newText({
		parent = sceneGroup,
		text = "HOW TO PLAY:\n\n1. TAP BUBBLES TO SPELL WORDS.\n\n2. VALID WORDS SCORE AUTOMATICALLY.\n\n3. IF A BUBBLE ESCAPES OR IS TAPPED TWICE, IT POPS!\n\n4. WHEN A BALLOON THAT HAS BEEN TAPPED POPS, THEN ALL TAPPED BALLOONS POP!\n\n5. GAME ENDS AFTER SCORING 5 WORDS OR AFTER BUBBLES RUN OUT.",
		x = screen.centerX,
		y = screen.centerY + 30,
		width = screen.width - 320,
		font = "assets/fonts/ff-comma-trial.regular.ttf",
		fontSize = 22
	})
	instructions:setFillColor( 0 )

	startButton = display.newText({
		parent = sceneGroup,
		text = "Tap Here to Start",
		x = screen.centerX,
		y = screen.maxY - 80,
		font = "assets/fonts/ff-comma-trial.regular.ttf",
		fontSize = 40
	})
	startButton:setFillColor( 0 )
	startButton.yStart = startButton.y

	-- Add continuous transitoons.
	transition.to( startButton, { time = 3500, alpha = 0.5, xScale=1.1, yScale=1.1, y=startButton.yStart - 2, transition=easing.continuousLoop, iterations = -1 } )

	startButton:addEventListener( "touch", startGame )


	---------------------------------------------------------------------------
	-- Audio control & restart button.

	buttonAudio = display.newText({
		parent = sceneGroup,
		text = "MUSIC: " .. (savedata.audio and "ON" or "OFF"),
		x = screen.minX + 64,
		y = screen.minY + 30,
		font = "assets/fonts/ff-comma-trial.regular.ttf",
		fontSize = 18
	})
	buttonAudio:setFillColor( 0 )
	buttonAudio.anchorX, buttonAudio.anchorY = 0, 0

	buttonAudio:addEventListener( "touch", function( event )
		if event.phase == "ended" then
			savedata.audio = not savedata.audio
			buttonAudio.text = "MUSIC: " .. (savedata.audio and "ON" or "OFF")
			loadsave.save( savedata, "data.json" )

			if savedata.audio then
				audio.setVolume( 0.5 )
			else
				audio.setVolume( 0 )
			end
		end
	end )

	if savedata.audio then
		audio.setVolume( 0.5 )
	else
		audio.setVolume( 0 )
	end

	buttonRestart = display.newText({
		parent = sceneGroup,
		text = "RESTART",
		x = buttonAudio.x,
		y = screen.minY + 70,
		font = "assets/fonts/ff-comma-trial.regular.ttf",
		fontSize = 18
	})
	buttonRestart:setFillColor( 0 )
	buttonRestart.anchorX, buttonRestart.anchorY = 0, 0
	buttonRestart.isVisible = false

	buttonRestart:addEventListener( "touch", function( event )
		if event.phase == "ended" then
			audio.play( "assets/audio/pop" .. math.random(4) .. ".wav" )
			gameover()
		end
	end )
end


---------------------------------------------------------------------------


function scene:show( event )
	local sceneGroup = self.view

	if event.phase == "will" then
		-- If coming from launchScreen scene, then start by removing it.
		if composer._previousScene == "scenes.launchScreen" then
			composer.removeScene( "scenes.launchScreen" )
		end

	elseif event.phase == "did" then
		audio.setVolume( 0.5, { channel=1 } )
		audio.play( "assets/audio/Gymnopedie No 1.mp3", { channel = 1, loops = -1 } )

		for i = 2, 32 do
			audio.setVolume( 0.3, { channel=i } )
		end
	end
end

---------------------------------------------------------------------------

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )

---------------------------------------------------------------------------

return scene