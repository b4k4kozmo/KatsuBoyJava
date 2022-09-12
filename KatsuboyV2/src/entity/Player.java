package entity;

import java.awt.Graphics2D;
import java.awt.Rectangle;
import java.awt.image.BufferedImage;
import java.io.IOException;

import javax.imageio.ImageIO;

import main.GamePanel;
import main.KeyHandler;
import main.UtilityTool;

public class Player extends Entity{
	
	
	KeyHandler keyH;
	
	public final int screenX;
	public final int screenY;
	
	int standCounter;
	boolean hasBoots = false;
	
	public Player(GamePanel gp, KeyHandler keyH) {
		
		super (gp);
		
		this.keyH = keyH;
		
		screenX = gp.screenWidth/2 - (gp.tileSize/2);
		screenY = gp.screenHeight/2 - (gp.tileSize/2);
		
		solidArea = new Rectangle();
		solidArea.x = 18;
		solidArea.y = 32;
		solidAreaDefaultX = solidArea.x;
		solidAreaDefaultY = solidArea.y;
		solidArea.width = 12;
		solidArea.height = 12;
		
		
		setDefaultValues();
		getPlayerImage();
	}
	
	public void setDefaultValues() {
	
		worldX = gp.tileSize * 94;
		worldY = gp.tileSize * 94;
		speed = 4;
		direction = "down";
	
	// PLAYER STATUS
		maxLife= 6;
		life = maxLife;
	}
	
	public void getPlayerImage() {
		
		up1 = setup("/player/boy_up_1");
		up2 = setup("/player/boy_up_2");
		down1 = setup("/player/boy_down_1");
		down2 = setup("/player/boy_down_2");
		left1 = setup("/player/boy_left_1");
		left2 = setup("/player/boy_left_2");
		right1 = setup("/player/boy_right_1");
		right2 = setup("/player/boy_right_2");
	
	}
	
	
	public void update() {
		
		if(keyH.upPressed == true || keyH.downPressed == true || keyH.leftPressed == true || keyH.rightPressed == true) {
			
			if (keyH.upPressed == true) {
				direction = "up";
				
			}
			else if (keyH.downPressed == true) {
				direction = "down";
				
			}
			else if (keyH.leftPressed == true) {
				direction = "left";
				
			}
			else if (keyH.rightPressed == true) {
				direction = "right";
				
			}
			
			
			// Shift run
			if (keyH.shiftPressed == true && hasBoots == true) {
				speed = 10;
			} else if (keyH.shiftPressed == false && hasBoots == true) {
				speed = 6;
			}
			
			// CHECK TILE COLLISION
			collisionOn = false;
			gp.cChecker.checkTile(this);
			
			//CHECK OBJECT COLLISION
			int objIndex = gp.cChecker.checkObject(this, true);
			pickUpObject(objIndex);
			
			//CHECK NPC COLLISION
			int npcIndex = gp.cChecker.checkEntity(this, gp.npc);
			interactNPC(npcIndex);
			
			//CHECK EVENT
			gp.eHandler.checkEvent();
			
			gp.keyH.enterPressed = false;
			
			
			// IF COLLISION IS FALSE, PLAYER CAN MOVE
			if(collisionOn == false) {
				
				switch(direction) {
				case "up": worldY -= speed; break;
				case "down": worldY += speed; break;
				case "left": worldX -= speed; break;
				case "right": worldX += speed; break;
				}
			}
			
			
			
			
			spriteCounter++;
			if(spriteCounter > 12) {
				if(spriteNum == 1) {
					spriteNum =2;
				}
				else if(spriteNum == 2) {
					spriteNum = 1;
				}
				spriteCounter = 0;
			}
			
		}
		
		
		
		
		
		
	}
	public void pickUpObject(int i) {
		
		if(i != 999) {
			
			String objectName = gp.obj[i].name;
			
			switch(objectName) {
		
			case "Boots":
				gp.playSE(2);
				hasBoots = true;
				gp.obj[i] = null;
				gp.ui.showMessage("Katsu boy picked up running shoes!");
				break;
			case "Chest":
				gp.ui.gameFinished = true;
				gp.stopMusic();
				gp.playSE(4);
				break;
				
			}
		}
		
	}
	public void interactNPC(int i) {
		if(i != 999) {
			if(gp.keyH.enterPressed == true) {
				gp.gameState = gp.dialogueState;
				gp.npc[i].speak();
				gp.keyH.enterPressed = false;
			}
			
		}
		
	}
	
	public void draw(Graphics2D g2) {
		

		
		BufferedImage image = null;
		
		switch(direction) {
		case "up":
			if(spriteNum == 1) {
				image = up1;
			}
			if(spriteNum == 2) {
				image = up2;
			}
			break;
		case "down":
			if(spriteNum == 1) {
				image = down1;
			}
			if(spriteNum == 2) {
				image = down2;
			}
			break;
		case "left":
			if(spriteNum == 1) {
				image = left1;
			}
			if(spriteNum == 2) {
				image = left2;
			}
			break;
		case "right":
			if(spriteNum == 1) {
				image = right1;
			}
			if(spriteNum == 2) {
				image = right2;
			}
			break;
			
		}
		g2.drawImage(image,  screenX, screenY, null);
		System.out.println(direction);
	}

}