package entity;

import java.awt.AlphaComposite;

import java.awt.Graphics2D;
import java.awt.Rectangle;
import java.awt.image.BufferedImage;




import main.GamePanel;
import main.KeyHandler;
import object.OBJ_Shield_Puffa;
import object.OBJ_Sword_Normal;


public class Player extends Entity{
	
	
	KeyHandler keyH;
	
	public final int screenX;
	public final int screenY;
	
	int standCounter;
	public boolean hasBoots = false;
	public boolean onCarbo = false;
	public boolean hasSword = false;
	public boolean attackCanceled = false;
	
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
		
		attackArea.width = 36;
		attackArea.height = 36;
		
		
		setDefaultValues();
		getPlayerImage();
		getPlayerAttackImage();
	}
	
	public void setDefaultValues() {
	
		worldX = gp.tileSize * 94;
		worldY = gp.tileSize * 94;
		speed = 4;
		direction = "down";
	
	// PLAYER STATUS
		level = 1;
		maxLife= 6;
		life = maxLife;
		strength = 1; // the more strength he has the more damage he gives
		dexterity = 1; // the more dexterity he has, the less damage he receives.
		exp = 0;
		nextLevelExp = 5;
		coin = 0;
		currentWeapon = new OBJ_Sword_Normal(gp);
		currentShield = new OBJ_Shield_Puffa(gp);
		attack = getAttack(); // the total attack value is decided by strength and weapon
		defense = getDefense();	// the total defense value is decided by dexterity and shield
	}
	public int getAttack () {
		return attack = strength * currentWeapon.attackValue;
	}
	public int getDefense() {
		return defense = dexterity * currentShield.defenseValue;
	}
	
	public void getPlayerImage() {
		
		up1 = setup("/player/boy_up_1",gp.tileSize,gp.tileSize);
		up2 = setup("/player/boy_up_2",gp.tileSize,gp.tileSize);
		down1 = setup("/player/boy_down_1",gp.tileSize,gp.tileSize);
		down2 = setup("/player/boy_down_2",gp.tileSize,gp.tileSize);
		left1 = setup("/player/boy_left_1",gp.tileSize,gp.tileSize);
		left2 = setup("/player/boy_left_2",gp.tileSize,gp.tileSize);
		right1 = setup("/player/boy_right_1",gp.tileSize,gp.tileSize);
		right2 = setup("/player/boy_right_2",gp.tileSize,gp.tileSize);
	
	}
	public void getPlayerAttackImage() {
		
		attackUp1 = setup("/player/boy_up_attack_1",gp.tileSize,gp.tileSize*2);
		attackUp2 = setup("/player/boy_up_attack_2",gp.tileSize,gp.tileSize*2);
		attackDown1 = setup("/player/boy_down_attack_1",gp.tileSize,gp.tileSize*2);
		attackDown2 = setup("/player/boy_down_attack_2",gp.tileSize,gp.tileSize*2);
		attackLeft1 = setup("/player/boy_left_attack_1",gp.tileSize*2,gp.tileSize);
		attackLeft2 = setup("/player/boy_left_attack_2",gp.tileSize*2,gp.tileSize);
		attackRight1 = setup("/player/boy_right_attack_1",gp.tileSize*2,gp.tileSize);
		attackRight2 = setup("/player/boy_right_attack_2",gp.tileSize*2,gp.tileSize);
		
	}
	public void update() {
		
		if(attacking == true) {
			attacking();	
		}
		
		
		else if(keyH.upPressed == true || keyH.downPressed == true ||
				keyH.leftPressed == true || keyH.rightPressed == true || keyH.enterPressed == true) {
			
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
			
			// Carbo controls
			if(onCarbo == true) {
				gp.obj[1].down1 = setup("/objects/carbuncle_green_2",gp.tileSize,gp.tileSize);
			
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
			
			//CHECK MONSTER COLLISION
			int monsterIndex = gp.cChecker.checkEntity(this, gp.monster);
			contactMonster(monsterIndex);
			
			//CHECK EVENT
			gp.eHandler.checkEvent();
			
			
			
			
			// IF COLLISION IS FALSE, PLAYER CAN MOVE
			if(collisionOn == false && keyH.enterPressed == false) {
				
				switch(direction) {
				case "up": worldY -= speed; break;
				case "down": worldY += speed; break;
				case "left": worldX -= speed; break;
				case "right": worldX += speed; break;
				}
			}
			
			if(keyH.enterPressed == true && attackCanceled == false && hasSword == true) {
				gp.playSE(8);
				attacking = true;
				spriteCounter = 0;
			}
			
			attackCanceled = false;
			gp.keyH.enterPressed = false;
			
			
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
		
		// This needs to be outside key if statement!
		if(invincible == true) {
			invincibleCounter++;
			if(invincibleCounter > 60) {
				invincible = false;
				invincibleCounter = 0;
				
			}
		}
	}
	public void attacking() {
		
		spriteCounter++;
		
		if(spriteCounter <=5) {
			spriteNum = 1;
		}
		if(spriteCounter > 5 && spriteCounter <= 25) {
			spriteNum = 2;
			
			// Save the current x, y, solidArea
			int currentWorldX = worldX;
			int currentWorldY = worldY;
			int solidAreaWidth = solidArea.width;
			int solidAreaHeight = solidArea.height;
			
			// Adjust player's worldX/Y for the attackArea
			switch(direction) {
			case "up": worldY -= attackArea.height; break;
			case "down": worldY += attackArea.height; break;
			case "left": worldX -= attackArea.width; break;
			case "right": worldX += attackArea.width; break;
			}
			
			//attackArea becomes solidArea
			solidArea.width = attackArea.width;
			solidArea.height = attackArea.height;
			// Check monster collision with the updated worldX, worldY, and solidArea
			int monsterIndex = gp.cChecker.checkEntity(this, gp.monster);
			damageMonster(monsterIndex);
			
			// Restore values to the saved values prior to collision 
			worldX = currentWorldX;
			worldY = currentWorldY;
			solidArea.width = solidAreaWidth;
			solidArea.height = solidAreaHeight;
			
		}
		if(spriteCounter > 25) {
			spriteNum = 1;
			spriteCounter = 0;
			attacking = false;
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
			case "Carbuncle":
				onCarbo = true;
				break;
				
				
			}
			
		}
		
	}
	public void interactNPC(int i) {
		if (gp.keyH.enterPressed == true) {
			
			if(i != 999) {
					attackCanceled = true;
					gp.stopSE();
					gp.playSE(10);
					gp.gameState = gp.dialogueState;
					gp.npc[i].speak();
					gp.keyH.enterPressed = false;	
			}
			
		}
	}
	public void contactMonster(int i) {
		
		if(i != 999) {
			
			if(invincible == false) {
				if(gp.monster[i].life != 0) {
					gp.playSE(7);
					life -= 1;
					invincible = true;
				}
				
			}
			
		}
	}
	public void damageMonster(int i) {
		
		if(i != 999) {
			
			if(gp.monster[i].invincible ==false) {
				
				gp.playSE(6);
				gp.monster[i].life -= 1;
				gp.monster[i].invincible = true;
				gp.monster[i].damageReaction();
				
				if(gp.monster[i].life <= 0) {
					gp.monster[i].dying = true;
					gp.stopSE();
					gp.playSE(9);
					if(life < maxLife) {
						life +=1;
					}
					
				}
			}
		}
	}
	
	public void draw(Graphics2D g2) {
		

		
		BufferedImage image = null;
		int tempScreenX = screenX;
		int tempScreenY = screenY;
		
		
		switch(direction) {
		case "up":
			if(attacking == false) {
				if(spriteNum == 1) {image = up1;}
				if(spriteNum == 2) {image = up2;}
			}
			if(attacking == true) {
				tempScreenY = screenY - gp.tileSize;
				if(spriteNum == 1) {image = attackUp1;}
				if(spriteNum == 2) {image = attackUp2;}
			}
			break;
		case "down":
			if(attacking == false) {
				if(spriteNum == 1) {image = down1;}
				if(spriteNum == 2) {image = down2;}
			}
			if(attacking == true) {
				if(spriteNum == 1) {image = attackDown1;}
				if(spriteNum == 2) {image = attackDown2;}
			}
			break;
		case "left":
			if(attacking == false) {
				if(spriteNum == 1) {image = left1;}
				if(spriteNum == 2) {image = left2;}
			}
			if(attacking == true) {
				tempScreenX = screenX - gp.tileSize;
				if(spriteNum == 1) {image = attackLeft1;}
				if(spriteNum == 2) {image = attackLeft2;}
			}
			break;
		case "right":
			if(attacking == false) {
				if(spriteNum == 1) {image = right1;}
				if(spriteNum == 2) {image = right2;}
		}
			if(attacking == true) {
				if(spriteNum == 1) {image = attackRight1;}
				if(spriteNum == 2) {image = attackRight2;}
			}
			break;
		}
		
		if(invincible == true) {
			g2.setComposite(AlphaComposite.getInstance(AlphaComposite.SRC_OVER, 0.3f));
			
		}
		
		g2.drawImage(image,  tempScreenX, tempScreenY, null);
		
		//Reset alpha
		g2.setComposite(AlphaComposite.getInstance(AlphaComposite.SRC_OVER, 1f));
		
		// DEBUG
//		g2.setFont(new Font("Arial", Font.PLAIN, 26));
//		g2.setColor(Color.white);
//		g2.drawString("Invincible:"+invincibleCounter, 12, 400);
//		
	}

}
