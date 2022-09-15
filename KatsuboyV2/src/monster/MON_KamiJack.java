package monster;

import java.util.Random;

import entity.Entity;
import main.GamePanel;

public class MON_KamiJack extends Entity{

	GamePanel gp;
	
	public MON_KamiJack(GamePanel gp) {
		super(gp);
		
		this.gp = gp;
		
		type = 2;
		name = "Kamijack";
		speed = 1;
		maxLife = 12;
		life = maxLife;
		
		solidArea.x = 6;
		solidArea.y = 24;
		solidArea.width = 36;
		solidArea.height = 24;
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
	}
	
	public void damageReaction() {
		
		actionLockCounter = 0;
		
		
	}

}
