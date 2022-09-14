package main;

import entity.NPC_NanaMan;
import entity.NPC_OldMan;
import monster.MON_Slime;
import monster.MON_Snome;
import object.OBJ_Boots;
import object.OBJ_Carbo;


public class AssetSetter {
	
	GamePanel gp;
	
	public AssetSetter(GamePanel gp) {
		this.gp = gp;
	}
	
	public void setObject() {
		
	
		gp.obj[0] = new OBJ_Boots(gp);
		gp.obj[0].worldX = 50 * gp.tileSize;
		gp.obj[0].worldY = 97 * gp.tileSize;
		
		
		gp.obj[1] = new OBJ_Carbo(gp);
		gp.obj[1].worldX = 52 * gp.tileSize;
		gp.obj[1].worldY = 98 * gp.tileSize;
	}
	public void setNPC() {
		
		gp.npc[0] = new NPC_OldMan (gp);
		gp.npc[0].worldX = gp.tileSize*82;
		gp.npc[0].worldY = gp.tileSize*20;
	
	
		
		gp.npc[2] = new NPC_OldMan (gp);
		gp.npc[2].worldX = gp.tileSize*96;
		gp.npc[2].worldY = gp.tileSize*95;
		
		gp.npc[3] = new NPC_NanaMan (gp);
		gp.npc[3].worldX = gp.tileSize*93;
		gp.npc[3].worldY = gp.tileSize*80;
	}
	
	public void setMonster() {
		
		gp.monster[0] = new MON_Snome(gp);
		gp.monster[0].worldX = gp.tileSize*82;
		gp.monster[0].worldY = gp.tileSize*95;
		
		gp.monster[1] = new MON_Slime(gp);
		gp.monster[1].worldX = gp.tileSize*58;
		gp.monster[1].worldY = gp.tileSize*79;
		
		gp.monster[2] = new MON_Slime(gp);
		gp.monster[2].worldX = gp.tileSize*8;
		gp.monster[2].worldY = gp.tileSize*55;
		
		gp.monster[3] = new MON_Slime(gp);
		gp.monster[3].worldX = gp.tileSize*8;
		gp.monster[3].worldY = gp.tileSize*51;
		
		gp.monster[4] = new MON_Slime(gp);
		gp.monster[4].worldX = gp.tileSize*8;
		gp.monster[4].worldY = gp.tileSize*46;
		
		gp.monster[5] = new MON_Slime(gp);
		gp.monster[5].worldX = gp.tileSize*8;
		gp.monster[5].worldY = gp.tileSize*35;
		
	}
}
