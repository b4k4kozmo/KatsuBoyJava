package object;

import entity.Entity;
import main.GamePanel;

public class OBJ_Sword_Normal extends Entity{
	public static final String objName = "Normal Sword";
	public OBJ_Sword_Normal(GamePanel gp) {
		super(gp);
		
		type = type_sword;
		name = objName;
		down1 = setup("/objects/sword",gp.tileSize,gp.tileSize);
		attackValue = 1;
		attackArea.width = 36;
		attackArea.height = 36;
		description = "[" + name + "]\nKatsu boy's sword.";
		price = 10;
		knockBackPower = 3;
		motion1_duration = 5;
		motion2_duration = 25;
		
	}

}
