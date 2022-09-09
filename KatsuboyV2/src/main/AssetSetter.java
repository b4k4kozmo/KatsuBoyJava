package main;

import object.OBJ_Boots;
import object.OBJ_Chest;
import object.OBJ_Door;
import object.OBJ_Key;

public class AssetSetter {
	
	GamePanel gp;
	
	public AssetSetter(GamePanel gp) {
		this.gp = gp;
	}
	
	public void setObject() {
		
		gp.obj[0] = new OBJ_Key(gp);
		gp.obj[0].worldX = 8 * gp.tileSize;
		gp.obj[0].worldY = 8 * gp.tileSize;	
		
		gp.obj[1] = new OBJ_Key(gp);
		gp.obj[1].worldX = 41 * gp.tileSize;
		gp.obj[1].worldY =	8 * gp.tileSize;
		
		gp.obj[2] = new OBJ_Door(gp);
		gp.obj[2].worldX = 29 * gp.tileSize;
		gp.obj[2].worldY = 30 * gp.tileSize;
		
		gp.obj[3] = new OBJ_Door(gp);
		gp.obj[3].worldX = 33 * gp.tileSize;
		gp.obj[3].worldY = 30 * gp.tileSize;
		
		gp.obj[4] = new OBJ_Chest(gp);
		gp.obj[4].worldX = 39 * gp.tileSize;
		gp.obj[4].worldY = 30 * gp.tileSize;
		
		gp.obj[5] = new OBJ_Boots(gp);
		gp.obj[5].worldX = 50 * gp.tileSize;
		gp.obj[5].worldY = 97 * gp.tileSize;
	}

}
