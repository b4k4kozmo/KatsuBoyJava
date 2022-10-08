package object;

import entity.Entity;
import main.GamePanel;

public class OBJ_Kami_Shield extends Entity{
	public OBJ_Kami_Shield(GamePanel gp) {
		super(gp);
		
		type = type_shield;
		name = "Kami Shield";
		down1 = setup("/objects/kamishield",gp.tileSize,gp.tileSize);
		defenseValue = 2;
		description = "[" + name + "]\nHeavy shield crafted\nby Kami-mon.";
		price = 100;
	}
}
