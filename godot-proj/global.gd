extends Node2D

const DEBUG_MODE : bool = true;

#===============================================================================
#---- MAIN MENU and DATA VARS --------------------------------------------------
# if using this for a different game, CHANGE THE NEXT LINE FIRST!
const game_data_base : String = "user://kkringle_001";
const options_path 		= game_data_base + "-options";
const hiscore_path 		= game_data_base + "-hiscores";

const GAME_SUPPORTS_SAVING 			: bool = true;
const GAME_SUPPORTS_HIGH_SCORES		: bool = false;
const GAME_SUPPORTS_TROPHIES			: bool = true;

var sfx_vol 		: int 	= 255;
var music_vol 		: int 	= 255;
var use_joystick 	: bool	= true;

#===============

func save_options_data():
	var fout : File = File.new();

	fout.open(options_path, fout.WRITE);
	sfx_vol = int(clamp(sfx_vol,0, 255));
	fout.store_8(sfx_vol);
	music_vol = int(clamp(music_vol, 0, 255));
	fout.store_8(music_vol);
	fout.store_8(use_joystick);
	fout.close();
	
	return;
	
#===============

func load_options_data():
	var fin : File = File.new();
		
	if (fin.file_exists(options_path)):
		fin.open(options_path, fin.READ);
		sfx_vol = fin.get_8();
		music_vol = fin.get_8();
		use_joystick = fin.get_8();
		fin.close();
	else:
		save_options_data();
	return;

#===============================================================================
#--- MUSIC PLAYER VARS & FUNCS -------------------------------------------------
var curr_music_id_priv 			: int = 0;
var next_music_id_priv			: int = 0;
var curr_music_fadevol_priv 	: int = -1;
var bgm_player 					: AudioStreamPlayer;
var bgm_file						: Resource = null;

const music_fadeout_step_size	: int = 3;

#-------------------------------------------------------------------------------
func play_BGM(id:int):
	if (id == curr_music_id_priv):
		return;
	else:
		next_music_id_priv = id;

#-------------------------------------------------------------------------------
func bgm_fade_helper_priv():
	bgm_player.volume_db = (((curr_music_fadevol_priv / 255.0) * (music_vol / 255.0)) * 50.0) - 49.7;
	
	# fade in
	if (curr_music_id_priv == next_music_id_priv):
		curr_music_fadevol_priv += music_fadeout_step_size * 16.0;
		curr_music_fadevol_priv = clamp(curr_music_fadevol_priv,0,255);
		return;
	
	#fade out
	curr_music_fadevol_priv -= music_fadeout_step_size; 

	if (curr_music_fadevol_priv < 0):
		curr_music_fadevol_priv = 0;
		bgm_player.stop();
		curr_music_id_priv = next_music_id_priv;		
		
		var music_path = "res://bgm/%02d.ogg" % next_music_id_priv;
		
		if (File.new().file_exists(music_path)):
			bgm_file = load(music_path);
			bgm_player.stream = bgm_file;
			bgm_player.play();
	
	return;
			
	

#---- SCREEN TRANSITION VARS  --------------------------------------------------
# these are here as a workaround for gdscript not having static vars

const SCREENWIPE_MAX_TICKS	: int = 80;

var screenwipe_anim_clock	: int;
var screenwipe_direction	: bool; # true for out, false for in
var screenwipe_active		: bool;
var screenwipe_next_scene;

#---- MAIN UI TYPEFACE ---------------------------------------------------------

var mainfont	: BitmapFont = null;

#---- JOYSTICK VARS ------------------------------------------------------------

enum BUTTON_STATE {
	IDLE,
	PRESSED,
	HELD
};

var _left_stick_angle : float;
var _left_stick_distance : float;
var _right_stick_x : float;
var _right_stick_y : float;

var _menu_up : int = BUTTON_STATE.IDLE;
var _menu_down : int = BUTTON_STATE.IDLE;

var _button_start : int = BUTTON_STATE.IDLE;
var _button_select : int = BUTTON_STATE.IDLE;
var _button_a : int = BUTTON_STATE.IDLE;
var _button_b : int = BUTTON_STATE.IDLE;
var _button_x : int = BUTTON_STATE.IDLE;
var _button_y : int = BUTTON_STATE.IDLE;
var _button_L2 : int = BUTTON_STATE.IDLE;
var _button_R2 : int = BUTTON_STATE.IDLE;

