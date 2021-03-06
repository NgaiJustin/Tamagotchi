open Elementals
open Gui
open Animation
open Graphics

exception Gameover of int

type game_var = {
  mutable game : Elementals.gamestate;
  speed : int;
  row_scale : int;
  mutable lifestage : string;
}

let g =
  { game = init_game (); speed = 2; row_scale = 1; lifestage = "" }

let vs : viewstate = { default_vs with animations = [] }

let elementals_init s =
  Graphics.clear_graph ();
  g.game <- init_game ();
  s.animations <- [];
  draw_pixels (default_vs.maxx / 2) (default_vs.maxy / 2)
    default_vs.maxx default_vs.maxy Graphics.white

let elementals_exit s = ()

let draw_score (win : bool) =
  draw_pixels (default_vs.maxx / 2) (default_vs.maxy / 2)
    default_vs.maxx default_vs.maxy white;
  if win then
    draw_message
      (default_vs.maxx * default_vs.scale / 2)
      ((default_vs.maxy * default_vs.scale) - 40)
      50 black
      (string_of_int 2 ^ " - " ^ string_of_int (get_losses g.game))
  else (
    draw_pixels (default_vs.maxx / 2) (default_vs.maxy / 2)
      default_vs.maxx default_vs.maxy white;
    draw_message
      (default_vs.maxx * default_vs.scale / 2)
      ((default_vs.maxy * default_vs.scale) - 40)
      50 black
      (string_of_int (get_wins g.game) ^ " - " ^ string_of_int 2))

let elementals_except s ex =
  match ex with
  | Elementals.Gameover w_l ->
      draw_score w_l;
      if w_l then
        gameover_screen_no_score 500 "Congrats, you win!"
          { gg_static with cx = vs.maxx / 2; cy = vs.maxy / 2 }
          s
      else
        gameover_screen_no_score 500 "Boo, you lost!"
          { gg_static with cx = vs.maxx / 2; cy = vs.maxy / 2 }
          s
  | _ -> raise ex

let elementals_key s c =
  match c with
  | 'a' -> g.game <- play_water g.game
  | 's' -> g.game <- play_fire g.game
  | 'd' -> g.game <- play_leaf g.game
  | _ -> print_endline "Invalid Key_pressed"

let e_anims_helper
    (height : int)
    (lst_so_far : Animation.animation list)
    (anim : Animation.animation) : Animation.animation list =
  { anim with cx = height * g.row_scale; cy = default_vs.maxy / 2 }
  :: lst_so_far

let rec get_elems_anims
    (elements : (element * int) list)
    (lst_so_far : Animation.animation list) : Animation.animation list =
  match elements with
  | [] -> lst_so_far
  | (_, 100) :: t -> get_elems_anims t lst_so_far
  | (Water, height) :: t ->
      get_elems_anims t (e_anims_helper height lst_so_far water_anim)
  | (Fire, height) :: t ->
      get_elems_anims t (e_anims_helper height lst_so_far fireball_anim)
  | (Leaf, height) :: t ->
      get_elems_anims t (e_anims_helper height lst_so_far leaf_anim)
  | (Nothing, _) :: t -> get_elems_anims t lst_so_far

let robot_and_tamagotchi () =
  let anim =
    match g.lifestage with
    | "Baby" | "Teenager" -> shoot_baby_anim
    | "Adult" -> shoot_anim
    | "Senior" -> shoot_elder_anim
    | _ -> failwith "Impossible"
  in
  [
    { robot_anim with cx = 105; cy = default_vs.maxy / 2 };
    { anim with cx = 15; cy = default_vs.maxy / 2 };
  ]

let get_animations (game : Elementals.gamestate) :
    Animation.animation list =
  get_elems_anims
    [ get_ours g.game; get_opponent g.game ]
    (robot_and_tamagotchi ())

let elementals_step s =
  (* Step Game *)
  if s.tick mod g.speed = 0 then g.game <- next g.game;
  (* Update Animations *)
  if s.tick mod g.speed = 0 then s.animations <- get_animations g.game;
  s.tick <- (s.tick + 1) mod 4000

let elementals_predraw s =
  draw_pixels (default_vs.maxx / 2) (default_vs.maxy / 2)
    default_vs.maxx default_vs.maxy white;
  draw_message
    (default_vs.maxx * default_vs.scale / 2)
    ((default_vs.maxy * default_vs.scale) - 40)
    50 black
    (string_of_int (get_wins g.game)
    ^ " - "
    ^ string_of_int (get_losses g.game))

let draw () =
  draw_loop vs elementals_init elementals_exit elementals_key
    elementals_except elementals_step elementals_predraw
