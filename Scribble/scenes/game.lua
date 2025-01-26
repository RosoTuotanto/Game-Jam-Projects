local composer = require("composer")
local scene = composer.newScene()

---------------------------------------------------------------------------

-- Common plugins, modules, libraries & classes.
local screen = require("classes.screen")
local bubble = require("classes.bubble")
local loadsave, savedata

---------------------------------------------------------------------------

-- Forward declarations & variables.
local title, instructions, startButton, buttonAudio, buttonRestart, kevinText
local highscoreText, scoreText, wordsTitle, wordText, bubbleCounter, currentWordCounter
local timerBubble
local highscore = 0
local score = 0
local popCount = 0
local gameActive = false
local currentWord = ""
local scoredWord = {}
local gameover

local bubbleSpawnTime = 500
local bubbleSpawnVarMin = 250
local bubbleSpawnVarMax = 1500

local container = display.newContainer( screen.width - 105, screen.height - 24 )
container.x, container.y = screen.centerX, screen.centerY + 2

local groupStats = display.newGroup()
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
-- Add two random letters to the mix so that the gameLetters add up to 100.
gameLetter[#gameLetter+1] = string.char( math.random( 65, 90 ) )
gameLetter[#gameLetter+1] = string.char( math.random( 65, 90 ) )

-- Original word list iswords_alpha.txt from https://github.com/dwyl/english-words.
-- The file has been modified to only include words consisting of 3-7 characters.
local path = system.pathForFile( "data/words.txt", system.ResourceDirectory )
local file = io.open( path, "r" )

local wordList = {}
-- List of approved words.
for line in file:lines() do
	-- Further filtering out words that are too short, because the word list
	-- seems to include lots of 3 non-fun & weird letter abbreviations.
	if string.len( line ) > 3 then
		wordList[line] = true
	end
end
io.close( file )
path, file = nil, nil -- luacheck: ignore

---------------------------------------------------------------------------



---------------------------------------------------------------------------

-- Functions.
local function resetSelection()
	currentWord = ""

	for i = 1, #bubblePiece do
		if bubblePiece[i] and bubblePiece[i].isActive then
			bubblePiece[i]:pop()
		end
	end

	currentWordCounter.text = "_ _ _ _ _ _"
end

local function selectBubble( whichBubble )
	-- print("selectBubble", whichBubble.letter )

	currentWord = currentWord .. whichBubble.letter
	print("currentWord", currentWord, wordList[string.lower(currentWord)] )

	local len = string.len( currentWord )
	currentWordCounter.text = ""

	for i = 1, 6 do
		local char
		if i <= len then
			char = string.sub( currentWord, i, i )
		else
			char = "_"
		end

		currentWordCounter.text = currentWordCounter.text .. char
	end

	-- The word list is in lowercase.
	if wordList[string.lower(currentWord)] then
		audio.play( "assets/audio/score.wav" )

		local wordValue = 0

		-- Just hacking the score from the string as I don't have the time
		-- to fix the bug with the bubbles and their properties.
		for i = 1, string.len( currentWord ) do
			local letter = string.sub( currentWord, i, i )
			wordValue = wordValue + dataLetters[letter].value
		end

		score = score + wordValue
		scoreText.text = "SCORE: " .. score

		if score > highscore then
			highscore = score
			highscoreText.text = "HIGHSCORE:  " .. highscore

			savedata.highscore = highscore
			loadsave.save( savedata, "data.json" )
		end

		scoredWord[#scoredWord+1] = currentWord

		wordText.text = ""

		for i = 1, 5 do
			if scoredWord[i] then
				wordText.text = wordText.text .. scoredWord[i] .. "\n\n"
			else
				wordText.text = wordText.text .. "-\n\n"
			end
		end

		resetSelection()

		if #scoredWord == 5 then
			gameover()
		end

	-- Word is too long, so pop all bubbles.
	elseif len == 6 then
		resetSelection()
	end

end


local function popBubble( whichBubble )
	-- print("popBubble", whichBubble.letter )

	popCount = popCount + 1

	local bubblesLeft = #gameLetter - popCount

	bubbleCounter.text = "BUBBLES LEFT:\n\n" .. bubblesLeft

	if gameActive and whichBubble.isActive then
		whichBubble.isActive = false
		resetSelection()

	end

	if bubblesLeft == 0 then
		gameover()
	end
end


local function createBubble()
	bubblePiece[#bubblePiece+1] = bubble.new( container, gameLetter[#bubblePiece+1], selectBubble, popBubble )
end

function gameover()
	if gameActive then
		gameActive = false

		-- These aren't useful after the game ends.
		bubbleCounter.isVisible = false
		currentWordCounter.isVisible = false
		buttonRestart.isVisible = false

		groupStats.y = 140

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

			title.isVisible, instructions.isVisible, startButton.isVisible, kevinText.isVisible = true, true, true, true
		end )
	end
end



local function startGame( event )
	if not gameActive and event.phase == "ended" then
		gameActive = true

		title.isVisible, instructions.isVisible, startButton.isVisible, kevinText.isVisible = false, false, false, false
		buttonRestart.isVisible = true
		audio.play( "assets/audio/pop" .. math.random(2,4) .. ".wav" )

		table.shuffle( gameLetter )
		scoredWord = {}
		popCount = 0
		score = 0

		-- Toggle them visible once the game starts and then just shift their position.
		highscoreText.isVisible = true
		scoreText.isVisible = true
		wordsTitle.isVisible = true
		wordText.isVisible = true
		bubbleCounter.isVisible = true
		currentWordCounter.isVisible = true

		groupStats.y = 0

		scoreText.text = "SCORE: 0"
		wordText.text = "-\n\n-\n\n-\n\n-\n\n-" -- 5 lines
		bubbleCounter.text = "BUBBLES LEFT:\n\n" .. #gameLetter
		currentWordCounter.text = "_ _ _ _ _ _"

		timerBubble = timer.performWithDelay( bubbleSpawnTime + math.random( bubbleSpawnVarMin, bubbleSpawnVarMax ), createBubble, #gameLetter )
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
		y = screen.minY + 110,
		font = "assets/fonts/ff-comma-trial.regular.ttf",
		fontSize = 92
	})
	title:setFillColor( 0 )


	instructions = display.newText({
		parent = sceneGroup,
		text = "HOW TO PLAY:\n\n1. TAP BUBBLES TO SPELL WORDS.\n\n2. VALID WORDS BETWEEN 4 and 6 CHARACTERS SCORE AUTOMATICALLY. IF A WORD IS TOO LONG, THEN ALL TAPPED BUBBLES POP AND THE WORD IS LOST!\n\n3. IF A BUBBLE ESCAPES OR IS TAPPED TWICE, IT POPS!\n\n4. WHEN A BUBBLE THAT HAS BEEN TAPPED POPS, THEN ALL TAPPED BUBBLES POP!\n\n5. GAME ENDS AFTER SCORING 5 WORDS OR AFTER BUBBLES RUN OUT.",
		x = screen.centerX - 70,
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
		y = screen.maxY - 64,
		font = "assets/fonts/ff-comma-trial.regular.ttf",
		fontSize = 40
	})
	startButton:setFillColor( 0 )
	startButton.yStart = startButton.y

	-- Add continuous transitoons.
	transition.to( startButton, { time = 3500, alpha = 0.5, xScale=1.1, yScale=1.1, y=startButton.yStart - 2, transition=easing.continuousLoop, iterations = -1 } )

	startButton:addEventListener( "touch", startGame )

	---------------------------------------------------------------------------

	kevinText = display.newText({
		parent = sceneGroup,
		text = "MUSIC:\n\n\"GYMNOPEDIE NO. 1\" KEVIN MACLEOD (INCOMPETECH.COM) LICENSED UNDER CREATIVE COMMONS: BY ATTRIBUTION 4.0 LICENSE HTTP://CREATIVECOMMONS.ORG/LICENSES/BY/4.0/",
		x = screen.centerX + 310,
		y = screen.centerY - 270,
		width = 360,
		font = "assets/fonts/ff-comma-trial.regular.ttf",
		fontSize = 11,
		align = "center"
	})
	kevinText:setFillColor( 0 )
	kevinText.rotation = 6

	---------------------------------------------------------------------------
	-- Audio control & restart button.

	buttonAudio = display.newText({
		parent = sceneGroup,
		text = "SOUND: " .. (savedata.audio and "ON" or "OFF"),
		x = screen.minX + 68,
		y = screen.minY + 28,
		font = "assets/fonts/ff-comma-trial.regular.ttf",
		fontSize = 18
	})
	buttonAudio:setFillColor( 0 )
	buttonAudio.anchorX, buttonAudio.anchorY = 0, 0

	buttonAudio:addEventListener( "touch", function( event )
		if event.phase == "ended" then
			savedata.audio = not savedata.audio
			buttonAudio.text = "SOUND: " .. (savedata.audio and "ON" or "OFF")
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
			audio.play( "assets/audio/pop" .. math.random(2,4) .. ".wav" )
			gameover()
		end
	end )

	---------------------------------------------------------------------------
	-- Highscore, score, bubble counter and word list.

	highscoreText = display.newText({
		parent = groupStats,
		text = "HIGHSCORE:  " .. highscore,
		x = screen.maxX - 240,
		y = screen.minY + 30,
		font = "assets/fonts/ff-comma-trial.regular.ttf",
		align = "left",
		fontSize = 18
	})
	highscoreText:setFillColor( 0 )
	highscoreText.anchorX, highscoreText.anchorY = 0, 0
	highscoreText.yStart = highscoreText.y
	highscoreText.isVisible = false

	scoreText = display.newText({
		parent = groupStats,
		text = "SCORE: 0",
		x = highscoreText.x + 43,
		y = highscoreText.y +  30,
		font = "assets/fonts/ff-comma-trial.regular.ttf",
		align = "left",
		fontSize = 18
	})
	scoreText:setFillColor( 0 )
	scoreText.anchorX, scoreText.anchorY = 0, 0
	scoreText.yStart = scoreText.y
	scoreText.isVisible = false


	wordsTitle = display.newText({
		parent = groupStats,
		text = "WORDS FOUND:",
		x = scoreText.x + 50,
		y = scoreText.y + 60,
		font = "assets/fonts/ff-comma-trial.regular.ttf",
		align = "center",
		fontSize = 18
	})
	wordsTitle:setFillColor( 0 )
	wordsTitle.anchorY = 0
	wordsTitle.yStart = wordsTitle.y
	wordsTitle.isVisible = false


	wordText = display.newText({
		parent = groupStats,
		text = "",
		x = wordsTitle.x,
		y = wordsTitle.y + 40,
		-- width = 200,
		font = "assets/fonts/ff-comma-trial.regular.ttf",
		align = "center",
		fontSize = 18
	})
	wordText:setFillColor( 0 )
	wordText.anchorY = 0
	wordText.yStart = wordText.y
	wordText.isVisible = false


	bubbleCounter = display.newText({
		parent = groupStats,
		text = "",
		x = wordText.x,
		y = wordText.y + 220,
		font = "assets/fonts/ff-comma-trial.regular.ttf",
		align = "center",
		fontSize = 18
	})
	bubbleCounter:setFillColor( 0 )
	bubbleCounter.anchorY = 0
	bubbleCounter.isVisible = false

	sceneGroup:insert( groupStats )

	---------------------------------------------------------------------------

	currentWordCounter = display.newText({
		parent = sceneGroup,
		text = "",
		x = screen.centerX,
		y = screen.maxY - 64,
		font = "assets/fonts/ff-comma-trial.regular.ttf",
		fontSize = 60
	})
	currentWordCounter:setFillColor( 0 )
	currentWordCounter.isVisible = false

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