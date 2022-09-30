package object;

import entity.Entity;
import main.GamePanel;

public class OBJ_Potion_Green extends Entity{
	
	
	GamePanel gp;
	
	
	public OBJ_Potion_Green(GamePanel gp) {
		super(gp);
		
		this.gp = gp;
		
		type = type_consumable;
		name = "Green Potion";
		value = gp.player.maxMana;
		down1 = setup("/objects/potion",gp.tileSize,gp.tileSize);
		description = "["+name+"]\nHeals your life\n"+value+" HP.";
		price = 10;
	}
	
	public void use(Entity entity) {
		gp.gameState = gp.dialogueState;
		gp.ui.currentDialogue = "You down the "+name+" and recover "+value+" MP.";
		entity.mana += value;
		gp.playSE(2);
	}

}
