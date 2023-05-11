# bmob 💣

## Description

An MIPS platform game where player strategically places bombs to explode enemies.

This game was inspired by _Bomb It_. The main gameplay is to explode moving enemies with bombs whose explosion range is limited (so timing is essential). The player wins when all enemies are destroyed. Falling off a platform, standing within the explosion range of an active bomb or colliding with an enemy for too long will lead to a game-over.

Through this project, I learned about the MIPS architecture, machine code and instructions and coding in an assembly language. This project is part of my coursework for CSCB58 Computer Organization.

## Installation

Download [MIPS simulator](https://courses.missouristate.edu/kenvollmar/mars/download.htm). Run the jar file  as instructed (Option B).

Open ```game.asm``` from ```File > Open``` or ```Ctrl/Command + O```. Choose ```Tool > Keyboard and Display MMIO Simulator``` and ```Connect to MIPS```. Open ```Tool > Bitmap Display``` and select the configuration according to the specification in ```game.asm``` preamble, then ```Connect to MIPS```.

You can now run ```game.asm``` by ```Assemble```, then ```Go``` from the ```Run``` menu.


## Usage

Move mouse pointer to the ```Keyboard``` section of ```Keyboard and Display MMIO Simulator``` window. You can control the player with the keys ```A``` (go left), ```D``` (go right), ```W``` (jump), and ```S``` (place bomb).

More instructions can be found in the demo video linked in ```game.asm``` preamble.