# LÖVE 2D Game with Lua: SnS

## Video Demo: <https://youtu.be/v2jbKhsR5zE>

## Description

My game is called slimes and skeletons, or SnS for short. It is a prototype game where you kill slimes and skeletons and your goal is to reach the house at the end of the path.

### Controls

The controls are relatively simple:
WASD to move;
Mouse button to attack;
The direction of the attack depends on your mouse, not the current direction of the player;
Finally, in order to run the game, visit the website linked below, then download, unzip and run the executable. Or, just use alt+l(Windows) or command+l(Mac) in VS Code.
<https://zulox.itch.io/sns>

### Assets

All assets' licenses are included with links to their repositories. You may have to search in multiple files for certain assets.

#### Libraries

All folders inside of the library are used in order to improve the ease of development and do not add any features that are present in SnS, but simply make the code cleaner.

For example, windfield is a physics module that takes the LÖVE2D's joints, fixtures and shapes into a single collider and world with easy to use functions. However, I am the one who needs to implement collision behavior, speed, shape and size. Then, I need to connect that behavior with what the player can see.

#### Art

CS50 is a course about learning how to program. Because of this, and mostly because of my lackluster skill, most of the art in this game was from [itch.io](https://itch.io/).

The hearts pack I used was made by [VampireGirl](https://itch.io/profile/fliflifly). However, the pack is free and she did not leave a license.

The main pack that I used, Mystic Woods, was made by [Game Endeavor]((https://game-endeavor.itch.io/)). He's a Youtube Creator who is currently posting developer logs for a game. His license has been included in the mystic woods folder which cost me $2.99.

### Code

The main.lua simply loads the game's graphics, loads in all of the files using require.lua and switches to the level game state. A game state is a table with all the regular love callbacks. This helps me switch between level, pause and end screens for the game.

In the configuration file, conf.lua, I define the title, version, dimensions and other miscellaneous settings which you can find out more about on the LÖVE2D website <https://love2d.org/wiki/Config_Files>.

#### Maps

This contains the map data necessary for the sti (simple tiled implementation) library to read and load the map so that I can draw it as well as all colliders that need to be used for the walls.

### Source

The source folder is made up of four directories. THe first one, entities, stores all the behavior and functions related to entities. The second one, instances, stores all game states. Thirdly, the load directory stores the files necessary to properly load the physics world as well as all of the files in the project. Finally, the utilities directory stores multiple useful functions such as a converter from hsl to rgb.

#### Entities

The entities folder is made up of four files: enemy.lua, player.lua, skeleton.lua, and slime.lua. The enemy file defines the general behavior for an enemy based on their stats. The player file defines the player's behavior. The slime and skeleton files contain functions which define the stats that will be used as input for the enemy initialization function. I will be covering the three main functions of each file. You may consult the documentation for all of the libraries I used for clarifications.

The **enemy.lua** file is made up of 11 functions and returns the enemy table with it's meta table's __call property, which defines what happens when you call the table as a function, being set to the new function. I also include the new function itself for flexibility purposes. The *new* function takes three arguments, the enemies statData, spriteData and animations. It initializes an enemy's stats, animations, collider, direction, the interval between attacks and its timer instance, which keeps track of all timer related to that enemy. The *update* function runs on every frame and takes delta time, the time between each frame, as it's argument. First, it updates the enemy's timer instance, then it gets the current state of the enemy (attack, move, dmg, etc.) in order to determine what it should do. It then calls the function that handles the specific state, which also returns the current animation for that state. Afterwards, it checks if the current state is different from the new state. If so, it updates the current state and resets the new animation's frame. Finally, it updates the animation and its orientation. The *draw* function simply draws the current animation by providing the enemy's position, scale and origin point (from where it is drawn).

The **player.lua** file is composed of 12 functions and returns the player table with the same __call property as the enemy table. It defines the player's behavior. The *new* function takes 2 arguments, the x and y values for the player. Just like for enemies, this function initializes all of the player's important properties. One difference is that the player has an acceleration to make his movement smoother and has 4 directional animations instead of them being two directional. The *update* function takes 1 argument, delta time and it runs every frame. It starts by initializing the directional vectors dx an dy of the player. Then, depending on the current state of the player, it assigns the appropriate values to those vectors. Afterwards, it updates the state of the player with those vectors. It then checks for either end state (over or win) and if one of them is true, then a switch is triggered. If it isn't triggered, then the speed is updated with the movement vectors and then applied to the player's collider. Afterwards, we check if the player has been damaged by the enemy and update its direction. We then get the player's current animation and change its type based on the player's new state. The *draw* function draws the player while setting its color to a specific brightness.

The **skeleton.lua** contains 1 function and returns the skeleton table. It fulfills the same role as the **slime.lua** file, so I'll only be talking about its functionality. The *new* function takes in two arguments, x and y, and defines all the variables which create the skeleton in the enemy.new function (Remember that the enemy table was assigned a __call value for that function). First, it defines the stats of the enemy such as health, position, speed, etc. Second, it defines the sprite information for the enemy such as the sprite sheet's path, how many rows and columns it has, a number representing the indentation of the collider and its attack interval in frames.

#### Instances

Instances, or gamestates, are tables containing call back functions that act exactly like the main love callbacks. I won't cover any other non-callback functions inside of these files.

##### Demo Level

The **demoLevel.lua** file contains 8 functions and describes the behavior of the demo level of this game. The first callback function is the *enter* function, which serves as the love.load() callback. It initializes the physics world and creates the collision classes. Then, the function grabs the map data from the maps folder and stores it in the Demo table. Finally, it iterates over the layers that make up the map and loads in all of the physics objects required (walls, houses, etc.). The second callback function is the *update* function. It checks if the game is paused, and returns immediately if it is the case. It updates the world, all entities, the flux (tweening table) and timer instances. Finally, the function does a bunch of math so that the camera works properly and tracks the player. The third callback function, *draw*, starts by attaching the camera to anything in the game world such as the map and all entities. Then, the hud camera attaches to anything hud related such as the player's hearts. The fourth callback function, *mousepressed*, checks for a pause, and if the left mouse button is pressed, the player's mousepressed callback is called. This initiates the player's attack. The final callback function, *keypressed*, inverses the pause state of the game if the 'escape' or 'p' keys are pressed.

##### Game Over

The **gameOver.lua** file contains 6 functions, and deals with the game's "game over" state. The first callback function, *enter*, starts by storing the previous instance table, which is the first input of the enter function. Afterwards, it clears all timers by iterating over all enemies. The world is destroyed and set to nil and the player direction is readjusted. Then, the player's animation is set as well as the font. The second callback function, *update*, updates the player's animation as well as the camera's position. The third callback function, *draw*, attaches the camera to everything drawn. It draws the red background of game over screens, the game over text, and the player character. The fourth callback function, *mousepressed*, refers to the fifth callback *keypressed* function which checks the player's animation position and if the death animation has finished, then it will switch back to the previous instance which is of course the demo level instance.

##### Game Won

The **gameWon.lua** file contains 5 functions, and deals with the game won state that is triggered once the player enters the house. The first callback function *enter* is similar the game over *enter* function. It clears all timers, destroys the world and updates the player's animation and direction. It also stores the font used for the game won screen. The second callback function *update*, updates the player's animation and camera's position. The third callback function *draw*, draws the background rectangle, the text and the player's death animation. The final callback function *keypressed*, waits for the escape key to be pressed and quits the game it is.

#### Load

These files are responsible for loading the base resources needed for the project.

##### Collision Classes

The **collisionClasses.lua** file simply initializes all the different types of collision boxes and their interactions with each other. For example, dead entities ignore all other entities.

##### Require

The **require.lua** file simply requires all of the different files and libraries used for the project.

#### Utilities

##### Debug

The **debug.lua** file contains a function whose role is to print debug statements on the game screen. This was only used for development, not the final product. It takes any numbers of arguments and prints them out using a for loop.

##### PrintTable

The **prinTable.lua** file contains the printTable function. It takes a table and iteratively prints all of its elements to the command line.
