package entity;

import java.awt.AlphaComposite;

import java.awt.Graphics2D;
import java.awt.Rectangle;
import java.awt.image.BufferedImage;
import java.util.ArrayList;

import main.GamePanel;
import main.KeyHandler;
import object.OBJ_Boots;
import object.OBJ_Key;
import object.OBJ_Shield_Puffa;
import object.OBJ_Shuriken;
import object.OBJ_Snowball;
import object.OBJ_Sword_Normal;


public class Player extends Entity{
	
	
	KeyHandler keyH;
	
	public final int screenX;
	public final int screenY;
	int standCounter = 0;
	public boolean hasBoots = false;
	public boolean onCarbo = false;
	
	public boolean attackCanceled = false;
	public ArrayList<Entity> inventory = new ArrayList<>();
	public final int maxInventorySize = 20;
	
	public Player(GamePanel gp, KeyHandler keyH) {
		
		super (gp);
		
		this.keyH = keyH;
		
		screenX = gp.screenWidth/2 - (gp.tileSize/2);
		screenY = gp.screenHeight/2 - (gp.tileSize/2);
		
		solidArea = new Rectangle();
		solidArea.x = 8;
		solidArea.y = 16;
		solidAreaDefaultX = solidArea.x;
		solidAreaDefaultY = solidArea.y;
		solidArea.width = 32;
		solidArea.height = 32;
		//ATTACK AREA
//		attackArea.width = 36;
//		attackArea.height = 36;
		
		
		setDefaultValues();
		getPlayerImage();
		getPlayerAttackImage();
		setItems();
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
		maxMana = 4;
		mana = maxMana;
		ammo = 10;
		strength = 1; // the more strength he has the more damage he gives
		dexterity = 1; // the more dexterity he has, the less damage he receives.
		exp = 0;
		nextLevelExp = 5;
		coin = 0;
		currentWeapon = new OBJ_Sword_Normal(gp);
		currentShield = new OBJ_Shield_Puffa(gp);
		//runs on mana
		projectile = new OBJ_Shuriken(gp);
		// runs on ammo
//		projectile = new OBJ_Snowball(gp);
		attack = getAttack(); // the total attack value is decided by strength and weapon
		defense = getDefense();	// the total defense value is decided by dexterity and shield
	}
	public void setItems() {
		
		inventory.add(currentWeapon);
		inventory.add(currentShield);
		inventory.add(new OBJ_Key(gp));
		inventory.add(new OBJ_Boots(gp));
		
	}
	public int getAttack () {
		attackArea = currentWeapon.attackArea;
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
		
		if (currentWeapon.name == "Normal Sword") {
			attackUp1 = setup("/player/boy_up_attack_1",gp.tileSize,gp.tileSize*2);
			attackUp2 = setup("/player/boy_up_attack_2",gp.tileSize,gp.tileSize*2);
			attackDown1 = setup("/player/boy_down_attack_1",gp.tileSize,gp.tileSize*2);
			attackDown2 = setup("/player/boy_down_attack_2",gp.tileSize,gp.tileSize*2);
			attackLeft1 = setup("/player/boy_left_attack_1",gp.tileSize*2,gp.tileSize);
			attackLeft2 = setup("/player/boy_left_attack_2",gp.tileSize*2,gp.tileSize);
			attackRight1 = setup("/player/boy_right_attack_1",gp.tileSize*2,gp.tileSize);
			attackRight2 = setup("/player/boy_right_attack_2",gp.tileSize*2,gp.tileSize);	
		}
		if (currentWeapon.name == "Kami no Bokken") {
			attackUp1 = setup("/player/boy_up_bokken_1",gp.tileSize,gp.tileSize*2);
			attackUp2 = setup("/player/boy_up_bokken_2",gp.tileSize,gp.tileSize*2);
			attackDown1 = setup("/player/boy_down_bokken_1",gp.tileSize,gp.tileSize*2);
			attackDown2 = setup("/player/boy_down_bokken_2",gp.tileSize,gp.tileSize*2);
			attackLeft1 = setup("/player/boy_left_bokken_1",gp.tileSize*2,gp.tileSize);
			attackLeft2 = setup("/player/boy_left_bokken_2",gp.tileSize*2,gp.tileSize);
			attackRight1 = setup("/player/boy_right_bokken_1",gp.tileSize*2,gp.tileSize);
			attackRight2 = setup("/player/boy_right_bokken_2",gp.tileSize*2,gp.tileSize);
			
		}
		if(currentWeapon.type == type_axe) {
			attackUp1 = setup("/player/boy_up_axe_1",gp.tileSize,gp.tileSize*2);
			attackUp2 = setup("/player/boy_up_axe_2",gp.tileSize,gp.tileSize*2);
			attackDown1 = setup("/player/boy_down_axe_1",gp.tileSize,gp.tileSize*2);
			attackDown2 = setup("/player/boy_down_axe_2",gp.tileSize,gp.tileSize*2);
			attackLeft1 = setup("/player/boy_left_axe_1",gp.tileSize*2,gp.tileSize);
			attackLeft2 = setup("/player/boy_left_axe_2",gp.tileSize*2,gp.tileSize);
			attackRight1 = setup("/player/boy_right_axe_1",gp.tileSize*2,gp.tileSize);
			attackRight2 = setup("/player/boy_right_axe_2",gp.tileSize*2,gp.tileSize);
		}
		
		System.out.println(currentWeapon);
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
			
			//CHECK INTERACTIVE TILE COLLISION
			int iTileIndex = gp.cChecker.checkEntity(this, gp.iTile);
			
			
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
			
			if(keyH.enterPressed == true && attackCanceled == false) {
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
		if(gp.keyH.shotKeyPressed == true && projectile.alive == false && shotAvailableCounter == 30 &&
				projectile.haveResource(this) == true) {
			
			// SET DEFAULT COORDINATES, DIRECTION AND USER
			projectile.set(worldX, worldY, direction, true, this);
			
			// SUBTRACT THE COST (MANA, AMMO)
			projectile.subtractResource(this);
			
			// ADD IT TO THE LIST
			gp.projectileList.add(projectile);
			
			shotAvailableCounter = 0;
			
			gp.playSE(8);
		}
		
		// This needs to be outside key if statement!
		if(invincible == true) {
			invincibleCounter++;
			if(invincibleCounter > 60) {
				invincible = false;
				invincibleCounter = 0;
				
			}
		}
		if(shotAvailableCounter < 30) {
			shotAvailableCounter++;
		}
		if(life > maxLife) {
			life = maxLife;
		}
		if(mana > maxMana) {
			mana = maxMana;
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
			
//			g2.setColor(gp.ui.kamiblack);
//			g2.fillRect(worldX, worldY, attackArea.width, attackArea.height);
			}
			
			//attackArea becomes solidArea
			solidArea.width = attackArea.width;
			solidArea.height = attackArea.height;
			// Check monster collision with the updated worldX, worldY, and solidArea
			int monsterIndex = gp.cChecker.checkEntity(this, gp.monster);
			damageMonster(monsterIndex, attack);
			
			int iTileIndex = gp.cChecker.checkEntity(this, gp.iTile);
			damageInteractiveTile(iTileIndex);
			
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
			
			// PICKUP ONLY ITEMS
			if(gp.obj[i].type == type_pickupOnly) {
				
				gp.obj[i].use(this);
				gp.obj[i] = null;
			}
			
			// INVENTORY ITEMS
			else {
				String text;
				
				if(inventory.size() != maxInventorySize) {
					
					inventory.add(gp.obj[i]);
					gp.playSE(1);
					text = "Got a " + gp.obj[i].name + "!";
				}
				else {
					text = "Your inventory is full!";
				}
				gp.ui.addMessage(text);
				gp.obj[i] = null;
			}
			
			
			
			
		}
		
	}
	public void interactNPC(int i) {
		if (gp.keyH.enterPressed == true) {
			
			if(i != 999) {
					attackCanceled = true;
					
					
					if(gp.npc[i].name == "Nanaman" && level <= 7) {
						exp += 444;
						if(hasBoots == false) {
							exp += 777;
							hasBoots = true;
						}
						if(level == 1) {
							exp += 111;
						}
						checkLevelUp();
							
						
						
						System.out.println("it's him!");
					}
					gp.stopSE();
					gp.playSE(10);
					gp.gameState = gp.dialogueState;
					gp.npc[i].speak();
					gp.keyH.enterPressed = false;
					
			}
			
			
		}
		checkLevelUp();
	}
	public void contactMonster(int i) {
		
		if(i != 999) {
			
			if(invincible == false) {
				if(gp.monster[i].life > 0) {
					gp.playSE(7);
					
					int damage = gp.monster[i].attack - defense;
					if (damage < 0) {
						damage = 0;
					}
					
					life -= damage;
					invincible = true;
				}
				
			}
			
		}
	}
	public void damageMonster(int i, int attack) {
		
		if(i != 999) {
			
			if(gp.monster[i].invincible ==false) {
				
				gp.playSE(6);
				
				int damage = attack - gp.monster[i].defense;
				if (damage < 0) {
					damage = 0;
				}
				
				gp.monster[i].life -= damage;
				gp.ui.addMessage(damage + " damage!");
				
				gp.monster[i].invincible = true;
				gp.monster[i].damageReaction();
				
				if(gp.monster[i].life <= 0) {
					gp.monster[i].dying = true;
					gp.stopSE();
					gp.playSE(9);
					gp.ui.addMessage("Killed the " + gp.monster[i].name + "!");
					gp.ui.addMessage("Gained " + gp.monster[i].exp + " exp!");
					exp += gp.monster[i].exp;
					checkLevelUp();
					if(life < maxLife) {
						life +=1;
					}
					
				}
			}
		}
	}
	
