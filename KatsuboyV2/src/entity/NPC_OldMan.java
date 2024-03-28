package entity;


import java.awt.Rectangle;
import java.util.Random;

import main.GamePanel;


public class NPC_OldMan extends Entity{

	public NPC_OldMan(GamePanel gp) {
		super(gp);
		
		direction = "down";
		speed = 1;
		
		solidArea = new Rectangle();
		solidArea.x = 8;
		solidArea.y = 16;
		solidAreaDefaultX = solidArea.x;
		solidAreaDefaultY = solidArea.y;
		solidArea.width = 28;
		solidArea.height = 28;
		
		dialogueSet = -1;
		soundNumber = 17;
		
		getImage();
		setDialogue();
		
	}
	public void getImage() {
		
		up1 = setup("/npc/oldman_up_01",gp.tileSize,gp.tileSize);
		up2 = setup("/npc/oldman_up_02",gp.tileSize,gp.tileSize);
		down1 = setup("/npc/oldman_down_01",gp.tileSize,gp.tileSize);
		down2 = setup("/npc/oldman_down_02",gp.tileSize,gp.tileSize);
		left1 = setup("/npc/oldman_left_01",gp.tileSize,gp.tileSize);
		left2 = setup("/npc/oldman_left_02",gp.tileSize,gp.tileSize);
		right1 = setup("/npc/oldman_right_01",gp.tileSize,gp.tileSize);
		right2 = setup("/npc/oldman_right_02",gp.tileSize,gp.tileSize);
	
	}
	public void setDialogue () {
		dialogues[0][0] = "Hello, Katsu boy!\nAre you ready for your adventure?";
		dialogues[0][1] = "There's something useful in the\nforest.";
		dialogues[0][2] = "Welcome to the lost hood.";
		dialogues[0][3] = "Hmmm... you don't remember?";
		dialogues[0][4] = "Try going up north.";
		dialogues[0][5] = "I'm here as long as you need me..";
		
		dialogues[1][0] = "Between you and me theres \na secret teleporter nearby \nthat takes you to a save point!";
		dialogues[1][1] = "Don't tell anyone i told you though...";
		dialogues[1][2] = "Seriously.. DON'T";
		dialogues[1][3] = "You can also reset that \nweird night curse at the KamiMart";
		dialogues[1][4] = "I think I can trust you.";
		dialogues[1][5] = "Sell your items at night. \nCatch that stinkin' gnome...";
		
		dialogues[2][0] = "Well, if it isn't the well known adventurer!";
		dialogues[2][1] = "KATSU BOY!";
		
	}
	public void setAction () {
		
		if(onPath == true) {
			
			int goalCol = 75;
			int goalRow = 95;
//			int goalCol = (gp.player.worldX + gp.player.solidArea.x)/gp.tileSize;
//			int goalRow = (gp.player.worldY + gp.player.solidArea.y)/gp.tileSize;
			
			searchPath(goalCol,goalRow);
		}
		else {
			
			actionLockCounter ++;
			
			if(actionLockCounter == 120) {
				Random random = new Random();
				int i = random.nextInt(100)+1; // pick a number between 1 and 100
				
				if(i < 25) {
					direction = "up";
				}
				if (i >25 && i <=50) {
					direction = "down";
				} 
				if (i > 50 && i <= 75 ) {
					direction = "left";
				}
				if (i > 75 && i <= 100 ) {
					direction = "right";
				}
				
				actionLockCounter= 0;
			}
		}
			
	}
	public void speak() {
		
		// Character specific stuff
		setSound();
		facePlayer();
		startDialogue(this,dialogueSet);
		
		dialogueSet++;
		if(dialogues[dialogueSet][0] == null) {
			
			dialogueSet = 0;
		}
		
		
		onPath = true;
		}
	
}


