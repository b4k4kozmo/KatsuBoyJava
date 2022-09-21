package monster;

import java.util.Random;

import entity.Entity;
import main.GamePanel;
import object.OBJ_Coin;
import object.OBJ_Heart;
import object.OBJ_Potion_Green;
import object.OBJ_Snowball;

public class MON_Snome extends Entity{

	GamePanel gp;
	
	public MON_Snome(GamePanel gp) {
		super(gp);
		
		this.gp = gp;
		
		type = type_monster;
		name = "Snome";
		speed = 1;
		maxLife = 21;
		life = maxLife;
		attack = 3;
		defense = 1;
		exp = 3;
		projectile = new OBJ_Snowball(gp);
		
		solidArea.x = 3;
		solidArea.y = 18;
		solidArea.width = 42;
		solidArea.height = 30;
		solidAreaDefaultX = solidArea.x;
		solidAreaDefaultY = solidArea.y;
		
		getImage();
	}
	
	public void getImage() {
		
		up1 = setup("/monster/snome_down_1",gp.tileSize,gp.tileSize);
		up2 = setup("/monster/snome_down_2",gp.tileSize,gp.tileSize);
		down1 = setup("/monster/snome_down_1",gp.tileSize,gp.tileSize);
		down2 = setup("/monster/snome_down_2",gp.tileSize,gp.tileSize);
		left1 = setup("/monster/snome_down_1",gp.tileSize,gp.tileSize);
		left2 = setup("/monster/snome_down_2",gp.tileSize,gp.tileSize);
		right1 = setup("/monster/snome_down_1",gp.tileSize,gp.tileSize);
		right2 = setup("/monster/snome_down_2",gp.tileSize,gp.tileSize);
	}
	
	public void setAction () {
		
		actionLockCounter ++;
		
		if(actionLockCounter == 120) {
			
			Random random = new Random();
			int i = random.nextInt(100)+1; // pick a number between 1 and 100
			
			if(i < 25) {
				direction = "up";
			}
			if (i >25 && i <=50) {
				direction = "down";
			} 
			if (i > 50 && i <= 75 ) {
				direction = "left";
			}
			if (i > 75 && i <= 100 ) {
				direction = "right";
			}
			
			actionLockCounter= 0;
			
			
		}
		
		int i = new Random().nextInt(100)+1;
		if(i > 99 && projectile.alive == false && shotAvailableCounter == 30) {
			projectile.set(worldX, worldY, direction, true, this);
			gp.projectileList.add(projectile);
			shotAvailableCounter = 0;
		}
	}
	public void damageReaction() {
		
	}
	public void checkDrop() {
		
		// CAST A DIE
		int i = new Random().nextInt(100)+1;
		
		//SET THE MONSTER DROP
		if(i< 50) {
			dropItem(new OBJ_Coin(gp));
		}
		if (i >= 50 && 1 < 75) {
			dropItem(new OBJ_Potion_Green(gp));
		}
		if (i >= 74 && i < 100) {
			dropItem(new OBJ_Heart(gp));
		}
	}

}
