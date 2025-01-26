-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------
display.setStatusBar( display.HiddenStatusBar )

local physics = require( "physics" )
physics.start()
physics.setGravity( 0, 0 )

math.randomseed( os.time() )

display.setDefault( "magTextureFilter", "nearest" )

local sheetOptionsPlayer =
{
    width = 32,
    height = 32,
    numFrames = 1
}

local playerSheet = graphics.newImageSheet( "assets/player.png", sheetOptionsPlayer )

local sheetOptionsBubble = 
{
    width = 64,
    height = 64,
    numFrames = 3
}

local bigBubbleSheet = graphics.newImageSheet( "assets/bigbubble.png", sheetOptionsBubble )

local bubbleSequenceData =
{
    { name="1", frames={ 1 }},
    { name="2", frames={ 2 } },
    { name="3", frames={ 3 }}
}
 


local sheetOptionsEnemy = 
{
    width = 48,
    height = 48,
    numFrames = 1
}

local enemySheet = graphics.newImageSheet( "assets/enemy.png", sheetOptionsEnemy )


-- Variables

local died = false
local bubbleFrameIndex = 1
local maxhp = 3
local hp = 2

local invulnerableTime = 500
local lastHitTime

local enemyTable = {}
local bubbleTable = {}

local player
local selfBubble
local gameLoopTimer

local backGroup = display.newGroup()
local mainGroup = display.newGroup()


local background = display.newImageRect( backGroup, "assets/background.png", 640, 360 )
background.x = display.contentCenterX
background.y = display.contentCenterY


player = display.newImageRect( mainGroup, playerSheet, 1, 32, 32)
player.x = display.contentCenterX
player.y = display.contentHeight - 36
physics.addBody( player)
player.myName = "player"


selfBubble = display.newSprite( bigBubbleSheet, bubbleSequenceData )
selfBubble.x = player.x
selfBubble.y = player.y
physics.addBody( selfBubble, { radius=20, isSensor = true } )
selfBubble.myName = "selfBubble"
selfBubble:setSequence(tostring( hp ))


local function createEnemy()

    local newEnemy = display.newImageRect( mainGroup, enemySheet, 1, 48, 48 )
    table.insert( enemyTable, newEnemy )
    physics.addBody( newEnemy, { box, 12, 21,}  )
    newEnemy.myName = "enemy"

    newEnemy.isSensor = true
    local whereFrom = math.random( 3 )

    if whereFrom == 1 then
        -- Left
        newEnemy.x = -60
        newEnemy.y = math.random( 60 )
        newEnemy:setLinearVelocity( math.random( 40,120 ), math.random (20,60 ) )
    elseif whereFrom == 2 then
        -- Top
        newEnemy.x = math.random( display.contentWidth )
        newEnemy.y = -60
        newEnemy:setLinearVelocity( math.random( -40,40 ), math.random( 40,120) )
    elseif whereFrom == 3 then
        -- Right
        newEnemy.x = display.contentWidth + 60
        newEnemy.y = math.random( 60 )
        newEnemy:setLinearVelocity( math.random( -120, -40 ), math.random( 20, 60) )
    end
end

local function createBubble()

    local newBubble = display.newImageRect( mainGroup, "assets/smallbubble.png" ,  16, 16 )
    table.insert( bubbleTable, newBubble )
    physics.addBody( newBubble, {radius=8} )
    newBubble.myName = "bubble"

    newBubble.isSensor = true
    local whereFrom = math.random( 3 )

    if whereFrom == 1 then
        -- Left
        newBubble.x = -60
        newBubble.y = math.random( 60 )
        newBubble:setLinearVelocity( math.random( 40,120 ), math.random (20,60 ) )
    elseif whereFrom == 2 then
        -- Top
        newBubble.x = math.random( display.contentWidth )
        newBubble.y = -60
        newBubble:setLinearVelocity( math.random( -40,40 ), math.random( 40,120) )
    elseif whereFrom == 3 then
        -- Right
        newBubble.x = display.contentWidth + 60
        newBubble.y = math.random( 60 )
        newBubble:setLinearVelocity( math.random( -120, -40 ), math.random( 20, 60) )
    end
end


