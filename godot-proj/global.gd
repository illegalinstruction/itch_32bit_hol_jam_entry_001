extends Node2D

const DEBUG_MODE : bool = true;

#---- SCREEN TRANSITION VARS  --------------------------------------------------
# these are here as a workaround for gdscript not having static vars

const SCREENWIPE_MAX_TICKS	: int = 80;

var screenwipe_anim_clock	: int;
var screenwipe_direction	: bool; # true for out, false for in
var screenwipe_active		: bool;
var screenwipe_next_scene;

#---- JOYSTICK VARS ------------------------------------------------------------

var use_joystick : bool = true;

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
			
	#else:
	#--- KEYBOARD --------------------------------------
	
	# if (Input.is_key_pressed(KEY_A)):
	#	if (Input.is_key_pressed(KEY_W)):
	#   if (Input.is_key_pressed(KEY_S)):
			
	return;

#-------------------------------------------------------------------------------

func _ready():
	
	# ready screen transition mechanism
	# for use
	screenwipe_direction 	= true;
	screenwipe_anim_clock	= 0;
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN);
	
	set_process(true);
	return;

#-------------------------------------------------------------------------------

func _process(_ignored):
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
	
#-------------------------------------------------------------------------------

func new_scene_screenwipe_start():
	if (screenwipe_active):
		return;

	screenwipe_active			= true;
	screenwipe_direction 	= false;
	screenwipe_anim_clock	= SCREENWIPE_MAX_TICKS;
	