func poll_joystick():
	if (screenwipe_active):
		_button_start  = BUTTON_STATE.IDLE;
		_button_select = BUTTON_STATE.IDLE;
		_button_a  = BUTTON_STATE.IDLE;
		_button_b  = BUTTON_STATE.IDLE;
		_button_x  = BUTTON_STATE.IDLE;
		_button_y  = BUTTON_STATE.IDLE;		
		_menu_up  = BUTTON_STATE.IDLE;
		_menu_down  = BUTTON_STATE.IDLE;
		
		return;
	
	if (use_joystick):
		
		#--- ANALOGUE STICKS --------------------------
		var left_tmp : Vector2 = Vector2(Input.get_joy_axis(0,JOY_ANALOG_LX), Input.get_joy_axis(0,JOY_ANALOG_LY));
		
		_left_stick_distance = left_tmp.length();
		_left_stick_angle = left_tmp.angle();
		
		_right_stick_x = Input.get_joy_axis(0,JOY_ANALOG_RX);
		_right_stick_y = Input.get_joy_axis(0,JOY_ANALOG_RY);
		
		#--- affordance for navigating menus ----------
		
		if ((left_tmp.y < -0.7) or (Input.is_joy_button_pressed(0, JOY_DPAD_UP))):
			_menu_up = _menu_up + 1;
		else:
			_menu_up = BUTTON_STATE.IDLE;
		
		if ((left_tmp.y > 0.7) or (Input.is_joy_button_pressed(0, JOY_DPAD_DOWN))):
			_menu_down = _menu_down + 1;
		else:
			_menu_down = BUTTON_STATE.IDLE;
			
		
		#--- BUTTONS ----------------------------------
		#----------
		
		if (Input.is_joy_button_pressed(0, JOY_XBOX_A)):
			_button_a = _button_a + 1;
			_button_a = int(clamp(_button_a,0,2.0));
		else:
			_button_a = BUTTON_STATE.IDLE;
		
		#----------
		
		if (Input.is_joy_button_pressed(0, JOY_XBOX_B)):
			if (_button_b == BUTTON_STATE.PRESSED):
				_button_b = BUTTON_STATE.HELD;
			else:
				_button_b = BUTTON_STATE.PRESSED;
		else:
			_button_b = BUTTON_STATE.IDLE;
		
		#----------
		
		if (Input.is_joy_button_pressed(0, JOY_XBOX_X)):
			_button_x = _button_x + 1;
			_button_x = int(clamp(_button_x,0,2.0));
		else:
			_button_x = BUTTON_STATE.IDLE;
		
		#----------
		
		if (Input.is_joy_button_pressed(0, JOY_XBOX_Y)):
			if (_button_y == BUTTON_STATE.PRESSED):
				_button_y = BUTTON_STATE.HELD;
			else:
				_button_y = BUTTON_STATE.PRESSED;
		else:
			_button_y = BUTTON_STATE.IDLE;
		
		#----------

		if (Input.is_joy_button_pressed(0, JOY_L2)):
			if (_button_L2 == BUTTON_STATE.PRESSED):
				_button_L2 = BUTTON_STATE.HELD;
			else:
				_button_L2 = BUTTON_STATE.PRESSED;
		else:
			_button_L2 = BUTTON_STATE.IDLE;
		
		#----------
		
		if (Input.is_joy_button_pressed(0, JOY_R2)):
			if (_button_R2 == BUTTON_STATE.PRESSED):
				_button_R2 = BUTTON_STATE.HELD;
			else:
				_button_R2 = BUTTON_STATE.PRESSED;
		else:
			_button_R2 = BUTTON_STATE.IDLE;
		
		#----------
		
		if (Input.is_joy_button_pressed(0, JOY_START)):
			if (_button_start == BUTTON_STATE.PRESSED):
				_button_start = BUTTON_STATE.HELD;
			else:
				_button_start = BUTTON_STATE.PRESSED;
		else:
			_button_start = BUTTON_STATE.IDLE;

		#----------
		
		if (Input.is_joy_button_pressed(0, JOY_SELECT)):
			if (_button_select == BUTTON_STATE.PRESSED):
				_button_select = BUTTON_STATE.HELD;
			else:
				_button_select = BUTTON_STATE.PRESSED;
		else:
			_button_select = BUTTON_STATE.IDLE;
			
	else:
	#--- KEYBOARD --------------------------------------
		#--- ANALOGUE STICKS --------------------------
		
		if (Input.is_key_pressed(KEY_W)):
			_left_stick_distance = 1.0;
			if (Input.is_key_pressed(KEY_A)):
				_left_stick_angle = deg2rad(135);
			elif (Input.is_key_pressed(KEY_D)):
				_left_stick_angle = deg2rad(45);
			else:
				_left_stick_angle = deg2rad(90);
		elif (Input.is_key_pressed(KEY_S)):
			_left_stick_distance = 1.0;
			if (Input.is_key_pressed(KEY_A)):
				_left_stick_angle = deg2rad(225);
			elif (Input.is_key_pressed(KEY_D)):
				_left_stick_angle = deg2rad(315);
			else:
				_left_stick_angle = deg2rad(270);
		elif (Input.is_key_pressed(KEY_A)):
			_left_stick_distance = 1.0;
			_left_stick_angle = deg2rad(180);
		elif (Input.is_key_pressed(KEY_D)):
			_left_stick_distance = 1.0;
			_left_stick_angle = deg2rad(0);
		else:
			_left_stick_distance = 0;

		var mouse_vec : Vector2 = get_viewport().get_mouse_position() - (get_viewport().size / Vector2(2.0,2.0)); 
		 
		_right_stick_x = mouse_vec.x;
		_right_stick_y = mouse_vec.y;
		
		#--- BUTTONS ----------------------------------
		#----------
		
		if (Input.is_mouse_button_pressed(0)):
			_button_a = _button_a + 1;
			_button_a = int(clamp(_button_a,0,2.0));
		else:
			_button_a = BUTTON_STATE.IDLE;
		
		#----------
		
		if (Input.is_mouse_button_pressed(1)):
			if (_button_b == BUTTON_STATE.PRESSED):
				_button_b = BUTTON_STATE.HELD;
			else:
				_button_b = BUTTON_STATE.PRESSED;
		else:
			_button_b = BUTTON_STATE.IDLE;
		
		#----------

		if (Input.is_key_pressed(KEY_R)):
			if (_button_L2 == BUTTON_STATE.PRESSED):
				_button_L2 = BUTTON_STATE.HELD;
			else:
				_button_L2 = BUTTON_STATE.PRESSED;
		else:
			_button_L2 = BUTTON_STATE.IDLE;
		
		#----------
		
		if (Input.is_key_pressed(KEY_F)):
			if (_button_R2 == BUTTON_STATE.PRESSED):
				_button_R2 = BUTTON_STATE.HELD;
			else:
				_button_R2 = BUTTON_STATE.PRESSED;
		else:
			_button_R2 = BUTTON_STATE.IDLE;
		
		#----------
		
		if (Input.is_key_pressed(KEY_ENTER)):
			if (_button_start == BUTTON_STATE.PRESSED):
				_button_start = BUTTON_STATE.HELD;
			else:
				_button_start = BUTTON_STATE.PRESSED;
		else:
			_button_start = BUTTON_STATE.IDLE;

		#----------
		
		if (Input.is_key_pressed(KEY_BACKSPACE)):
			if (_button_select == BUTTON_STATE.PRESSED):
				_button_select = BUTTON_STATE.HELD;
			else:
				_button_select = BUTTON_STATE.PRESSED;
		else:
			_button_select = BUTTON_STATE.IDLE;

	return;

