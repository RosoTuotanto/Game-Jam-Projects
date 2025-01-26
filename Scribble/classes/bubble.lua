local bubble = {}

local screen = require("classes.screen")
local random = math.random


function bubble.new( parent, character, callbackSelect, callbackPop )

	local group = display.newGroup()
	parent:insert( group )
	group.letter = character or "?"

	local xMin, xMax = -parent.width*0.5 + 120, parent.width*0.5 - 250

	-- Randomly assign the starting position of the bubble
	-- and the direction it will move/animate towards.
	group.x, group.y = random( xMin, xMax ), parent.height*0.5 + 50
	group.direction = random(1, 2) == 1 and -1 or 1
	group.xStart = group.x

	local shape = display.newImageRect( group, "assets/images/bubble" .. random(5) .. ".png", 64, 64 )

	local letter = display.newText({
		parent = group,
		text = group.letter,
		font = "assets/fonts/ff-comma-trial.regular.ttf",
		fontSize = 36
	})
	letter:setFillColor( 0 )


	function group:animate()

		-- Change the direction of the animation so that the bubbles
		-- don't randomly retain their size, rotation and position.
		group.direction = -group.direction

		local dx = random( 3 ) * group.direction
		local scale = 1 + random( 10 )*0.01 * group.direction
		local rotation = random( 2 ) * group.direction

		transition.to( self, {
			time = random( 500, 800 ),
			x = group.xStart + dx,
			xScale = scale,
			yScale = scale,
			rotation = rotation,
			onComplete = group.animate
		} )
	end

	local groupTransition


	function group:touch( event )
		if event.phase == "began" then
			local isActive = not group.isActive

			if isActive then
				group.isActive = true

				shape:setFillColor( 0.5, 0.5, 1 )
				letter:setFillColor( 0.5, 0.5, 1 )

				callbackSelect( self )
			else
				-- Bubble reactivated, just pop it.
				group:pop()
			end

		end
		return true
	end

	group:addEventListener( "touch", group )

	function group:pop()
		if not group.isPopped then
			group.isPopped = true

			transition.cancel( groupTransition )

			audio.play( "assets/audio/pop" .. random(4) .. ".wav" )

			-- Add pop image.
			local pop = display.newImageRect( parent, "assets/images/pop" .. random(3) .. ".png", 120, 120 )
			pop.x, pop.y = self.x, self.y
			pop.rotation = random( 360 )

			local scale = random( 90, 110 )*0.01

			transition.to( pop, {
				delay = 50,
				time = 50,
				xScale = scale,
				yScale = scale,
				rotation = pop.rotation + random( -10, 10 ),
				-- alpha = 0,
				onComplete = function()
					display.remove( pop )
				end
			} )

			-- "Pop" the bubble.
			transition.to( self, { time = 100, xScale=1.25, yScale=1.25, alpha=0.25, transition=easing.inBack, onComplete = function()
				display.remove( self )
			end } )

			callbackPop( self )
		end
	end

	groupTransition = transition.to( group, { time = 15000 + random( 3000, 5000 ), y = group.y - parent.height - group.height, onComplete = group.pop } )
		-- transition.to( group, { time = 1000, y = group.y+100, transition = easing.inQuad, onComplete = function()
		-- 	group:destroy()
		-- end } )
	-- end } )

	group:animate()

	return group
end


return bubble