package object;

import entity.Entity;
import main.GamePanel;

public class OBJ_Potion_Green extends Entity{
	
	
	GamePanel gp;
	public static final String objName = "Green Potion";
	
	public OBJ_Potion_Green(GamePanel gp) {
		super(gp);
		
		this.gp = gp;
		
		type = type_consumable;
		name = objName;
		value = gp.player.maxMana;
		down1 = setup("/objects/potion",gp.tileSize,gp.tileSize);
		description = "["+name+"]\nHeals your life\n"+value+" HP.";
		price = 10;
		stackable = true;
		
	}
	public void setDialogue() {
		dialogues[0][0] = "You down the "+name+" and recover "+ gp.player.maxMana +" MP.";
	}
	public boolean use(Entity entity) {
		soundNumber = 20;
		setSound();
		setDialogue();
		startDialogue(this,0);
		entity.mana += entity.maxMana;
		gp.playSE(2);
		return true;
	}

}
