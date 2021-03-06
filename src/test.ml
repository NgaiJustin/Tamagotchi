open OUnit2
open Homemode
open State

(* -------------------------------------------------------------------- *)
(* ---------------------------- Test Plan ----------------------------- *)
(* -------------------------------------------------------------------- *)
(* OUnit Testing vs. Manual Testing ------------------------------------
   Almost all our modules are comprised of pairs. There is a engine
   component that provides functionality of the simulation and there is
   a visual part that provides the information for the visual rendering
   on the GUI. We designed the engines — dolphin, drum, elementals,
   state - to be purely functional to ease the testing. Due to the
   functional and deterministic nature of the engines, it is natural to
   have them be OUnit tested. With the certainty that the engines are
   simulating things correctly, we know that our games/state updating
   will be working as intended. With the finicky nature of frontend
   programming, the modules that are responsible for the visual
   rendering mainly involve draw commands to the GUI which cannot be
   tested easily with OUnit. As such, we chose to manually test all
   these visual modules - dolphinview, drumview, elementalsview,
   homemode, gui, animation *)

(* How Test Cases were developed && Why This Testing Demonstrates
   Correctness of the System -----------------------------------------
   With reference to the lectures regarding testing, we designed out
   test cases through the lens of observers, mutators and generators.
   Ideally we would all combinations of observers with the mutators and
   generators, however, in our case some matchings did not make sense --
   for example in the dolphin.ml game engine, the process_middle
   function does have anything to do with any of the observers. Thus we
   ended up losening up on this requirement. Instead of testing every
   single possible combination, we simply structure our testing by
   observer. We designed a OUnit helper function and printer for each
   observer and wrote a suite of tests for each observer in each module.
   In these tests we tested all relevant mutators and generators. In the
   process of coming up with relevant combinations of the mutator and
   generator functions we first tested in a glassbox manner -- for ex.
   after changing a lane left, check if the lane is actually left, and
   repeat for all possible lane swaps. For observers that provided a
   more property based value -- for example num_rocks returns the total
   number of rocks -- we leveraged randomisation with our mutator
   functions to view the module's behaviour under stress. Like so, we
   ensure that our engine will behave as expected with any observer,
   mutator and generator functions. We believe that this demonstrates
   correctness since if we ensure that with all combinations of
   observer, mutator and generator functions, our module behaviours as
   we expect then we know that our game simulation will be sound. With
   the correctness of the engine certain, we simply need to focus on
   ensuring that we have a visual indication that corresponds to what is
   being simulated in the engine. Since the aesthetics of visual
   elements are subjective, the "correctness" of the visual component is
   much more flexible. But after many nights of tweaks and fixes, we are
   very proud of how it looks. We hope you enjoy play with our
   Tamagotchi! *)

(* -------------------------------------------------------------------- *)
(* -------------------------- State Testing --------------------------- *)
(* -------------------------------------------------------------------- *)
(*[piano] is a record representing the piano item*)
let piano = { name = "piano"; cost = 10 }

(*[violin] is a record representing the violin item*)
let violin = { name = "violin"; cost = 5 }