local function shootTrident()

    local newTrident = display.newImageRect( mainGroup, "assets/trident.png", 16, 32 )
    physics.addBody( newTrident, { isSensor=true } )
    newTrident.isBullet = true
    newTrident.myName = "trident"

    newTrident.x = player.x
    newTrident.y = player.y - 5
    newTrident:toBack()

    transition.to( newTrident, { y=-40, time=500,
        onComplete = function() display.remove( newTrident ) end
    } )
end

Runtime:addEventListener( "tap", shootTrident )


local pressedKeys = {}

    local function onKeyEvent( event )
        if event.phase == "down" then
            pressedKeys[event.keyName] = true
        else
            pressedKeys[event.keyName] = false
        end
    end

   local function onEnterFrame( event )
    if pressedKeys["a"] then
        player.x  = player.x - 5
        selfBubble.x = selfBubble.x - 5
    end
    if pressedKeys["d"] then
        player.x = player.x + 5
        selfBubble.x = selfBubble.x + 5
    end
       
end

Runtime:addEventListener( "key", onKeyEvent )
Runtime:addEventListener( "enterFrame", onEnterFrame )

local gameLoop, spawnEnemy

function spawnEnemy()
    print("spawnEnemy")
    gameLoopTimer = timer.performWithDelay( math.random (500, 1000), gameLoop )
end


function gameLoop()
    print("gameLoop")
    -- Spawn enemy
    createEnemy()
   
    -- Remove enemies off screen
    for i = #enemyTable, 1, -1 do
        local thisEnemy = enemyTable[i]
        
        if ( thisEnemy.x < -100 or 
             thisEnemy.x > display.contentWidth + 100 or
             thisEnemy.y < -100 or
             thisEnemy.y > display.contentHeight + 100 )
        then
            display.remove( thisEnemy )
            table.remove( enemyTable, i )
        end
    end
    spawnEnemy()

end  
spawnEnemy()

local bubbleLoop, spawnBubble

function spawnBubble()
    bubbleLoopTimer = timer.performWithDelay( math.random (2000, 5000), bubbleLoop )
end

function bubbleLoop()
    createBubble()
    -- Remove bubbles off screen
    for i = #bubbleTable, 1, -1 do
        local thisBubble = bubbleTable[i]
        
        if ( thisBubble.x < -100 or 
            thisBubble.x > display.contentWidth + 100 or
            thisBubble.y < -100 or
            thisBubble.y > display.contentHeight + 100 )
        then
            display.remove( thisBubble )
            table.remove( bubbleTable, i )
        end
    end

    spawnBubble()
end
spawnBubble()


local function onCollision( event )

    if ( event.phase == "began" ) then

        local obj1 = event.object1
        local obj2 = event.object2
 
        if ( ( obj1.myName == "trident" and obj2.myName == "enemy" ) or
             ( obj1.myName == "enemy" and obj2.myName == "trident" ) )
        then
            display.remove( obj1 )
            display.remove( obj2 )

            for i = #enemyTable, 1, -1 do
                if ( enemyTable[i] == obj1 or enemyTable[i] == obj2 ) then
                    table.remove( enemyTable, i )
                    break
                end
            end

           

        elseif ( ( obj1.myName == "selfBubble" and obj2.myName == "enemy" ) or
                 ( obj1.myName == "enemy" and obj2.myName == "selfBubble" ) )
        then
            local timeNow = system.getTimer()
            if not lastHitTime or lastHitTime + invulnerableTime < timeNow then
                lastHitTime = timeNow

                hp = hp - 1
                if hp > 0 then
                    selfBubble:setSequence(tostring( hp ))
                end
                if (hp <= 0 and died == false ) then
                    died = true

                    Runtime:removeEventListener( "key", onKeyEvent )
                    Runtime:removeEventListener( "enterFrame", onEnterFrame )
                    
                    Runtime:removeEventListener( "tap", shootTrident )
                    

                
                        display.remove( player )
                        display.remove( selfBubble )
                else
                    player.alpha = 0.5
                    timer.performWithDelay( invulnerableTime, function()
                        player.alpha = 1 
                    end )
                end
            end

        elseif ( ( obj1.myName == "bubble" and obj2.myName == "player" ) or
                ( obj1.myName == "player" and obj2.myName == "bubble" ) ) 
        then
            hp = math.min(maxhp, hp + 1)
            if hp < 4 then
                selfBubble:setSequence(tostring( hp ))
            end
        end
    end
end    
  
Runtime:addEventListener( "collision", onCollision )


 -- Grow bubble hp
