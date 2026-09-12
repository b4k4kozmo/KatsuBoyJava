class_name SE
extends RefCounted
## Names for the sound slots, so calls read as gp.play_se(SE.COIN) instead of
## gp.play_se(SE.COIN).
##
## The number is the slot in the SoundBank resource
## (assets/data/sound_bank.tres). To change which file a sound uses, open that
## resource and swap the stream - no code change. To add a new sound, append it
## to the bank and add a constant here.

const MUSIC_MAIN := 0
const COIN := 1
const POWER_UP := 2
const UNLOCK := 3
const FANFARE := 4
const MUSIC_NIGHT := 5
const HIT_MONSTER := 6
const RECEIVE_DAMAGE := 7
const SWING_WEAPON := 8
const ENEMY_DEATH := 9
const DIALOGUE := 10
const CURSOR_MOVE := 11
const DEATH := 12
const DOOR := 13
const SLEEP := 14
const BLOCK := 15
const PARRY := 16
const TEXT_1 := 17
const TEXT_2 := 18
const TEXT_3 := 19
const TEXT_4 := 20