	public void damageInteractiveTile(int i) {
		if(i != 999 && gp.iTile[i].destructable == true 
				&& gp.iTile[i].isCorrectItem(this) == true && gp.iTile[i].invincible == false) {
			
			gp.iTile[i].playSE();
			gp.iTile[i].life--;
			gp.iTile[i].invincible = true;
			
			// Generate particle
			generateParticle(gp.iTile[i],gp.iTile[i]);
			
			if(gp.iTile[i].life == 0) {
				gp.iTile[i] = gp.iTile[i].getDestroyedForm();
			}
			
			
		}
		
	}
	public void checkLevelUp() {
		
		while(exp >= nextLevelExp) {
			gp.ui.addMessage("Level up!");
			level++;
			nextLevelExp *= 3;
			maxLife += 2;
			if(level%2 == 0) {
				maxMana += 1;
			}
			life = maxLife;
			mana = maxMana;
			strength++;
			dexterity++;
			attack = getAttack();
			defense = getAttack();
			gp.stopSE();
			gp.playSE(4);
			gp.gameState = gp.dialogueState;
			gp.ui.currentDialogue = "You are now " + level + "!\n"
					+ "You can feel the power!";
		}
	}
	public void selectItem() {
		
		int itemIndex = gp.ui.getItemIndexOnSlot();
	
		if(itemIndex < inventory.size()) {
			
			Entity selectedItem = inventory.get(itemIndex);
			
			if(selectedItem.type == type_sword || selectedItem.type == type_axe) {
				
				currentWeapon = selectedItem;
				attack = getAttack();
				getPlayerAttackImage();
			}
			if(selectedItem.type == type_shield) {
				
				currentShield = selectedItem;
				defense = getDefense();
			}
			if(selectedItem.type == type_consumable) {

				selectedItem.use(this);
				inventory.remove(itemIndex);
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
