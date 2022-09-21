package monster;

import java.util.Random;

import entity.Entity;
import main.GamePanel;
import object.OBJ_Coin;
import object.OBJ_Heart;
import object.OBJ_Potion_Green;

public class MON_KamiJack extends Entity{

	GamePanel gp;
	
	public MON_KamiJack(GamePanel gp) {
		super(gp);
		
		this.gp = gp;
		
		type = type_monster;
		name = "Kamijack";
		speed = 12;
		maxLife = 111;
		life = maxLife;
		attack = 20;
		defense = 6;
		exp = 250;
		
		solidArea.x = 3;
		solidArea.y = 18;
		solidArea.width = 42;
		solidArea.height = 30;
		solidAreaDefaultX = solidArea.x;
		solidAreaDefaultY = solidArea.y;
		
		getImage();
	}
	
	public void getImage() {
		
		up1 = setup("/monster/kamijack_down_1",gp.tileSize*2,gp.tileSize*2);
		up2 = setup("/monster/kamijack_down_2",gp.tileSize*2,gp.tileSize*2);
		down1 = setup("/monster/kamijack_down_1",gp.tileSize*2,gp.tileSize*2);
		down2 = setup("/monster/kamijack_down_2",gp.tileSize*2,gp.tileSize*2);
		left1 = setup("/monster/kamijack_down_1",gp.tileSize*2,gp.tileSize*2);
		left2 = setup("/monster/kamijack_down_2",gp.tileSize*2,gp.tileSize*2);
		right1 = setup("/monster/kamijack_down_1",gp.tileSize*2,gp.tileSize*2);
		right2 = setup("/monster/kamijack_down_2",gp.tileSize*2,gp.tileSize*2);
	}
	
	public void setAction () {
		
		actionLockCounter++;
		int slowDown = 60;
		
		if(actionLockCounter == slowDown) {
			
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
	}
	
	public void damageReaction() {
		actionLockCounter= 0;
		speed = 3;
		slowDown = 120;
				
		
		
		
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
