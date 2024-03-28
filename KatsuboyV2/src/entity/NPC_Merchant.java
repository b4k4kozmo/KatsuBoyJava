package entity;

import java.awt.Rectangle;

import main.GamePanel;
import object.OBJ_Kami_Shield;
import object.OBJ_Kamibokken;
import object.OBJ_Potion_Green;
import object.OBJ_Tent;

public class NPC_Merchant extends Entity {

	public NPC_Merchant(GamePanel gp) {
		super(gp);
		
		direction = "down";
		speed = 1;
		
		solidArea = new Rectangle();
		solidArea.x = 8;
		solidArea.y = 16;
		solidArea.width = 32;
		solidArea.height = 32;
		solidAreaDefaultX = solidArea.x;
		solidAreaDefaultY = solidArea.y;
		
		
		soundNumber = 20;
		
		getImage();
		setDialogue();
		setItems();
		setSound();
	}
	public void getImage() {
		
		up1 = setup("/npc/kamimon_down_1",gp.tileSize,gp.tileSize);
		up2 = setup("/npc/kamimon_down_2",gp.tileSize,gp.tileSize);
		down1 = setup("/npc/kamimon_down_1",gp.tileSize,gp.tileSize);
		down2 = setup("/npc/kamimon_down_2",gp.tileSize,gp.tileSize);
		left1 = setup("/npc/kamimon_down_1",gp.tileSize,gp.tileSize);
		left2 = setup("/npc/kamimon_down_2",gp.tileSize,gp.tileSize);
		right1 = setup("/npc/kamimon_down_1",gp.tileSize,gp.tileSize);
		right2 = setup("/npc/kamimon_down_2",gp.tileSize,gp.tileSize);
	
	}
	public void setDialogue () {
		
		dialogues[0][0] = "Welcome to Kami Mart! \nWhat'll it be?";
		dialogues[0][1] = "Welcome to the bargain jungle!";
		dialogues[1][0] = "See ya next time!";
		dialogues[2][0] = "No... that's too low!";
		dialogues[3][0] = "Thank you for your purchase!";
		dialogues[4][0] = "Your pockets are full!";
		dialogues[5][0] = "I don't got time for jokes!";
		dialogues[6][0] = "Ohhhhh baby!";
		dialogues[7][0] = "Sure.. I'll take that off your hands..";
		dialogues[8][0] = "I dont sell to the likes of you";
		
	}
	public void setItems() {
		
		inventory.add(new OBJ_Potion_Green(gp));
		inventory.add(new OBJ_Kamibokken(gp));
		inventory.add(new OBJ_Kami_Shield(gp));
		inventory.add(new OBJ_Tent(gp));
	}
	public void speak() {
		
		startDialogue(this,dialogueSet);
		gp.gameState = gp.tradeState;
		gp.ui.npc = this;
	}
}
