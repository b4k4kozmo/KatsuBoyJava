package entity;


import java.util.Random;

import main.GamePanel;


public class NPC_NanaMan extends Entity{

	public NPC_NanaMan(GamePanel gp) {
		super(gp);
		
		name = "Nanaman";
		direction = "down";
		speed = 25;
		
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
		dialogues[0] = "Dude, it's me!";
		dialogues[1] = "Just call me Nanaman for now..";
		dialogues[2] = "777";
		dialogues[3] = "Hmmm... you don't remember?";
		dialogues[4] = "You're faster than I imagined.";
		dialogues[5] = "I can wall grab!";
		
		
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
		
		super.speak();
		}
	
}


