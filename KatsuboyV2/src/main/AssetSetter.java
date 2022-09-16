package main;

import entity.NPC_NanaMan;
import entity.NPC_OldMan;
import monster.MON_KamiJack;
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
		
		
		int i = 0;
		gp.monster[i] = new MON_Snome(gp);
		gp.monster[i].worldX = gp.tileSize*82;
		gp.monster[i].worldY = gp.tileSize*95;
		i++;
		gp.monster[i] = new MON_Slime(gp);
		gp.monster[i].worldX = gp.tileSize*58;
		gp.monster[i].worldY = gp.tileSize*79;
		i++;
		gp.monster[i] = new MON_Slime(gp);
		gp.monster[i].worldX = gp.tileSize*8;
		gp.monster[i].worldY = gp.tileSize*55;
		i++;
		gp.monster[i] = new MON_Slime(gp);
		gp.monster[i].worldX = gp.tileSize*8;
		gp.monster[i].worldY = gp.tileSize*51;
		i++;
		gp.monster[i] = new MON_Slime(gp);
		gp.monster[i].worldX = gp.tileSize*8;
		gp.monster[i].worldY = gp.tileSize*46;
		i++;
		gp.monster[i] = new MON_Slime(gp);
		gp.monster[i].worldX = gp.tileSize*8;
		gp.monster[i].worldY = gp.tileSize*35;
		i++;
		gp.monster[i] = new MON_KamiJack(gp);
		gp.monster[i].worldX = gp.tileSize*90;
		gp.monster[i].worldY = gp.tileSize*79;
		i++;
		gp.monster[i] = new MON_Slime(gp);
		gp.monster[i].worldX = gp.tileSize*84;
		gp.monster[i].worldY = gp.tileSize*93;
		i++;
		gp.monster[i] = new MON_Snome(gp);
		gp.monster[i].worldX = gp.tileSize*80;
		gp.monster[i].worldY = gp.tileSize*90;
		i++;
		gp.monster[i] = new MON_Snome(gp);
		gp.monster[i].worldX = gp.tileSize*80;
		gp.monster[i].worldY = gp.tileSize*88;
		i++;
		gp.monster[i] = new MON_Snome(gp);
		gp.monster[i].worldX = gp.tileSize*80;
		gp.monster[i].worldY = gp.tileSize*87;
		i++;
		gp.monster[i] = new MON_Snome(gp);
		gp.monster[i].worldX = gp.tileSize*79;
		gp.monster[i].worldY = gp.tileSize*87;
		i++;
		gp.monster[i] = new MON_Snome(gp);
		gp.monster[i].worldX = gp.tileSize*78;
		gp.monster[i].worldY = gp.tileSize*87;
		i++;
		gp.monster[i] = new MON_Snome(gp);
		gp.monster[i].worldX = gp.tileSize*77;
		gp.monster[i].worldY = gp.tileSize*87;
		i++;
		gp.monster[i] = new MON_Snome(gp);
		gp.monster[i].worldX = gp.tileSize*77;
		gp.monster[i].worldY = gp.tileSize*86;
		i++;
		gp.monster[i] = new MON_Snome(gp);
		gp.monster[i].worldX = gp.tileSize*77;
		gp.monster[i].worldY = gp.tileSize*86;
		i++;
		gp.monster[i] = new MON_Snome(gp);
		gp.monster[i].worldX = gp.tileSize*76;
		gp.monster[i].worldY = gp.tileSize*86;
		i++;
		gp.monster[i] = new MON_Snome(gp);
		gp.monster[i].worldX = gp.tileSize*77;
		gp.monster[i].worldY = gp.tileSize*85;
		i++;
		gp.monster[i] = new MON_Snome(gp);
		gp.monster[i].worldX = gp.tileSize*76;
		gp.monster[i].worldY = gp.tileSize*87;
		i++;
		gp.monster[i] = new MON_KamiJack(gp);
		gp.monster[i].worldX = gp.tileSize*88;
		gp.monster[i].worldY = gp.tileSize*79;
		i++;
		gp.monster[i] = new MON_KamiJack(gp);
		gp.monster[i].worldX = gp.tileSize*89;
		gp.monster[i].worldY = gp.tileSize*79;
		i++;
		gp.monster[i] = new MON_KamiJack(gp);
		gp.monster[i].worldX = gp.tileSize*90;
		gp.monster[i].worldY = gp.tileSize*78;
		i++;
	}
	
}
