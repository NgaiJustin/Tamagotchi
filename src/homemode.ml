open Animation
open Gui
open State
open Unix

let delta = 30

let default_anim_length = 300

let vs : viewstate = { default_vs with animations = [] }

type button =
  | Eat
  | Sleep
  | Toilet
  | Dolphin
  | Drum
  | Elementals

type avatar_anim =
  | Eating
  | Sleeping
  | Cleaning
  | Idle

type homestate = {
  (* 0 = Eat, 1 = Sleep, 2 = Toilet, 3 = Dolphin, 4 = Drum, 5 =
     Elementals *)
  mutable tam_state : tamagotchi;
  total_icons : int;
  mutable active_icon : int;
  mutable active_anim : avatar_anim;
  mutable anim_counter : int;
}

type game_flags = {
  mutable dolphin : bool;
  mutable drum : bool;
  mutable elements : bool;
}

let my_home =
  {
    tam_state = init_tam "./json/baby.json";
    total_icons = 6;
    active_icon = 0;
    anim_counter = 0;
    active_anim = Idle;
  }

let _ = ignore (State.set_cleanliness 10 my_home.tam_state)

(** [button_of_int] returns the corresponding button for the int *
    representation of [active_icon_num]

    Precondition: [active_icon_num] must be an integer between 0 and 5
    inclusive *)
let button_of_int (active_icon_num : int) =
  match active_icon_num with
  | 0 -> Eat
  | 1 -> Sleep
  | 2 -> Toilet
  | 3 -> Dolphin
  | 4 -> Drum
  | 5 -> Elementals
  | _ -> failwith "Impossible: Precondition violation"

let activate_button (active_button : button) =
  match active_button with
  | Eat ->
      my_home.active_anim <- Eating;
      my_home.anim_counter <- default_anim_length;
      ignore (State.increment_eat my_home.tam_state);
      ignore (State.decrement_happy my_home.tam_state)
  | Sleep ->
      my_home.active_anim <- Sleeping;
      my_home.anim_counter <- default_anim_length;
      ignore (State.increment_sleep my_home.tam_state);
      ignore (State.decrement_happy my_home.tam_state)
  | Toilet ->
      my_home.active_anim <- Cleaning;
      my_home.anim_counter <- default_anim_length;
      ignore (State.increment_cleanliness my_home.tam_state);
      ignore (State.decrement_happy my_home.tam_state)
  | Dolphin ->
      Dolphinview.draw ();
      ignore (State.set_happy 15 my_home.tam_state)
  | Drum ->
      Drumview.g.lifestage <- State.get_lifestage my_home.tam_state;
      Drumview.draw ();
      ignore (State.set_happy 15 my_home.tam_state)
  | Elementals ->
      Elementalsview.g.lifestage <-
        State.get_lifestage my_home.tam_state;
      Elementalsview.draw ();
      ignore (State.set_happy 15 my_home.tam_state)

let my_game_flags = { dolphin = false; drum = false; elements = false }

let reset_game_flags () =
  my_game_flags.dolphin <- false;
  my_game_flags.drum <- false;
  my_game_flags.elements <- false

let lifestage_to_anim
    (lifestage : string)
    baby_anim
    adult_anim
    elder_anim : Animation.animation =
  match lifestage with
  | "Baby" | "Teenager" -> baby_anim
  | "Adult" -> adult_anim
  | "Senior" -> elder_anim
  | _ -> adult_anim

let get_avatar_animations (hs : homestate) : Animation.animation =
  match hs.active_anim with
  | Eating ->
      lifestage_to_anim
        (State.get_lifestage hs.tam_state)
        eat_anim_baby eat_anim_adult eat_anim_elder
  | Sleeping ->
      lifestage_to_anim
        (State.get_lifestage hs.tam_state)
        sleep_anim_baby sleep_anim_adult sleep_anim_elder
  | Cleaning ->
      lifestage_to_anim
        (State.get_lifestage hs.tam_state)
        clean_anim_baby clean_anim_adult clean_anim_elder
  | Idle ->
      lifestage_to_anim
        (State.get_lifestage hs.tam_state)
        avatar_baby avatar_adult avatar_elder

