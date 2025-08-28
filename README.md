# Snake Game in Assembly (NASM)

A classic **Snake game** implemented in **16-bit NASM assembly** for DOS `.COM` executables.  
This version features **two snakes**, where **Snake 1 is player-controlled** and **Snake 2 is AI-controlled** with collision avoidance.

---

## Features

- **Player-controlled Snake** using arrow keys.
- **AI-controlled Snake** that moves toward food while avoiding collisions.
- **Food spawning** at random positions avoiding both snakes.
- **Collision detection** with walls, self, and other snake.
- **Simple DOS graphics** using text mode (80x25 screen).
- Smooth gameplay with adjustable delay loop.
- **Game over message** and key press to exit.

---

## Configuration

| Setting        | Description                  | Value                       |
|----------------|-----------------------------|----------------------------|
| WIDTH          | Playable width of game grid  | 78                          |
| HEIGHT         | Playable height of game grid | 23                          |
| MAX_SEG        | Maximum segments per snake   | 100                         |
| CHAR_SNAKE1    | Player snake character       | `#`                         |
| ATTR_SNAKE1    | Player snake color           | Light Green (0x0A)          |
| CHAR_SNAKE2    | AI snake character           | `@`                         |
| ATTR_SNAKE2    | AI snake color               | Light Cyan (0x0B)           |
| CHAR_FOOD      | Food character               | `*`                         |
| ATTR_FOOD      | Food color                   | Light Red (0x0C)            |

---

## Controls

- **Arrow Keys:** Move the player snake (Snake 1)
- **ESC:** Exit the game

---

## How to Assemble and Run

### Requirements

- NASM assembler ([https://www.nasm.us/](https://www.nasm.us/))
- DOS environment or DOSBox

### Steps

1. Save the code as `snake.asm`
2. Open a terminal in the same directory
3. Assemble the code:
4. Run the game in DOS or DOSBox:
   ``` bash
   snake.com
   ```
## How It Works
### Initialization
 - Sets up video segment (text mode)
 - Hides cursor and clears screen
 - Initializes two snakes’ positions
 - Places the first food randomly

### Main Loop
- Draws the game screen
- Reads player input for Snake 1
- AI chooses the next move for Snake 2
- Updates positions of both snakes
- Checks collisions with walls, snakes, and food
- Adds new food when eaten
- Delays to control game speed

### AI Logic for Snake 2
- Moves toward food in X or Y direction
- Checks for safe moves to avoid collisions with walls or snakes
- Falls back to any safe direction if a direct move toward food is unsafe

### Game Over
- Displays a “Game Over!” message
- Waits for key press before exiting

## Notes
- This game is written entirely in 16-bit assembly for DOS .COM programs.
- Works best in DOSBox or a DOS-compatible environment.
- AI is simple but avoids collisions and moves toward food intelligently.
```bash
nasm -f bin snake.asm -o snake.com
```
