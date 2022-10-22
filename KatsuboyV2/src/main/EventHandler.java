package main;

import entity.Entity;

public class EventHandler {

	GamePanel gp;
	EventRect eventRect[][][];
	
	int prevEventX, prevEventY;
	boolean canTouchEvent = true;
	int tempMap, tempCol, tempRow;
	
	
	public EventHandler(GamePanel gp) {
		this.gp = gp;
		
		eventRect = new EventRect[gp.maxMap][gp.maxWorldCol][gp.maxWorldRow];
		
		int map = 0;
		int col = 0;
		int row = 0;
		while(map < gp.maxMap && col < gp.maxWorldCol && row < gp.maxWorldRow) {
			
			eventRect[map][col][row] = new EventRect();
			eventRect[map][col][row].x = 23;
			eventRect[map][col][row].y = 23;
			eventRect[map][col][row].width = 12;
			eventRect[map][col][row].height = 12;
			eventRect[map][col][row].eventRectDefaultX = eventRect[map][col][row].x;
			eventRect[map][col][row].eventRectDefaultY = eventRect[map][col][row].y;
			
			col++;
			if(col == gp.maxWorldCol) {
				col=0;
				row++;
				
				if(row == gp.maxWorldRow) {
					row = 0;
					map++;
				}
			}
		}	
	}
	
	public void checkEvent() {
		
		// check if player character is more than 1 tile away from last event
		
		int xDistance = Math.abs(gp.player.worldX - prevEventX);
		int yDistance = Math.abs(gp.player.worldY - prevEventY);
		int distance = Math.max(xDistance, yDistance);
		if(distance > gp.tileSize) {
			canTouchEvent = true;
		}
		
		
		
		if(canTouchEvent == true) {
			if(hit(0,95,95, "any") == true) { damagePit(gp.dialogueState); }
			else if(hit(0,5,71, "down") == true) { healingPool(gp.dialogueState); }
			else if(hit(0,97,97, "any") == true) { teleport(gp.dialogueState, 5, 70); }
			else if(hit(0,8,46, "any") == true) { changeMap(1,26,32); }
			else if(hit(1,26,32, "any") == true) { changeMap(0,8,46); }
			else if(hit(1,26,20, "up") == true) { speak(gp.npc[1][1]); }
			
			else if(hit(0,10,9, "up") == true) { changeMap(2,82,67); }
			else if(hit(2,82,67, "any") == true) { changeMap(0,10,9); }
			
		}
		
	}
	
	public boolean hit(int map, int col, int row, String reqDirection) {
	
		boolean hit = false;
		
		if(map == gp.currentMap) {
			gp.player.solidArea.x = gp.player.worldX + gp.player.solidArea.x;
			gp.player.solidArea.y = gp.player.worldY + gp.player.solidArea.y;
			eventRect[map][col][row].x = col*gp.tileSize+eventRect[map][col][row].x; 
			eventRect[map][col][row].y = row*gp.tileSize+eventRect[map][col][row].y; 
		
			if(gp.player.solidArea.intersects(eventRect[map][col][row]) && eventRect[map][col][row].eventDone == false) {
				if(gp.player.direction.contentEquals(reqDirection) || reqDirection.contentEquals("any")) {
					hit = true;
					
					prevEventX = gp.player.worldX;
					prevEventY = gp.player.worldY;
			}
		}
		
			gp.player.solidArea.x = gp.player.solidAreaDefaultX;
			gp.player.solidArea.y = gp.player.solidAreaDefaultY;
			eventRect[map][col][row].x = eventRect[map][col][row].eventRectDefaultX;
			eventRect[map][col][row].y = eventRect[map][col][row].eventRectDefaultY;
		}
		return hit;
	}
	public void teleport(int gameState, int x, int y) {
		
		gp.gameState = gameState;
		gp.playSE(4);
		gp.ui.currentDialogue = "Surprise!";
		gp.player.worldX = gp.tileSize*x;
		gp.player.worldY = gp.tileSize*y;	
	}
	public void damagePit(int gameState) {
		gp.gameState = gameState;
		gp.playSE(7);
		gp.ui.currentDialogue = "Ouch! You fell down";
		gp.player.life -= 1;
//		eventRect[col][row].eventDone = true;
		canTouchEvent = false;
	}
	public void healingPool(int gameState) {
		
		if(gp.keyH.enterPressed == true) {
			gp.gameState = gameState;
			gp.player.attackCanceled = true;
			gp.stopSE();
			gp.playSE(2);
			gp.ui.currentDialogue = "Mmmmm... that was tasty. \nYou feel refreshed.";
			gp.player.life = gp.player.maxLife;
			gp.player.mana = gp.player.maxMana; 
			gp.aSetter.setMonster();
			gp.player.isCursed = false;
			
		}	
	}
	public void changeMap(int currentMap, int x, int y) {
		
		gp.gameState = gp.transitionState;
		tempMap = currentMap;
		tempCol = x;
		tempRow = y;
		canTouchEvent = false;
		gp.playSE(13);
	}
	public void speak(Entity entity) {
		
		if(gp.keyH.enterPressed == true) {
			gp.gameState = gp.dialogueState;
			gp.player.attackCanceled = true;
			entity.speak();
		}
	}
		
}
