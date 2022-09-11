package entity;


import java.util.Random;

import main.GamePanel;


public class NPC_OldMan extends Entity{

	public NPC_OldMan(GamePanel gp) {
		super(gp);
		
		direction = "down";
		speed = 1;
		
		getImage();
		setDialogue();
		
	}
	public void getImage() {
		
		up1 = setup("/npc/oldman_up_01");
		up2 = setup("/npc/oldman_up_02");
		down1 = setup("/npc/oldman_down_01");
		down2 = setup("/npc/oldman_down_02");
		left1 = setup("/npc/oldman_left_01");
		left2 = setup("/npc/oldman_left_02");
		right1 = setup("/npc/oldman_right_01");
		right2 = setup("/npc/oldman_right_02");
	
	}
	public void setDialogue () {
		dialogues[0] = "Hello, Katsu boy!\nAre you ready for your adventure?";
		dialogues[1] = "There's something useful in the\nforest.";
		dialogues[2] = "Welcome to the lost hood.";
		dialogues[3] = "Hmmm... you don't remember?";
		dialogues[4] = "Try going up north.";
		dialogues[5] = "I'm here as long as you need me..";
		
		
	}
	public void setAction () {
		
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
	public void speak() {
		
		// Character specific stuff
		
		super.speak();
		}
	
}


