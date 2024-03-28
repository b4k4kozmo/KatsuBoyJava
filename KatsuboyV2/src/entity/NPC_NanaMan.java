package entity;


import java.awt.Rectangle;
import java.util.Random;

import main.GamePanel;


public class NPC_NanaMan extends Entity{

	public NPC_NanaMan(GamePanel gp) {
		super(gp);
		
		name = "Nanaman";
		direction = "down";
		speed = 25;
		soundNumber = 19;
		
		solidArea = new Rectangle();
		solidArea.x = 3;
		solidArea.y = 18;
		solidArea.width = 42;
		solidArea.height = 30;
		solidAreaDefaultX = solidArea.x;
		solidAreaDefaultY = solidArea.y;
		
		getImage();
		setDialogue();
		
	}
	public void getImage() {
		
		up1 = setup("/npc/nanaman_1",gp.tileSize,gp.tileSize);
		up2 = setup("/npc/nanaman_2",gp.tileSize,gp.tileSize);
		down1 = setup("/npc/nanaman_3",gp.tileSize,gp.tileSize);
		down2 = setup("/npc/nanaman_4",gp.tileSize,gp.tileSize);
		left1 = setup("/npc/nanaman_4",gp.tileSize,gp.tileSize);
		left2 = setup("/npc/nanaman_3",gp.tileSize,gp.tileSize);
		right1 = setup("/npc/nanaman_1",gp.tileSize,gp.tileSize);
		right2 = setup("/npc/nanaman_2",gp.tileSize,gp.tileSize);
	
	}
	public void setDialogue () {
		dialogues[0][0] = "Dude, it's me!";
		dialogues[0][1] = "Just call me Nanaman for now..";
		dialogues[0][2] = "777";
		dialogues[0][3] = "Hmmm... you don't remember?";
		dialogues[0][4] = "You're faster than I imagined.";
		dialogues[0][5] = "I can wall grab!";
		
		
	}
	public void setAction () {
		
		actionLockCounter ++;
		if(actionLockCounter == 45) {
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
	
	public void speak() {
		
		// Character specific stuff
		
		setSound();
		facePlayer();
		startDialogue(this,dialogueSet);
		
		if(gp.player.level <= 7) {
			gp.player.exp += 444;
			gp.player.isCursed = false;
			if(gp.player.hasBoots == false) {
				gp.player.exp += 777;
				gp.player.hasBoots = true;
			}
			if(gp.player.level == 1) {
				gp.player.exp += 111;
			}
			
		}
		gp.player.checkLevelUp();
	
	}
}


