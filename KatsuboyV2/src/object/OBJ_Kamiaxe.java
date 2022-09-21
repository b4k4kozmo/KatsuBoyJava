package object;

import entity.Entity;
import main.GamePanel;

public class OBJ_Kamiaxe extends Entity {

	public OBJ_Kamiaxe(GamePanel gp) {
		super(gp);
		
		type = type_axe;
		name = "Kami Axe";
		down1 = setup("/objects/axe",gp.tileSize,gp.tileSize);
		attackValue = 4;
		attackArea.width = 24;
		attackArea.height = 24;
		description = "[" + name + "]\nA strong axe forged\nby dreams.";
		
	}
	
}