(*[num_printer num] returns the string representing numberic values of a
  Tamagotchi's state*)
let state_num_printer num : string = string_of_int num

(*[string_printer str] returns the string representing string values of
  a Tamagotchi's state*)
let state_string_printer str : string = str

(*[str_feature_test name a b] constructs an OUnit test named [name] that
  checks if [a] is equal to [b] and uses a custom [state_string_printer]*)
let str_feature_test name a b =
  name >:: fun ctxt -> assert_equal a b ~printer:state_string_printer

(*[num_feature_test name a b] constructs an OUnit test named [name] that
  checks if [a] is equal to [b] and uses a custom [state_num_printer]*)
let num_feature_test name a b =
  name >:: fun ctxt -> assert_equal a b ~printer:state_num_printer

(*[equal_sets_test name a b] constructs an OUnit test named [name] that
  checks if [a] is equal to [b] to be used on lists.*)
let equal_sets_test name a b = name >:: fun ctxt -> assert_equal a b

(*[death_exc name fxn] constructs an OUnit test named [name] that checks
  if [fxn] will raise [Death] exception.*)
let death_exc name fxn = name >:: fun ctxt -> assert_raises Death fxn

(*[negative_money_exc name fxn] constructs an OUnit test named [name]
  that checks if [fxn] will raise [NegativeMoney] exception.*)
let negative_money_exc name fxn =
  name >:: fun ctxt -> assert_raises NegativeMoney fxn

(* [repeated_step n tam] returns the result of applying the State.step
   function on [tam] [n] times. *)
let rec repeated_step n tam =
  if n = 0 then tam else repeated_step (n - 1) (step tam)

let state_tests =
  [
    (* ----------------- Observer: get_breed ------------------- *)
    str_feature_test "breed of baby" "crazy"
      (init_tam "./json/baby.json" |> get_breed);
    str_feature_test "breed of teen" "fluffy"
      (init_tam "./json/teen.json" |> get_breed);
    str_feature_test "breed of senior" "bald"
      (init_tam "./json/senior.json" |> get_breed);
    (* ---------------- Observer: get_lifestage ------------------ *)
    (* ----------------------- No Change ------------------------- *)
    str_feature_test "Lifestage of baby" "Baby"
      (init_tam "./json/baby.json" |> get_lifestage);
    str_feature_test "Lifestage of teen" "Teenager"
      (init_tam "./json/teen.json" |> get_lifestage);
    str_feature_test "Lifestage of senior" "Senior"
      (init_tam "./json/senior.json" |> get_lifestage);
    (* --------------------- Increment Age ---------------------- *)
    str_feature_test "Lifestage of baby incr 1" "Baby"
      (init_tam "./json/baby.json" |> increment_age |> get_lifestage);
    str_feature_test "Lifestage of teen incr 1" "Adult"
      (init_tam "./json/teen.json" |> increment_age |> get_lifestage);
    str_feature_test "Lifestage of senior incr 1" "Senior"
      (init_tam "./json/senior.json" |> increment_age |> get_lifestage);
    (* --------------------------- Step ---------------------------- *)
    str_feature_test "Lifestage of baby incr 2" "Teenager"
      (init_tam "./json/baby.json" |> repeated_step 729 |> get_lifestage);
    str_feature_test "Lifestage of teen incr 2" "Adult"
      (init_tam "./json/teen.json" |> repeated_step 729 |> get_lifestage);
    death_exc "Lifestage of senior incr 2" (fun () ->
        init_tam "./json/senior.json" |> repeated_step 729);
    (* -------------------- Observer: get_sleep ---------------------- *)
    (* ------------------------ No Change ------------------------- *)
    num_feature_test "sleep of baby" 100
      (init_tam "./json/baby.json" |> get_sleep);
    num_feature_test "sleep of teen" 45
      (init_tam "./json/teen.json" |> get_sleep);
    num_feature_test "sleep of senior" 90
      (init_tam "./json/senior.json" |> get_sleep);
    (* ---------------------- Set Sleep ----------------------- *)
    num_feature_test "sleep of baby -20" 80
      (init_tam "./json/baby.json" |> set_sleep (-20) |> get_sleep);
    num_feature_test "sleep of teen -20" 25
      (init_tam "./json/teen.json" |> set_sleep (-20) |> get_sleep);
    num_feature_test "sleep of senior -20" 70
      (init_tam "./json/senior.json" |> set_sleep (-20) |> get_sleep);
    death_exc "death sleep of baby" (fun () ->
        init_tam "./json/baby.json" |> set_sleep (-100));
    num_feature_test "negative edge case sleep of teen" 1
      (init_tam "./json/teen.json" |> set_sleep (-44) |> get_sleep);
    num_feature_test "positive edge case sleep of senior" 100
      (init_tam "./json/senior.json" |> set_sleep 10 |> get_sleep);
    num_feature_test "over 100 sleep of senior" 100
      (init_tam "./json/senior.json" |> set_sleep 300 |> get_sleep);
    (* ----------------------- Increment Sleep ------------------------ *)
    num_feature_test "increment sleep of baby" 100
      (init_tam "./json/baby.json" |> increment_sleep |> get_sleep);
    num_feature_test "increment sleep of teen" 50
      (init_tam "./json/teen.json" |> increment_sleep |> get_sleep);
    num_feature_test "increment sleep of senior" 95
      (init_tam "./json/senior.json" |> increment_sleep |> get_sleep);
    (* ---------------------------- Step ----------------------------- *)
    num_feature_test "step sleep of baby" 90
      (init_tam "./json/baby.json" |> repeated_step 364 |> get_sleep);
    num_feature_test "step sleep of teen" 35
      (init_tam "./json/teen.json" |> repeated_step 364 |> get_sleep);
    num_feature_test "step sleep of senior" 80
      (init_tam "./json/senior.json" |> repeated_step 364 |> get_sleep);
    (* ------------------ Observer: get_cleanliness -------------------- *)
    (* ------------------------ No Change ------------------------- *)
    num_feature_test "clean of baby" 100
      (init_tam "./json/baby.json" |> get_cleanliness);
    num_feature_test "clean of teen" 87
      (init_tam "./json/teen.json" |> get_cleanliness);
    num_feature_test "clean of senior" 70
      (init_tam "./json/senior.json" |> get_cleanliness);
    (* ---------------------- Set Cleanliness ----------------------- *)
    num_feature_test "clean of baby -20" 80
      (init_tam "./json/baby.json"
      |> set_cleanliness (-20) |> get_cleanliness);
    num_feature_test "clean of teen -20" 67
      (init_tam "./json/teen.json"
      |> set_cleanliness (-20) |> get_cleanliness);
    num_feature_test "clean of senior -20" 50
      (init_tam "./json/senior.json"
      |> set_cleanliness (-20) |> get_cleanliness);
    death_exc "death clean of teen" (fun () ->
        init_tam "./json/teen.json" |> set_cleanliness (-87));
    num_feature_test "negative edge case clean of baby" 1
      (init_tam "./json/baby.json"
      |> set_cleanliness (-99) |> get_cleanliness);
    num_feature_test "positive edge case clean of teen" 100
      (init_tam "./json/teen.json"
      |> set_cleanliness 13 |> get_cleanliness);
    num_feature_test "over 100 clean of senior" 100
      (init_tam "./json/senior.json"
      |> set_cleanliness 300 |> get_cleanliness);
    (* -------------------- Increment Cleanliness --------------------- *)
    num_feature_test "increment clean of baby" 100
      (init_tam "./json/baby.json"
      |> increment_cleanliness |> get_cleanliness);
    num_feature_test "increment clean of teen" 92
      (init_tam "./json/teen.json"
      |> increment_cleanliness |> get_cleanliness);
    num_feature_test "increment clean of senior" 75
      (init_tam "./json/senior.json"
      |> increment_cleanliness |> get_cleanliness);
    (* ---------------------------- Step ----------------------------- *)
    num_feature_test "step clean of baby" 90
      (init_tam "./json/baby.json"
      |> repeated_step 460 |> get_cleanliness);
    num_feature_test "step clean of teen" 77
      (init_tam "./json/teen.json"
      |> repeated_step 460 |> get_cleanliness);
    num_feature_test "step clean of senior" 60
      (init_tam "./json/senior.json"
      |> repeated_step 460 |> get_cleanliness);
    (* ------------------ Observer: get_hunger -------------------- *)
    (* ------------------------ No Change ------------------------- *)
    num_feature_test "hunger of baby" 100
      (init_tam "./json/baby.json" |> get_hunger);
    num_feature_test "hunger of teen" 28
      (init_tam "./json/teen.json" |> get_hunger);
    num_feature_test "hunger of senior" 83
      (init_tam "./json/senior.json" |> get_hunger);
    (* ---------------------- Set Hunger ----------------------- *)
    num_feature_test "hunger of baby -20" 80
      (init_tam "./json/baby.json" |> set_hunger (-20) |> get_hunger);
    num_feature_test "hunger of teen -20" 8
      (init_tam "./json/teen.json" |> set_hunger (-20) |> get_hunger);
    num_feature_test "hunger of senior -20" 63
      (init_tam "./json/senior.json" |> set_hunger (-20) |> get_hunger);
    death_exc "death hunger of senior" (fun () ->
        init_tam "./json/senior.json" |> set_hunger (-550));
    num_feature_test "negative edge case hunger of teen" 1
      (init_tam "./json/teen.json" |> set_hunger (-27) |> get_hunger);
    num_feature_test "positive edge case hunger of baby" 100
      (init_tam "./json/baby.json" |> set_hunger 0 |> get_hunger);
    num_feature_test "over 100 hunger of senior" 100
      (init_tam "./json/senior.json" |> set_hunger 18 |> get_hunger);
    (* ---------------------- Increment Hunger ----------------------- *)
    num_feature_test "increment hunger of baby" 100
      (init_tam "./json/baby.json" |> increment_eat |> get_hunger);
    num_feature_test "increment hunger of teen" 33
      (init_tam "./json/teen.json" |> increment_eat |> get_hunger);
    num_feature_test "increment hunger of senior" 88
      (init_tam "./json/senior.json" |> increment_eat |> get_hunger);
    (* ---------------------------- Step ----------------------------- *)
    num_feature_test "step hunger of baby" 80
      (init_tam "./json/baby.json" |> repeated_step 740 |> get_hunger);
    num_feature_test "step hunger of teen" 8
      (init_tam "./json/teen.json" |> repeated_step 740 |> get_hunger);
    num_feature_test "step hunger of senior" 73
      (init_tam "./json/senior.json" |> repeated_step 365 |> get_hunger);
    (* ------------------ Observer: get_happy -------------------- *)
    (* ------------------------ No Change ------------------------- *)
    num_feature_test "happy of baby" 100
      (init_tam "./json/baby.json" |> get_happy);
    num_feature_test "happy of teen" 42
      (init_tam "./json/teen.json" |> get_happy);
    num_feature_test "happy of senior" 93
      (init_tam "./json/senior.json" |> get_happy);
    (* ---------------------- Set Happy ----------------------- *)
    num_feature_test "happy of baby -20" 80
      (init_tam "./json/baby.json" |> set_happy (-20) |> get_happy);
    num_feature_test "happy of teen -20" 22
      (init_tam "./json/teen.json" |> set_happy (-20) |> get_happy);
    num_feature_test "happy of senior -20" 73
      (init_tam "./json/senior.json" |> set_happy (-20) |> get_happy);
    death_exc "death happy of baby" (fun () ->
        init_tam "./json/baby.json" |> set_happy (-100));
    num_feature_test "negative edge case happy of senior" 1
      (init_tam "./json/senior.json" |> set_happy (-92) |> get_happy);
    num_feature_test "positive edge case happy of teen" 100
      (init_tam "./json/teen.json" |> set_happy 58 |> get_happy);
    num_feature_test "over 100 happy of senior" 100
      (init_tam "./json/senior.json" |> set_happy 100 |> get_happy);
    (* ---------------------- Increment Happy ----------------------- *)
    num_feature_test "increment happy of baby" 100
      (init_tam "./json/baby.json" |> increment_happy |> get_happy);
    num_feature_test "increment happy of teen" 47
      (init_tam "./json/teen.json" |> increment_happy |> get_happy);
    num_feature_test "increment happy of senior" 98
      (init_tam "./json/senior.json" |> increment_happy |> get_happy);
    (* ---------------------- Decrement Happy ----------------------- *)
    num_feature_test "increment happy of baby" 95
      (init_tam "./json/baby.json" |> decrement_happy |> get_happy);
    num_feature_test "increment happy of teen" 37
      (init_tam "./json/teen.json" |> decrement_happy |> get_happy);
    num_feature_test "increment happy of senior" 88
      (init_tam "./json/senior.json" |> decrement_happy |> get_happy);
    (* ---------------------------- Step ----------------------------- *)
    num_feature_test "step happy of baby" 90
      (init_tam "./json/baby.json" |> repeated_step 364 |> get_happy);
    num_feature_test "step happy of teen" 32
      (init_tam "./json/teen.json" |> repeated_step 364 |> get_happy);
    num_feature_test "step happy of senior" 83
      (init_tam "./json/senior.json" |> repeated_step 364 |> get_happy);
    (* ------------------ Observer: get_age -------------------- *)
    (* ------------------------ No Change ------------------------- *)
    num_feature_test "age of baby" 4
      (init_tam "./json/baby.json" |> get_age);
    num_feature_test "age of teen" 10
      (init_tam "./json/teen.json" |> get_age);
    num_feature_test "age of senior" 34
      (init_tam "./json/senior.json" |> get_age);
    (* ------------------------ Increment Age ------------------------- *)
    num_feature_test "increment age of baby 3" 7
      (init_tam "./json/baby.json"
      |> increment_age |> increment_age |> increment_age |> get_age);
    num_feature_test "increment age of teen 2" 12
      (init_tam "./json/teen.json"
      |> increment_age |> increment_age |> get_age);
    num_feature_test "increment age of senior 1" 35
      (init_tam "./json/senior.json" |> increment_age |> get_age);
    (* ---------------------------- Step ----------------------------- *)
    num_feature_test "step age of baby" 6
      (init_tam "./json/baby.json" |> repeated_step 740 |> get_age);
    num_feature_test "step age of teen" 11
      (init_tam "./json/teen.json" |> repeated_step 364 |> get_age);
    num_feature_test "step age of senior" 34
      (init_tam "./json/senior.json" |> repeated_step 363 |> get_age);
    (* ------------------ Observer: get_money -------------------- *)
    (* ------------------------ No Change ------------------------- *)
    num_feature_test "money of baby" 0
      (init_tam "./json/baby.json" |> get_money);
    num_feature_test "money of teen" 10
      (init_tam "./json/teen.json" |> get_money);
    num_feature_test "money of senior" 10
      (init_tam "./json/senior.json" |> get_money);
    (* ------------------------ Set Money ------------------------- *)
    num_feature_test "set money of baby 10" 10
      (init_tam "./json/baby.json" |> set_money 10 |> get_money);
    num_feature_test "set money of teen -10" 0
      (init_tam "./json/teen.json" |> set_money (-10) |> get_money);
    negative_money_exc "senior in debt" (fun () ->
        init_tam "./json/senior.json" |> set_money (-11));
    (* ------------------ Observer: get_inventory -------------------- *)
    (* ------------------------ No Change ------------------------- *)
    equal_sets_test "inventory of baby" []
      (init_tam "./json/baby.json" |> get_inventory);
    equal_sets_test "inventory of teen" [ piano ]
      (init_tam "./json/teen.json" |> get_inventory);
    equal_sets_test "inventory of senior" [ piano ]
      (init_tam "./json/senior.json" |> get_inventory);
    (* ------------------------ Set Item ------------------------- *)
    equal_sets_test "add piano to baby" [ piano ]
      (init_tam "./json/baby.json" |> set_item piano |> get_inventory);
    equal_sets_test "add piano to teen" [ piano; piano ]
      (init_tam "./json/teen.json" |> set_item piano |> get_inventory);
    equal_sets_test "add violin to senior" [ violin; piano ]
      (init_tam "./json/senior.json" |> set_item violin |> get_inventory);
  ]

(* -------------------------------------------------------------------- *)
(* -------------------------- Dolphin Testing ------------------------- *)
(* -------------------------------------------------------------------- *)

(** [lane_printer lane] returns a string representing [lane] *)
let lane_printer (lane : Dolphin.lane) : string =
  match lane with
  | Left -> "Left"
  | Middle -> "Middle"
  | Right -> "Right"

(** [rock_printer rocks] returns a string representing [rocks] *)
let rock_printer (rocks : (int * int) list) : string =
  let str_list =
    List.map
      (fun (lane, height) ->
        "(" ^ string_of_int lane ^ ", " ^ string_of_int height ^ ") ")
      rocks
  in
  List.fold_left ( ^ ) "( " str_list ^ ")"

(** [num_rocks_printer num_rocks] returns a string representing
    [num_rocks] *)
let num_rocks_printer num_rocks : string = string_of_int num_rocks

(** [dolphin_lane_test name actual_value expected_output] constructs an
    OUnit test named [name] that checks if [expected_output] is equal to
    [actual_value] and uses a custom [lane_printer] *)
let dolphin_lane_test (name : string) actual_value expected_out : test =
  name >:: fun _ ->
  assert_equal expected_out actual_value ~printer:lane_printer

(** [dolphin_rock_test_w_seed name gamestate_func expected_output]
    constructs an OUnit test named [name] that checks if
    [expected_output] is equal to [gamestate_func] applied on a freshly
    initialized Dolphin.gamestate and uses a custom [rock_printer]

    Note that gamestate_func allows for delayed application of the
    Dolphin.add_rock functions. The purpose of this is to allow the seed
    to be set before the add_rock methods (which involve randomness) to
    allow for testing*)
let dolphin_rock_test_w_seed
    ?(seed = 1)
    (name : string)
    gamestate_func
    expected_out : test =
  Random.init 1;
  name >:: fun _ ->
  assert_equal expected_out
    (Dolphin.init_game () |> gamestate_func)
    ~printer:rock_printer

(** [dolphin_num_rock_test name actual_value expected_output] constructs
    an OUnit test named [name] that checks if [expected_output] is equal
    to [actual_value] and uses a custom [num_rocks_printer] *)
let dolphin_num_rock_test (name : string) actual_value expected_out :
    test =
  name >:: fun _ ->
  assert_equal expected_out actual_value ~printer:num_rocks_printer

(** [dolphin_repeated_next n gamestate] returns the result of applying
    the Dolphin.next function on [gamestate] [n] time *)
let rec dolphin_repeated_next (n : int) (gamestate : Dolphin.gamestate)
    : Dolphin.gamestate =
  if n = 0 then gamestate
  else dolphin_repeated_next (n - 1) (gamestate |> Dolphin.next)

let dolphin_test =
  let open Dolphin in
  [
    (* ----------------- Observer: get_dolphin_lane ------------------- *)
    (* -------------------------- One --------------------------- *)
    dolphin_lane_test "Middle to Right"
      (init_game () |> process_right |> get_dolphin_lane)
      Right;
    dolphin_lane_test "Middle to Left"
      (init_game () |> process_left |> get_dolphin_lane)
      Left;
    (* -------------------------- Two --------------------------- *)
    dolphin_lane_test "Middle |> Right |> Right"
      (init_game () |> process_right |> process_right
     |> get_dolphin_lane)
      Right;
    dolphin_lane_test "Middle |> Left |> Left"
      (init_game () |> process_left |> process_left |> get_dolphin_lane)
      Left;
    dolphin_lane_test "Middle |> Right |> Left"
      (init_game () |> process_right |> process_left |> get_dolphin_lane)
      Middle;
    dolphin_lane_test "Middle |> Left |> Right"
      (init_game () |> process_left |> process_right |> get_dolphin_lane)
      Middle;
    (* ------------------------- Three -------------------------- *)
    dolphin_lane_test "Middle |> Right |> Right |> Right"
      (init_game () |> process_right |> process_right |> process_right
     |> get_dolphin_lane)
      Right;
    dolphin_lane_test "Middle |> Right |> Right |> Left"
      (init_game () |> process_right |> process_right |> process_left
     |> get_dolphin_lane)
      Middle;
    dolphin_lane_test "Middle |> Right |> Left |> Right"
      (init_game () |> process_right |> process_left |> process_right
     |> get_dolphin_lane)
      Right;
    dolphin_lane_test "Middle |> Left |> Right |> Right"
      (init_game () |> process_left |> process_right |> process_right
     |> get_dolphin_lane)
      Right;
    dolphin_lane_test "Middle |> Left |> Left |> Right"
      (init_game () |> process_left |> process_left |> process_right
     |> get_dolphin_lane)
      Middle;
    dolphin_lane_test "Middle |> Left |> Right |> Left"
      (init_game () |> process_left |> process_right |> process_left
     |> get_dolphin_lane)
      Left;
    dolphin_lane_test "Middle |> Right |> Left |> Left"
      (init_game () |> process_right |> process_left |> process_left
     |> get_dolphin_lane)
      Left;
    dolphin_lane_test "Middle |> Left |> Left |> Left"
      (init_game () |> process_left |> process_left |> process_left
     |> get_dolphin_lane)
      Left;
    (* --------------------- Observer: get_rocks ---------------------- *)
    (* Seed default is set to 1 - values are: 1, 2, 0, 0, 2, 2, 2, 0, 0,
       0, 2 *)
    (* The application of the gamestate functions are delayed since the
       seed needs to be reset each time the [dolphin_rock_test_w_seed]
       function is called *)
    dolphin_rock_test_w_seed "Adding one rock - middle lane"
      (fun gs -> gs |> add_rock |> next |> get_rocks)
      [ (1, 60) ];
    dolphin_rock_test_w_seed "Adding two rock - left, right lanes"
      (fun gs -> gs |> add_rock |> add_rock |> next |> get_rocks)
      [ (0, 60); (2, 60) ];
    dolphin_rock_test_w_seed "Add rock |> next |> add 2 rocks"
      (fun gs ->
        gs |> add_rock |> next |> add_rock |> add_rock |> next
        |> get_rocks)
      [ (2, 60); (2, 60); (0, 59) ];
    dolphin_rock_test_w_seed
      "Repeat (Add rock |> next) three times then add one last rock"
      (fun gs ->
        gs |> add_rock |> next |> add_rock |> next |> add_rock |> next
        |> add_rock |> next |> get_rocks)
      [ (0, 60); (0, 59); (0, 58); (2, 57) ];
    dolphin_rock_test_w_seed
      "Repeat (Add rock |> next) three times then add one last rock"
      (fun gs ->
        gs |> add_rock |> next |> add_rock |> next |> add_rock |> next
        |> add_rock |> next |> get_rocks)
      [ (0, 60); (1, 59); (2, 58); (2, 57) ];
    dolphin_rock_test_w_seed "Add one rock and fall to bottom"
      (fun gs ->
        gs |> add_rock |> dolphin_repeated_next 52 |> get_rocks)
      [ (1, 9) ];
    (* --------------------- Observer: num_rocks ---------------------- *)
    dolphin_num_rock_test "Adding one rock "
      (init_game () |> add_rock |> num_rocks)
      1;
    dolphin_num_rock_test "Adding two rock "
      (init_game () |> add_rock |> add_rock |> num_rocks)
      2;
    dolphin_num_rock_test "Adding three rocks "
      (init_game () |> add_rock |> add_rock |> add_rock |> num_rocks)
      3;
  ]

(* -------------------------------------------------------------------- *)
(* --------------------------- Drum Testing --------------------------- *)
(* -------------------------------------------------------------------- *)

(** [color_printer color] returns a string representing [color] *)
let color_printer (color : Drum.color) : string =
  match color with Don -> "Don" | Ka -> "Ka"

(** [beat_printer beat] returns a string representing [beat] *)
let beat_printer (beat : Drum.beat) : string =
  match beat with
  | Right _ -> "Right"
  | Idle -> "Idle"
  | Left _ -> "Left"

(** [beats_printer beats] returns a string representing [beats] *)
let beats_printer (beats : (int * Drum.color) list) : string =
  let str_list =
    List.map
      (fun (height, c) ->
        "(" ^ string_of_int height ^ ", " ^ color_printer c ^ ") ")
      beats
  in
  List.fold_left ( ^ ) "( " str_list ^ ")"

(** [num_beats_printer num_rocks] returns a string representing
    [num_beats] *)
let num_beats_printer num_beats : string = string_of_int num_beats

(** [drum_combo_printer num_rocks] returns a string representing [combo] *)
let drum_combo_printer combo : string = string_of_int combo

(** [drum_score_printer num_rocks] returns a string representing [score] *)
let drum_score_printer score : string = string_of_int score

(** [drum_color_test name actual_value expected_output] constructs an
    OUnit test named [name] that checks if [expected_output] is equal to
    [actual_value] and uses a custom [color_printer] *)
let drum_color_test (name : string) actual_value expected_out : test =
  name >:: fun _ ->
  assert_equal expected_out actual_value ~printer:color_printer

(** [drum_beat_test name actual_value expected_output] constructs an
    OUnit test named [name] that checks if [expected_output] is equal to
    [actual_value] and uses a custom [beat_printer] *)
let drum_beat_test (name : string) actual_value expected_out : test =
  name >:: fun _ ->
  assert_equal expected_out actual_value ~printer:beat_printer

(** [drum_beats_test_w_seed name gamestate_func expected_output]
    constructs an OUnit test named [name] that checks if
    [expected_output] is equal to [gamestate_func] applied on a freshly
    initialized Dolphin.gamestate and uses a custom [beats_printer]

    Note that gamestate_func allows for delayed application of the
    Drum.add_beat functions. The purpose of this is to allow the seed to
    be set before the add_beat methods (which involve randomness) to
    allow for testing*)
let drum_beats_test_w_seed
    ?(seed = 1)
    (name : string)
    gamestate_func
    expected_out : test =
  Random.init 1;
  name >:: fun _ ->
  assert_equal expected_out
    (Drum.init_game () |> gamestate_func)
    ~printer:beats_printer

(** [beats_num_beat_test name actual_value expected_output] constructs
    an OUnit test named [name] that checks if [expected_output] is equal
    to [actual_value] and uses a custom [num_beats_printer] *)
let beats_num_beat_test (name : string) actual_value expected_out : test
    =
  name >:: fun _ ->
  assert_equal expected_out actual_value ~printer:num_beats_printer

(** [drum_combo_test name actual_value expected_output] constructs an
    OUnit test named [name] that checks if [expected_output] is equal to
    [actual_value] and uses a custom [num_beats_printer] *)
let drum_combo_test (name : string) actual_value expected_out : test =
  name >:: fun _ ->
  assert_equal expected_out actual_value ~printer:drum_combo_printer

(** [drum_score_test name actual_value expected_output] constructs an
    OUnit test named [name] that checks if [expected_output] is equal to
    [actual_value] and uses a custom [num_beats_printer] *)
let drum_score_test (name : string) actual_value expected_out : test =
  name >:: fun _ ->
  assert_equal expected_out actual_value ~printer:drum_score_printer

(** [drum_repeated_next n gamestate] returns the result of applying the
    Drum.next function on [gamestate] [n] time *)
let rec drum_repeated_next (n : int) (gamestate : Drum.gamestate) :
    Drum.gamestate =
  if n = 0 then gamestate
  else drum_repeated_next (n - 1) (gamestate |> Drum.next)

let drum_test =
  let open Drum in
  [
    (* ----------------- Observer: get_beat_type ------------------- *)
    drum_beat_test "Beat type upon hitting right button"
      (init_game () |> process_right |> get_beat_type)
      (Right 50);
    drum_beat_test
      "Beat type upon hitting right button and waiting a frame"
      (init_game () |> process_right |> drum_repeated_next 1
     |> get_beat_type)
      (Right 49);
    drum_beat_test
      "Beat type upon hitting right button and waiting 51 frames"
      (init_game () |> process_right |> drum_repeated_next 51
     |> get_beat_type)
      Idle;
    drum_beat_test "Beat type upon hitting left button"
      (init_game () |> process_left |> get_beat_type)
      (Left 50);
    drum_beat_test
      "Beat type upon hitting left button and waiting a frame"
      (init_game () |> process_left |> drum_repeated_next 1
     |> get_beat_type)
      (Left 49);
    drum_beat_test
      "Beat type upon hitting left button and waiting 51 frames"
      (init_game () |> process_left |> drum_repeated_next 51
     |> get_beat_type)
      Idle;
    drum_beat_test "Beat type upon pressing nothing"
      (init_game () |> get_beat_type)
      Idle;
    drum_beat_test "Beat type upon pressing middle button"
      (init_game () |> get_beat_type)
      Idle;
    drum_color_test "Check if adding Don has color Don"
      (init_game () |> add_don |> get_beats |> List.hd |> snd)
      Don;
    drum_color_test "Check if adding Ka has color Ka"
      (init_game () |> add_ka |> get_beats |> List.hd |> snd)
      Ka;
    (* --------------------- Observer: get_beats ---------------------- *)
    (* Seed default is set to 1 - values are: 1, 2, 0, 0, 2, 2, 2, 0, 0,
       0, 2 *)
    (* The application of the gamestate functions are delayed since the
       seed needs to be reset each time the [drum_beats_test_w_seed]
       function is called *)
    drum_beats_test_w_seed "Adding one beat set - single Don"
      (fun gs -> gs |> add_beat |> next |> get_beats)
      [ (120, Don) ];
    drum_beats_test_w_seed
      "Adding two beat sets - Ka Ka, and Don Don Don"
      (fun gs -> gs |> add_beat |> add_beat |> next |> get_beats)
      [ (120, Ka); (140, Ka); (120, Don); (135, Don); (150, Don) ];
    drum_beats_test_w_seed "Add beat set |> next |> add 2 beat sets"
      (fun gs ->
        gs |> add_beat |> next |> add_beat |> add_beat |> next
        |> get_beats)
      [
        (119, Ka); (134, Ka); (149, Ka); (120, Don); (135, Ka);
        (150, Don); (120, Don); (140, Don);
      ];
    drum_beats_test_w_seed
      "Repeat (Add beat set |> next) three times then add one last \
       beat set"
      (fun gs ->
        gs |> add_beat |> next |> add_beat |> next |> add_beat |> next
        |> add_beat |> next |> get_beats)
      [
        (117, Ka); (137, Ka); (118, Ka); (138, Ka); (119, Ka);
        (134, Ka); (149, Ka); (120, Ka); (140, Ka);
      ];
    drum_beats_test_w_seed
      "Repeat (Add beat set |> next) three times then add one last \
       beat set"
      (fun gs ->
        gs |> add_beat |> next |> add_beat |> next |> add_beat |> next
        |> add_beat |> next |> get_beats)
      [
        (117, Ka); (132, Ka); (147, Ka); (118, Ka); (133, Ka);
        (148, Ka); (119, Ka); (139, Ka); (120, Don);
      ];
    drum_beats_test_w_seed "Add one beat set and fall to bottom"
      (fun gs -> gs |> add_beat |> drum_repeated_next 52 |> get_beats)
      [ (69, Ka); (89, Ka) ];
    (* --------------------- Observer: get_num_beats
       ---------------------- *)
    beats_num_beat_test "Adding one beat set "
      (init_game () |> add_don |> get_num_beats)
      10;
    beats_num_beat_test "Adding two beat sets "
      (init_game () |> add_don |> add_don |> get_num_beats)
      9;
    beats_num_beat_test "Adding three beat sets "
      (init_game () |> add_don |> add_don |> add_don |> get_num_beats)
      8;
  ]

(* -------------------------------------------------------------------- *)
(* ----------------------- Elementalist Testing ----------------------- *)
(* -------------------------------------------------------------------- *)

(*[our_opponent_printer player] returns the string representing the
  current element [player] played and the current position of the
  [player] animation.*)
let our_opponent_printer (player : Elementals.element * int) =
  match fst player with
  | Fire -> "Fire, " ^ string_of_int (snd player)
  | Water -> "Water, " ^ string_of_int (snd player)
  | Leaf -> "Leaf, " ^ string_of_int (snd player)
  | Nothing -> "Nothing, " ^ string_of_int (snd player)

(*[win_loss_printer win_loss] returns the string the number of wins or
  losses the player has.*)
let win_loss_printer (win_loss : int) = string_of_int win_loss

(*[currently_animated_printed currently_animated] returns the string
  representing the boolean [currently_animated].*)
let currently_animated_printer (currently_animated : bool) =
  string_of_bool currently_animated

(** [our_opponent_test name gamestate_func expected_out] constructs an
    OUnit test named [name] that checks if [expected_out] is equal to
    [gamestate_func] applied on () and uses a custom
    [our_opponent_printer]

    Note that gamestate_func allows for delayed application of the
    Elementals.init_game and Elementals.win_loss functions. The purpose
    of this is to allow the seed to be set before the init_game and
    win_loss methods (which involve randomness) to allow for testing*)
let our_opponent_test
    ?(seed = 1)
    (name : string)
    gamestate_func
    expected_out : test =
  Random.init 1;
  name >:: fun _ ->
  assert_equal expected_out (() |> gamestate_func)
    ~printer:our_opponent_printer

(** [win_loss_test name gamestate_func expected_out] constructs an OUnit
    test named [name] that checks if [expected_out] is equal to
    [gamestate_func] applied on () and uses a custom [win_loss_printer]

    Note that gamestate_func allows for delayed application of the
    Elementals.init_game and Elementals.win_loss functions. The purpose
    of this is to allow the seed to be set before the init_game and
    win_loss methods (which involve randomness) to allow for testing*)
let win_loss_test
    ?(seed = 1)
    (name : string)
    gamestate_func
    expected_out : test =
  Random.init 1;
  name >:: fun _ ->
  assert_equal expected_out (() |> gamestate_func)
    ~printer:win_loss_printer

(** [currently_animated_test name gamestate_func expected_out]
    constructs an OUnit test named [name] that checks if [expected_out]
    is equal to [gamestate_func] applied on () and uses a custom
    [currently_animated_printer]

    Note that gamestate_func allows for delayed application of the
    Elementals.init_game and Elementals.win_loss functions. The purpose
    of this is to allow the seed to be set before the init_game and
    win_loss methods (which involve randomness) to allow for testing*)
let currently_animated_test
    ?(seed = 1)
    (name : string)
    gamestate_func
    expected_out : test =
  Random.init 1;
  name >:: fun _ ->
  assert_equal expected_out (() |> gamestate_func)
    ~printer:currently_animated_printer

(** [elementals_repeated_next n gamestate] returns the result of
    applying the Elementals.next function on [gamestate] [n] time *)
let rec elementals_repeated_next
    (n : int)
    (gamestate : Elementals.gamestate) : Elementals.gamestate =
  if n = 0 then gamestate
  else elementals_repeated_next (n - 1) (gamestate |> Elementals.next)

let elementals_test =
  let open Elementals in
  [
    (* ----------------------- Observer: get_ours ------------------------ *)
    (* ---------------------------- Initial ------------------------------ *)
    our_opponent_test "initial our"
      (fun () -> init_game () |> get_ours)
      (Nothing, 0);
    (* --------------------- Play Something First ---------------------- *)
    our_opponent_test "our play water"
      (fun () -> init_game () |> play_water |> get_ours)
      (Water, 20);
    our_opponent_test "our play fire"
      (fun () -> init_game () |> play_fire |> get_ours)
      (Fire, 20);
    our_opponent_test "our play leaf"
      (fun () -> init_game () |> play_leaf |> get_ours)
      (Leaf, 20);
    (* -------------------- Play Something Second --------------------- *)
    our_opponent_test "our play water then fire"
      (fun () ->
        init_game () |> play_water
        |> elementals_repeated_next 32
        |> play_fire |> get_ours)
      (Fire, 20);
    our_opponent_test "our play fire then leaf"
      (fun () ->
        init_game () |> play_fire
        |> elementals_repeated_next 32
        |> play_leaf |> get_ours)
      (Leaf, 20);
    our_opponent_test "our play leaf then water"
      (fun () ->
        init_game () |> play_leaf
        |> elementals_repeated_next 32
        |> play_water |> get_ours)
      (Water, 20);
    (* --------------------- Observer: get_opponent ---------------------- *)
    (* ---------------------------- Initial ------------------------------ *)
    our_opponent_test "initial opponent - Water #1"
      (fun () -> init_game () |> get_opponent)
      (Leaf, 100);
    our_opponent_test "initial opponent - Leaf #2"
      (fun () -> init_game () |> get_opponent)
      (Leaf, 100);
    our_opponent_test "initial opponent - Fire #3"
      (fun () -> init_game () |> get_opponent)
      (Water, 100);
    (* --------------------- Play Something First ---------------------- *)
    our_opponent_test "opponent play fire"
      (fun () -> init_game () |> play_water |> next |> get_opponent)
      (Fire, 99);
    our_opponent_test "opponent play leaf"
      (fun () -> init_game () |> play_fire |> next |> get_opponent)
      (Leaf, 99);
    our_opponent_test "opponent play leaf"
      (fun () -> init_game () |> play_leaf |> next |> get_opponent)
      (Leaf, 99);
    (* -------------------- Play Something Second --------------------- *)
    our_opponent_test "opponent play water then fire"
      (fun () ->
        init_game () |> play_water |> next |> play_fire |> next
        |> get_opponent)
      (Water, 98);
    our_opponent_test "opponent play fire then leaf"
      (fun () ->
        init_game () |> play_fire |> next |> play_leaf |> next
        |> get_opponent)
      (Fire, 98);
    our_opponent_test "opponent play leaf then water"
      (fun () ->
        init_game () |> play_leaf |> next |> play_water |> next
        |> get_opponent)
      (Water, 98);
    (* ---------------------- Observer: get_wins ----------------------- *)
    (* --------------------- Play Something First ---------------------- *)
    win_loss_test "wins play water"
      (fun () ->
        init_game () |> play_water
        |> elementals_repeated_next 32
        |> get_wins)
      0;
    win_loss_test "wins play fire"
      (fun () ->
        init_game () |> play_fire
        |> elementals_repeated_next 32
        |> get_wins)
      1;
    win_loss_test "wins play leaf"
      (fun () ->
        init_game () |> play_leaf
        |> elementals_repeated_next 32
        |> get_wins)
      0;
    (* --------------------- Observer: get_losses ---------------------- *)
    (* --------------------- Play Something First ---------------------- *)
    win_loss_test "loss play water"
      (fun () ->
        init_game () |> play_water
        |> elementals_repeated_next 32
        |> get_losses)
      1;
    win_loss_test "loss play fire"
      (fun () ->
        init_game () |> play_fire
        |> elementals_repeated_next 32
        |> get_losses)
      0;
    win_loss_test "loss play leaf"
      (fun () ->
        init_game () |> play_leaf
        |> elementals_repeated_next 32
        |> get_losses)
      0;
    (* --------------- Observer: get_currently_animated ---------------- *)
    (* -------------------------- Play Next --------------------------- *)
    (* currently_animated_test "currently animated - play next" (fun ()
       -> init_game () |> play_water |> elementals_repeated_next 32 |>
       get_currently_animated) false; *)
    (* ----------------------- Don't Play Next ------------------------ *)
    (* currently_animated_test "currently animated - don't play next"
       (fun () -> init_game () |> play_water |> get_currently_animated)
       false; *)
  ]

let suite =
  "test suite for Tamagotchi Final Project"
  >::: List.flatten
         [ state_tests; dolphin_test; drum_test; elementals_test ]

let _ = run_test_tt_main suite
