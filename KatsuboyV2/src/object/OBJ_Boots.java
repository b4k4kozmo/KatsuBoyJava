package object;

import entity.Entity;
import main.GamePanel;

public class OBJ_Boots extends Entity{
	
	public static final String objName = "Boots";
	
	public OBJ_Boots(GamePanel gp) {
		super(gp);
		
		
		name = objName;
		down1 = setup("/objects/boots",gp.tileSize,gp.tileSize);
		description = "[" + name + "]\nGotta go fast!";
		price = 10;
	}

}
	