let reset_avatar_animations (hs : homestate) =
  hs.active_anim <- Idle;
  hs.anim_counter <- 0

let eat_active =
  [
    eat_icon_bobble; sleep_icon_static; toilet_icon_static;
    dolphin_icon_static; drum_icon_static; elementals_icon_static;
  ]

let sleep_active =
  [
    eat_icon_static; sleep_icon_bobble; toilet_icon_static;
    dolphin_icon_static; drum_icon_static; elementals_icon_static;
  ]

let clean_active =
  [
    eat_icon_static; sleep_icon_static; toilet_icon_bobble;
    dolphin_icon_static; drum_icon_static; elementals_icon_static;
  ]

let dolphin_active =
  [
    eat_icon_static; sleep_icon_static; toilet_icon_static;
    dolphin_icon_bobble; drum_icon_static; elementals_icon_static;
  ]

let drum_active =
  [
    eat_icon_static; sleep_icon_static; toilet_icon_static;
    dolphin_icon_static; drum_icon_bobble; elementals_icon_static;
  ]

let elementals_active =
  [
    eat_icon_static; sleep_icon_static; toilet_icon_static;
    dolphin_icon_static; drum_icon_static; elementals_icon_bobble;
  ]

let get_toolbar_animations (hs : homestate) : Animation.animation list =
  match button_of_int hs.active_icon with
  | Eat -> eat_active
  | Sleep -> sleep_active
  | Toilet -> clean_active
  | Dolphin -> dolphin_active
  | Drum -> drum_active
  | Elementals -> elementals_active

let get_status_height (order : int) : int =
  let y_spacing = 8 and y_start = 35 and scale = 4 in
  (y_start + (y_spacing * order)) * scale

let draw_status_name () =
  draw_message 50 (get_status_height 4) 20 Graphics.black "Happy:";
  draw_message 50 (get_status_height 3) 20 Graphics.black "Sleep:";
  draw_message 50 (get_status_height 2) 20 Graphics.black "Clean:";
  draw_message 50 (get_status_height 1) 20 Graphics.black "Hunger:";
  draw_message 50 (get_status_height 0) 20 Graphics.black "Age:"

let draw_status_value
    (happy : string)
    (sleep : string)
    (cleanliness : string)
    (hunger : string)
    (age : string) =
  draw_message 120 (get_status_height 4) 25 Graphics.black happy;
  draw_message 120 (get_status_height 3) 25 Graphics.black sleep;
  draw_message 120 (get_status_height 2) 25 Graphics.black cleanliness;
  draw_message 120 (get_status_height 1) 25 Graphics.black hunger;
  draw_message 120 (get_status_height 0) 25 Graphics.black age

let get_status_animations (hs : homestate) : unit =
  let sleep = hs.tam_state |> get_sleep |> string_of_int
  and cleanliness = hs.tam_state |> get_cleanliness |> string_of_int
  and hunger = hs.tam_state |> get_hunger |> string_of_int
  and age = hs.tam_state |> get_age |> string_of_int
  and happy = hs.tam_state |> get_happy |> string_of_int in
  draw_status_name ();
  draw_status_value happy sleep cleanliness hunger age

let get_poop_animations (hs : homestate) : unit =
  let scaled_cleanliness = (hs.tam_state |> get_cleanliness) / 10 in
  let poop_count = 10 - scaled_cleanliness in
  for i = 1 to (poop_count / 4) + 1 do
    if i = (poop_count / 4) + 1 then
      for j = 1 to poop_count mod 4 do
        draw_img (120 - (10 * i)) (27 + (j * 10)) poop
      done
    else
      for j = 1 to 4 do
        draw_img (120 - (10 * i)) (27 + (j * 10)) poop
      done
  done

let get_animations (hs : homestate) : Animation.animation list =
  let tool_bar_anims = get_toolbar_animations hs
  and avatar_anim = get_avatar_animations hs in
  avatar_anim :: tool_bar_anims

