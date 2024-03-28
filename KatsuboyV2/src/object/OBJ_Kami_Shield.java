package object;

import entity.Entity;
import main.GamePanel;

public class OBJ_Kami_Shield extends Entity{
	
	public static final String objName = "Kami Shield";
	public OBJ_Kami_Shield(GamePanel gp) {
		super(gp);
		
		type = type_shield;
		name = objName;
		down1 = setup("/objects/kamishield",gp.tileSize,gp.tileSize);
		defenseValue = 2;
		description = "[" + name + "]\nHeavy shield crafted\nby Kami-mon.";
		price = 100;
	}
}
