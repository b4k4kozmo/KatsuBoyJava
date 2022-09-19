package main;

import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;


public class KeyHandler implements KeyListener{
	
	GamePanel gp;
	public boolean upPressed, downPressed, leftPressed, rightPressed, shiftPressed, enterPressed;
	// DEBUG
	boolean checkDrawTime = false;
	
	

	public KeyHandler(GamePanel gp) {
		this.gp = gp;	
		}


	


	@Override
	public void keyTyped(KeyEvent e) {
	}

	@Override
	public void keyPressed(KeyEvent e) {
		int code = e.getKeyCode();
		
		
		//TITLE STATE
		if(gp.gameState == gp.titleState) {
			titleState(code);	
		}
		
		//PLAYSTATE
		else if (gp.gameState == gp.playState) {
			playState(code);
		}
		
		//PAUSE STATE
		else if(gp.gameState == gp.pauseState) {
			pauseState(code);
		}
		
		// DIALOGUE STATE	
		else if(gp.gameState == gp.dialogueState ) {
			dialogueState(code);
		}
		// CHARACTER STATE
		else if (gp.gameState == gp.characterState) {
			characterState(code);
		}
	}
	public void titleState(int code) {
		if(gp.ui.titleScreenState == 0 ) {
			if(code == KeyEvent.VK_W) {
				gp.ui.commandNum--;
				gp.playSE(11);
				if(gp.ui.commandNum < 0) {
					gp.stopSE();
					gp.ui.commandNum = 0;
					
				}
			}
			if(code == KeyEvent.VK_S) {
				gp.ui.commandNum++;
				gp.playSE(11);
				if(gp.ui.commandNum > 2) {
					gp.stopSE();
					gp.ui.commandNum = 2;
					
				}
			}
			if(code == KeyEvent.VK_ENTER) {
				if (gp.ui.commandNum == 0) {
					gp.playSE(1);
					gp.ui.titleScreenState = 1;
					gp.playMusic(0);
				}
				if(gp.ui.commandNum == 1) {
					// add later
					gp.playSE(1);
				}
				if(gp.ui.commandNum == 2) {
					gp.playSE(1);
					System.exit(0);
				}
			}
		}
		
		else if(gp.ui.titleScreenState == 1 ) {
			if(code == KeyEvent.VK_W) {
				gp.ui.commandNum--;
				gp.playSE(11);
				if(gp.ui.commandNum < 0) {
					gp.stopSE();
					gp.ui.commandNum = 0;
					
				}
			}
			if(code == KeyEvent.VK_S) {
				gp.ui.commandNum++;
				gp.playSE(11);
				if(gp.ui.commandNum > 3) {
					gp.stopSE();
					gp.ui.commandNum = 3;
					
				}
			}
			if(code == KeyEvent.VK_ENTER) {
				if (gp.ui.commandNum == 0) {
					System.out.println("Do some samurai specific stuff");
					gp.playSE(1);
					gp.gameState = gp.playState;
					gp.player.hasSword = true;
				}
				if(gp.ui.commandNum == 1) {
					System.out.println("Do some Ninja specific stuff");
					gp.playSE(1);
					gp.gameState = gp.playState;
					gp.player.hasBoots = true;
					
					
				}
				if(gp.ui.commandNum == 2) {
					System.out.println("Do some Zilla specific stuff");
					gp.playSE(1);
					gp.stopMusic();
					gp.playMusic(5);
					gp.ui.kamiwhite = gp.ui.kamigreen;
					gp.ui.kamipink = gp.ui.kamigreen;
					gp.gameState = gp.playState;
					gp.player.hasBoots = true;
					gp.player.hasSword = true;
					
				}
				if(gp.ui.commandNum == 3) {
					gp.playSE(1);
					gp.ui.titleScreenState = 0;
					gp.stopMusic();
					gp.ui.commandNum = 0;
				}
			}
		}
	
	}
	public void playState(int code) {
		if (code == KeyEvent.VK_W) {
			upPressed = true;
		}
		if (code == KeyEvent.VK_S) {
			downPressed = true;
		}
		if (code == KeyEvent.VK_A) {
			leftPressed = true;
		}
		if (code == KeyEvent.VK_D) {
			rightPressed = true;
		}
		if (code == KeyEvent.VK_SHIFT) {
			shiftPressed = true;
		}
		
		// PAUSE
		if (code == KeyEvent.VK_P) {
			gp.gameState = gp.pauseState;
			gp.playSE(1);
			}
		if(code == KeyEvent.VK_C) {
			gp.gameState = gp.characterState;
			gp.playSE(1);
		}
		if(code == KeyEvent.VK_ENTER) {
			enterPressed = true;
		}
		
		
		// DEBUG
		if (code == KeyEvent.VK_T) {
			if(checkDrawTime == false) {
				checkDrawTime = true;
			}
			else if(checkDrawTime == true) {
				checkDrawTime = false;
			}
		}
	}
	
	public void pauseState(int code) {
		if (code == KeyEvent.VK_P) {
			gp.gameState = gp.playState;
			gp.playSE(1);
			}
	}
	
	public void dialogueState(int code) {
		if (code == KeyEvent.VK_ENTER) {
			gp.gameState = gp.playState;
		}
	}
	public void characterState(int code) {
		if(code == KeyEvent.VK_C) {
			gp.gameState = gp.playState;
			gp.playSE(1);
		}
		if(code == KeyEvent.VK_W) {
			if(gp.ui.slotRow != 0) {
				gp.ui.slotRow--;
				gp.playSE(11);
			}
			
		}
		if(code == KeyEvent.VK_A) {
			if(gp.ui.slotCol != 0) {
				gp.ui.slotCol--;
				gp.playSE(11);
			}
			
		}
		if(code == KeyEvent.VK_S) {
			if(gp.ui.slotRow != 3) {
				gp.ui.slotRow++;
				gp.playSE(11);
			}
			
		}
		if(code == KeyEvent.VK_D) {
			if(gp.ui.slotCol != 4) {
				gp.ui.slotCol++;
				gp.playSE(11);
			}
			
		}
		if(code == KeyEvent.VK_ENTER) {
			gp.player.selectItem();
		}
		
	}

	@Override
	public void keyReleased(KeyEvent e) {
		
		int code = e.getKeyCode();
		
		if (code == KeyEvent.VK_W) {
			upPressed = false;
		}
		if (code == KeyEvent.VK_S) {
			downPressed = false;
		}
		if (code == KeyEvent.VK_A) {
			leftPressed = false;
		}
		if (code == KeyEvent.VK_D) {
			rightPressed = false;
		}
		if (code == KeyEvent.VK_SHIFT) {
			shiftPressed = false;
		}
		if (code == KeyEvent.VK_ENTER) {
			enterPressed = false;
		}
		
	}

}