(** Draw the tool bars, setup screen*)
let setup_toolbars s =
  (* Draw top and bottom black bars *)
  draw_pixels_ll 0 0 120 10 Graphics.black;
  draw_pixels_ll 0 110 120 10 Graphics.black;
  s.animations <- get_animations my_home

(** Main init function for HomeMode*)
let init s =
  (* Window has width s.scale * maxx and height s.scale * s.maxy *)
  Graphics.open_graph
    (" "
    ^ string_of_int (s.scale * s.maxx)
    ^ "x"
    ^ string_of_int (s.scale * s.maxy));
  Graphics.set_color s.bc;
  Graphics.fill_rect 0 0 (s.scale * s.maxx) (s.scale * s.maxy);
  setup_toolbars s

(** Main exit function for HomeMode *)
let exit s =
  Graphics.close_graph ();
  print_endline "";
  print_endline
    "Thanks for playing! Your Tamagotchi will be waiting for your \
     return";
  print_endline ""

(** Main exception function for HomeMode *)
let except s ex =
  match ex with
  | State.Death ->
      Graphics.clear_graph ();
      s.animations <- [];
      gameover_screen_no_score 500 "Oh no :("
        { tam_death with cx = vs.maxx / 2; cy = vs.maxy / 2 }
        s
  | _ -> ()

(** [key] processes the [c] character pressed and updates the state [s]
    accordingly *)
let key s c =
  (* draw_pixel s.x s.y s.scale s.fc; *)
  (match c with
  | '1' -> ignore (State.increment_age my_home.tam_state)
  | 'a' ->
      my_home.active_icon <-
        (my_home.active_icon - 1 + my_home.total_icons)
        mod my_home.total_icons
  | 'd' ->
      my_home.active_icon <-
        (my_home.active_icon + 1 + my_home.total_icons)
        mod my_home.total_icons
  | 's' -> my_home.active_icon |> button_of_int |> activate_button
  | 'x' -> raise End
  | _ -> ());
  s.animations <- get_animations my_home

let clear_center (state : viewstate) : unit =
  Graphics.set_color state.bc;
  Graphics.fill_rect 0 (10 * state.scale)
    (state.scale * state.maxx)
    (state.scale * (state.maxy - 20))

(** [step] increments the tick in the state, used for conservatively
    animating *)
let step (state : viewstate) : unit =
  (* Handle Avatar Animation (except idle) Transitions*)
  if my_home.active_anim != Idle then
    if my_home.anim_counter = 0 then (
      reset_avatar_animations my_home;
      state.animations <- get_animations my_home)
    else my_home.anim_counter <- my_home.anim_counter - 1;
  (* Update animations every [delta] frames *)
  if state.tick mod delta = 0 then
    state.animations <- increment_anims state.animations;
  if true then ignore (State.step my_home.tam_state);
  state.tick <- (state.tick + 1) mod delta

let predraw_setup (state : viewstate) =
  draw_pixels_ll 0 0 120 10 Graphics.black;
  draw_pixels_ll 0 110 120 10 Graphics.black;
  clear_center state

let predraw_helper (date : string) (time : string) =
  draw_message 75
    (default_vs.maxy * default_vs.scale * 42 / 60)
    25 Graphics.black date;
  draw_message 75
    (default_vs.maxy * default_vs.scale * 38 / 60)
    25 Graphics.black time

let predraw (state : viewstate) : unit =
  predraw_setup state;
  let {
    tm_sec = sec;
    tm_min = min;
    tm_hour = hour;
    tm_mday = mday;
    tm_mon = mon;
    tm_year = year;
  } =
    localtime (time ())
  in
  predraw_helper
    (Printf.sprintf "%04d-%02d-%02d" (year + 1900) (mon + 1) mday)
    (Printf.sprintf "%02d:%02d:%02d" hour min sec);
  if hour < 18 && hour > 6 then draw_img 100 80 sun
  else draw_img 100 80 moon;
  get_status_animations my_home;
  get_poop_animations my_home

let draw () = draw_loop vs init exit key except step predraw

(* For debugging. Uncomment the following line and run [make homemode] *)
(* TODO: Load from json (if it exists), otherwise launch new Tamagotchi
   session *)
(* let _ = draw () *)
