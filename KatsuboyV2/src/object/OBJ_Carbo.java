package object;

import entity.Entity;

import main.GamePanel;

public class OBJ_Carbo extends Entity{
	
	
	public OBJ_Carbo(GamePanel gp) {
		super(gp);
		
		
		name = "Carbuncle";
		down1 = setup("/objects/carbuncle_green_1",gp.tileSize,gp.tileSize);
		price = 10;
		
		
		
		
	}

}
	

