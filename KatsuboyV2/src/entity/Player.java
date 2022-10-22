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
	public boolean attackCanceled = false;
	public boolean lightUpdated = false;
	public boolean isCursed = false;
	
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
		getImage();
		getAttackImage();
		getGuardImage();
		setItems();
	}
	
	public void setDefaultValues() {
	
		worldX = gp.tileSize * 94;
		worldY = gp.tileSize * 94;
//		worldX = gp.tileSize * 26;
//		worldY = gp.tileSize * 32;
		defaultSpeed = 4;
		speed = defaultSpeed;
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
		coin = 999;
		currentWeapon = new OBJ_Sword_Normal(gp);
		currentShield = new OBJ_Shield_Puffa(gp);
		//runs on mana
		projectile = new OBJ_Shuriken(gp);
		// runs on ammo
//		projectile = new OBJ_Snowball(gp);
		attack = getAttack(); // the total attack value is decided by strength and weapon
		defense = getDefense();	// the total defense value is decided by dexterity and shield
	}
	public void setDefaultPositions() {
		
		worldX = gp.tileSize * 94;
		worldY = gp.tileSize * 94;
		direction = "down";
	}
	public void restoreLifeAndMana() {
		
		life = maxLife;
		mana = maxMana;
		invincible = false;
		transparent = false;
	}
	
	public void setItems() {
		
		inventory.clear();
		getAttackImage();
		inventory.add(currentWeapon);
		inventory.add(currentShield);
	}
	public int getAttack () {
		attackArea = currentWeapon.attackArea;
		motion1_duration = currentWeapon.motion1_duration;
		motion2_duration = currentWeapon.motion2_duration;
		return attack = strength * currentWeapon.attackValue;
	}
	public int getDefense() {
		return defense = dexterity * currentShield.defenseValue;
	}
	
	public void getImage() {
		
		up1 = setup("/player/boy_up_1",gp.tileSize,gp.tileSize);
		up2 = setup("/player/boy_up_2",gp.tileSize,gp.tileSize);
		down1 = setup("/player/boy_down_1",gp.tileSize,gp.tileSize);
		down2 = setup("/player/boy_down_2",gp.tileSize,gp.tileSize);
		left1 = setup("/player/boy_left_1",gp.tileSize,gp.tileSize);
		left2 = setup("/player/boy_left_2",gp.tileSize,gp.tileSize);
		right1 = setup("/player/boy_right_1",gp.tileSize,gp.tileSize);
		right2 = setup("/player/boy_right_2",gp.tileSize,gp.tileSize);
	
	}
	public void getSleepingImage(BufferedImage image) {
		up1 = image;
		up2 = image;
		down1 = image;
		down2 = image;
		left1 = image;
		left2 = image;
		right1 = image;
		right2 = image;
	
	}
	public void getAttackImage() {
		
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
	public void getGuardImage() {
		guardUp = setup("/player/guard_boy_up",gp.tileSize,gp.tileSize);
		guardDown = setup("/player/guard_boy_down",gp.tileSize,gp.tileSize);
		guardLeft = setup("/player/guard_boy_left",gp.tileSize,gp.tileSize);
		guardRight = setup("/player/guard_boy_right",gp.tileSize,gp.tileSize);
	}
	public void update() {
		
		if(knockBack == true) {
			
			collisionOn = false;
			gp.cChecker.checkTile(this);
			gp.cChecker.checkObject(this, true);
			gp.cChecker.checkEntity(this, gp.npc);
			gp.cChecker.checkEntity(this, gp.monster);
			gp.cChecker.checkEntity(this, gp.iTile);
			
			if(collisionOn == true) {
				knockBackCounter = 0;
				knockBack = false;
				speed = defaultSpeed;
			}
			else if(collisionOn == false ) {
				switch(knockBackDirection) {
				case "up": worldY -= speed; break;
				case "down": worldY += speed; break;
				case "left": worldX -= speed; break;
				case "right": worldX += speed; break;
				}
			}
			
			knockBackCounter++;
			if(knockBackCounter == 10) {
				knockBackCounter = 0;
				knockBack = false;
				speed = defaultSpeed;
			}
		}
		
		else if(attacking == true) {
			attacking();	
		}
		else if(keyH.controlPressed == true) {
			guarding = true;
			guardCounter++;
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
//			if(onCarbo == true) {
//				gp.obj[1].down1 = setup("/objects/carbuncle_green_2",gp.tileSize,gp.tileSize);
//			
//			}
			
			
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
			guarding = false;
			guardCounter = 0;
			
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
		else {
			standCounter++;
			if(standCounter == 20) {
				spriteNum = 1;
				standCounter = 0;
			}
			guarding = false;
			guardCounter = 0;
		}
		
		if(gp.keyH.shotKeyPressed == true && projectile.alive == false && shotAvailableCounter == 30 &&
				projectile.haveResource(this) == true) {
			
			// SET DEFAULT COORDINATES, DIRECTION AND USER
			projectile.set(worldX, worldY, direction, true, this);
			
			// SUBTRACT THE COST (MANA, AMMO)
			projectile.subtractResource(this);
				
			// CHECK VACANCY
			for(int i = 0; i < gp.projectile[1].length; i++) {
				if(gp.projectile[gp.currentMap][i] == null) {
					gp.projectile[gp.currentMap][i] = projectile;
					break;
				}
			}
			
			shotAvailableCounter = 0;
			
			gp.playSE(8);
		}
		
		// This needs to be outside key if statement!
		if(invincible == true) {
			invincibleCounter++;
			if(invincibleCounter > 60) {
				invincible = false;
				transparent = false;
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
		if(life <= 0) {
			gp.gameState = gp.gameOverState;
			gp.ui.commandNum = -1;
			gp.stopSE();
			gp.stopMusic();
			gp.playSE(12);
		}
	}

	public void pickUpObject(int i) {
		
		if(i != 999) {
			
			// PICKUP ONLY ITEMS
			if(gp.obj[gp.currentMap][i].type == type_pickupOnly) {
				
				gp.obj[gp.currentMap][i].use(this);
				gp.obj[gp.currentMap][i] = null;
			}
			// OBSTACLE
			else if(gp.obj[gp.currentMap][i].type == type_obstacle) {
				if(keyH.enterPressed == true) {
					attackCanceled = true;
					gp.obj[gp.currentMap][i].interact();
				}
			}
			// INVENTORY ITEMS
			else {
				String text;
				
				if(canObtainItem(gp.obj[gp.currentMap][i]) == true) {
					gp.playSE(1);
					text = "Got a " + gp.obj[gp.currentMap][i].name + "!";
				}
				else {
					text = "Your inventory is full!";
				}
				gp.ui.addMessage(text);
				gp.obj[gp.currentMap][i] = null;
			}
			
			
			
			
		}
		
	}
	public void interactNPC(int i) {
		if (gp.keyH.enterPressed == true) {
			
			if(i != 999) {
					attackCanceled = true;
					
					
					if(gp.npc[gp.currentMap][i].name == "Nanaman" && level <= 7) {
						exp += 444;
						gp.player.isCursed = false;
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
					gp.npc[gp.currentMap][i].speak();
					gp.keyH.enterPressed = false;
					
			}
			
			
		}
		checkLevelUp();
	}
	public void contactMonster(int i) {
		
		if(i != 999) {
			
			if(invincible == false) {
				if(gp.monster[gp.currentMap][i].life > 0) {
					gp.playSE(7);
					
					int damage = gp.monster[gp.currentMap][i].attack - defense;
					if (damage < 1) {
						damage = 1;
					}
					
					life -= damage;
					invincible = true;
					transparent = true;
					if(gp.eManager.lighting.dayState == gp.eManager.lighting.night) {
						isCursed = true;
						System.out.print(isCursed);
					}
				}
				
			}
			
		}
	}
	public void damageMonster(int i, Entity attacker, int attack, int knockBackPower) {
		
		if(i != 999) {
			
			if(gp.monster[gp.currentMap][i].invincible == false) {
				
				gp.playSE(6);
				if(knockBackPower > 0) {
					setKnockBack(gp.monster[gp.currentMap][i], attacker, knockBackPower);
				}
				
				if(gp.monster[gp.currentMap][i].offBalance == true) {
					attack *= 3;
				}
				
				
				int damage = attack - gp.monster[gp.currentMap][i].defense;
				if (damage < 0) {
					damage = 0;
				}
				
				gp.monster[gp.currentMap][i].life -= damage;
				gp.ui.addMessage(damage + " damage!");
				
				gp.monster[gp.currentMap][i].invincible = true;
				gp.monster[gp.currentMap][i].damageReaction();
				
				if(gp.monster[gp.currentMap][i].life <= 0) {
					gp.monster[gp.currentMap][i].dying = true;
					gp.stopSE();
					gp.playSE(9);
					gp.ui.addMessage("Killed the " + gp.monster[gp.currentMap][i].name + "!");
					gp.ui.addMessage("Gained " + gp.monster[gp.currentMap][i].exp + " exp!");
					exp += gp.monster[gp.currentMap][i].exp;
					checkLevelUp();
				}
			}
		}
	}

	public void damageInteractiveTile(int i) {
		if(i != 999 && gp.iTile[gp.currentMap][i].destructable == true 
				&& gp.iTile[gp.currentMap][i].isCorrectItem(this) == true && gp.iTile[gp.currentMap][i].invincible == false) {
			
			gp.iTile[gp.currentMap][i].playSE();
			gp.iTile[gp.currentMap][i].life--;
			gp.iTile[gp.currentMap][i].invincible = true;
			
			// Generate particle
			generateParticle(gp.iTile[gp.currentMap][i],gp.iTile[gp.currentMap][i]);
			
			if(gp.iTile[gp.currentMap][i].life == 0) {
				gp.iTile[gp.currentMap][i] = gp.iTile[gp.currentMap][i].getDestroyedForm();
			}	
		}	
	}
	public void damageProjectile(int i) {
		
		if(i != 999) {
			Entity projectile = gp.projectile[gp.currentMap][i];
			projectile.alive = false;
			generateParticle(projectile,projectile);
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
		
		int itemIndex = gp.ui.getItemIndexOnSlot(gp.ui.playerSlotCol,gp.ui.playerSlotRow);
	
		if(itemIndex < inventory.size()) {
			
			Entity selectedItem = inventory.get(itemIndex);
			
			if(selectedItem.type == type_sword || selectedItem.type == type_axe) {
				
				currentWeapon = selectedItem;
				attack = getAttack();
				getAttackImage();
			}
			if(selectedItem.type == type_shield) {
				
				currentShield = selectedItem;
				defense = getDefense();
			}
			if (selectedItem.type == type_light) {
				if(currentLight == selectedItem) {
					currentLight = null;
				}
				else {
					currentLight = selectedItem;
				}
				lightUpdated = true;
			}
			if(selectedItem.type == type_consumable) {

				if(selectedItem.use(this) == true) {
					if(selectedItem.amount > 1) {
						selectedItem.amount--;
					}
					else {
						inventory.remove(itemIndex);
					}
				}
			}	
		}
	}
	public int searchItemInInventory(String itemName) {
		
		int itemIndex = 999;
		
		for(int i = 0; i < inventory.size(); i++) {
			if(inventory.get(i).name.equals(itemName)) {
				itemIndex = i;
				break;
			}
		}
		return itemIndex;
	}
	public boolean canObtainItem(Entity item) {
		
		boolean canObtain = false;
		
		// CHECK IF STACKABLE
		if(item.stackable == true) {
			
			int index = searchItemInInventory(item.name);
			
			if(index != 999) {
				inventory.get(index).amount++;
				canObtain = true;
			}
			else { // New item need to check vacancy
				if(inventory.size() != maxInventorySize) {
					inventory.add(item);
					canObtain = true;
				}
			}
		}
		else { // Not stackable check vacancy
			if(inventory.size() != maxInventorySize) {
				inventory.add(item);
				canObtain = true;
			}
		}
		return canObtain;	
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
			if(guarding == true) {
				image = guardUp;
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
			if(guarding == true) {
				image = guardDown;
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
			if(guarding == true) {
				image = guardLeft;
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
			if(guarding == true) {
				image = guardRight;
			}
			break;
		}
		
		if(transparent == true) {
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