#-------------------------------------------------------------------------------

func load_fonts():
	mainfont = BitmapFont.new();
	mainfont.set_height(14);
	mainfont.add_texture(load("res://gfx/font/mainfont.png"));
		
	var x_index;
	var y_index;
	var char_index = 32;
	
	for y_index in range (0,7):
		for x_index in range (0, 16):
			mainfont.add_char(char_index,0,Rect2(Vector2((x_index*16) + 2, (y_index*16)+2), Vector2(9,13)));
			char_index += 1;  
	
	return;

#-------------------------------------------------------------------------------

func _ready():
	# music player
	bgm_player = AudioStreamPlayer.new();
	add_child(bgm_player);	
	
	# ui typeface
	load_fonts();
	
	# ready screen transition mechanism
	# for use
	screenwipe_direction 	= true;
	screenwipe_anim_clock	= 0;
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN);
	
	set_process(true);
	return;

#-------------------------------------------------------------------------------

func _process(_ignored):
	# --- music manager
	bgm_fade_helper_priv();
	
	# --- gather input
	poll_joystick();
	
	# --- manage screenwipe if needed
	if (screenwipe_active):
		if (screenwipe_direction):
			screenwipe_anim_clock += 1;
			
			if (screenwipe_anim_clock >= SCREENWIPE_MAX_TICKS):
				screenwipe_active = false;
				screenwipe_direction = false;
				if (screenwipe_next_scene == null):
					get_tree().quit();
				else:
					get_node("/root/main/colour_ruiner/game_root").change_scene_to(screenwipe_next_scene);
		else:
			screenwipe_anim_clock -= 1;
			if (screenwipe_anim_clock < 1):
				screenwipe_active = false;
	
	# hotkey to get out 
	if (DEBUG_MODE):
		if (Input.is_key_pressed(KEY_ESCAPE) and Input.is_key_pressed(KEY_Q)):
			get_tree().quit();
	return;

#-------------------------------------------------------------------------------

func change_scene_to(in_scene):
	if (screenwipe_active):
		return;

	screenwipe_direction 	= true;
	screenwipe_active			= true;
	screenwipe_next_scene	= in_scene;
	screenwipe_anim_clock	= 0;
	play_BGM(0);
	
#-------------------------------------------------------------------------------

func new_scene_screenwipe_start():
	if (screenwipe_active):
		return;

	screenwipe_active			= true;
	screenwipe_direction 	= false;
	screenwipe_anim_clock	= SCREENWIPE_MAX_TICKS;
	