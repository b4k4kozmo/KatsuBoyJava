package object;

import entity.Entity;
import main.GamePanel;

public class OBJ_Kamibokken extends Entity {

	public OBJ_Kamibokken(GamePanel gp) {
		super(gp);

		type = type_sword;
		name = "Kami no Bokken";
		down1 = setup("/objects/kamibokken", gp.tileSize,gp.tileSize);
		attackValue = 3;
		attackArea.width = 48;
		attackArea.height = 52;
		description = "[" + name + "]\nWooden training sword.\nStronger than it looks.";
		price = 21;
		knockBackPower = 9;
	}

}
