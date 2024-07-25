#define SNIFF 1
#define SHAKE 2
#define SCRATCH 3
#define WASHUP 4

/mob/living/simple_animal/mouse
	name = "mouse"
	real_name = "mouse"
	desc = "It's a small, disease-ridden rodent."
	icon_state = "mouse_gray"
	icon_living = "mouse_gray"
	icon_dead = "mouse_gray_dead"
	icon_resting = "mouse_gray_sleep"
	speak = list("Squeek!","SQUEEK!","Squeek?")
	speak_emote = list("squeeks","squeaks","squiks")
	emote_hear = list("squeeks","squeaks","squiks")
	emote_see = list("runs in a circle", "shakes", "scritches at something")
	var/squeak_sound = 'sound/creatures/mouse_squeak.ogg'
	talk_sound = list('sound/creatures/rat_talk.ogg')
	damaged_sound = list('sound/creatures/rat_wound.ogg')
	death_sound = 'sound/creatures/rat_death.ogg'
	tts_seed = "Gyro"
	speak_chance = 1
	turns_per_move = 5
	nightvision = 6
	maxHealth = 5
	health = 5
	blood_volume = BLOOD_VOLUME_SURVIVE
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/mouse = 1)
	response_help  = "pets"
	response_disarm = "gently pushes aside"
	response_harm   = "stamps on"
	density = FALSE
	ventcrawler_trait = TRAIT_VENTCRAWLER_ALWAYS
	pass_flags = PASSTABLE | PASSGRILLE | PASSMOB
	mobility_flags = MOBILITY_FLAGS_REST_CAPABLE_DEFAULT
	mob_size = MOB_SIZE_TINY
	var/mouse_color //brown, gray and white, leave blank for random
	var/non_standard = FALSE //for no "mouse_" with mouse_color
	layer = MOB_LAYER
	atmos_requirements = list("min_oxy" = 16, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 223		//Below -50 Degrees Celcius
	maxbodytemp = 323	//Above 50 Degrees Celcius
	universal_speak = 0
	can_hide = TRUE
	pass_door_while_hidden = TRUE
	holder_type = /obj/item/holder/mouse
	can_collar = 1
	gold_core_spawnable = FRIENDLY_SPAWN
	var/chew_probability = 1
	var/static/list/animated_mouses = list(
			/mob/living/simple_animal/mouse,
			/mob/living/simple_animal/mouse/brown,
			/mob/living/simple_animal/mouse/gray,
			/mob/living/simple_animal/mouse/white,
			/mob/living/simple_animal/mouse/blobinfected)

/mob/living/simple_animal/mouse/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/squeak, list(squeak_sound), 100, extrarange = SHORT_RANGE_SOUND_EXTRARANGE, dead_check = TRUE) //as quiet as a mouse or whatever
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)

/mob/living/simple_animal/mouse/handle_automated_action()
	if(prob(chew_probability) && isturf(loc))
		var/turf/simulated/floor/F = get_turf(src)
		if(istype(F) && !F.intact && !F.transparent_floor)
			var/obj/structure/cable/C = locate() in F
			if(C && prob(15))
				if(C.avail())
					visible_message("<span class='warning'>[src] chews through [C]. It's toast!</span>")
					playsound(src, 'sound/effects/sparks2.ogg', 100, 1)
					toast() // mmmm toasty.
				else
					visible_message("<span class='warning'>[src] chews through [C].</span>")
				investigate_log("was chewed through by a mouse at [COORD(F)]", INVESTIGATE_WIRES)
				C.deconstruct()

/mob/living/simple_animal/mouse/handle_automated_speech()
	..()
	if(prob(speak_chance) && !incapacitated())
		playsound(src, squeak_sound, 100, 1)

/mob/living/simple_animal/mouse/handle_automated_movement()
	. = ..()
	if(resting)
		if(prob(1))
			set_resting(FALSE, instant = TRUE)
			if(is_available_for_anim())
				do_idle_animation(pick(SNIFF, SCRATCH, SHAKE, WASHUP))
		else if(prob(5))
			custom_emote(EMOTE_AUDIBLE, "соп%(ит,ят)%.")
	else if(prob(0.5))
		set_resting(TRUE, instant = TRUE)

/mob/living/simple_animal/mouse/proc/do_idle_animation(anim)
	ADD_TRAIT(src, TRAIT_IMMOBILIZED, "mouse_animation_trait_[anim]")
	flick("mouse_[mouse_color]_idle[anim]",src)
	addtimer(CALLBACK(src, PROC_REF(animation_end), anim), 2 SECONDS)

/mob/living/simple_animal/mouse/proc/animation_end(anim)
	REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, "mouse_animation_trait_[anim]")

/mob/living/simple_animal/mouse/proc/is_available_for_anim()
	. = FALSE
	if(is_type_in_list(src, animated_mouses, FALSE))
		return TRUE

/mob/living/simple_animal/mouse/New()
	..()
	pixel_x = rand(-6, 6)
	pixel_y = rand(0, 10)

	color_pick()

	if(is_available_for_anim())
		add_verb(src, /mob/living/simple_animal/mouse/proc/sniff)
		add_verb(src, /mob/living/simple_animal/mouse/proc/shake)
		add_verb(src, /mob/living/simple_animal/mouse/proc/scratch)
		add_verb(src, /mob/living/simple_animal/mouse/proc/washup)

/mob/living/simple_animal/mouse/proc/color_pick()
	if(!mouse_color)
		mouse_color = pick( list("brown","gray","white") )
	icon_state = "mouse_[mouse_color]"
	icon_living = "mouse_[mouse_color]"
	icon_dead = "mouse_[mouse_color]_dead"
	icon_resting = "mouse_[mouse_color]_sleep"
	desc = "It's a small [mouse_color] rodent, often seen hiding in maintenance areas and making a nuisance of itself."

/mob/living/simple_animal/mouse/attack_hand(mob/living/carbon/human/M as mob)
	if(M.a_intent == INTENT_HELP)
		get_scooped(M)
	..()

/mob/living/simple_animal/mouse/attack_animal(mob/living/simple_animal/M)
	if(istype(M, /mob/living/simple_animal/pet/cat))
		var/mob/living/simple_animal/pet/cat/C = M
		if(C.friendly && C.eats_mice && C.a_intent == INTENT_HARM)
			apply_damage(15, BRUTE) //3x от ХП обычной мыши или полное хп крысы
			visible_message("<span class='danger'>[M.declent_ru(NOMINATIVE)] [M.attacktext] [src.declent_ru(ACCUSATIVE)]!</span>", \
							"<span class='userdanger'>[M.declent_ru(NOMINATIVE)] [M.attacktext] [src.declent_ru(ACCUSATIVE)]!</span>")
			return
	. = ..()

/mob/living/simple_animal/mouse/pull_constraint(atom/movable/pulled_atom, state, supress_message = FALSE) //Prevents mouse from pulling things
	if(istype(pulled_atom, /obj/item/reagent_containers/food/snacks/cheesewedge))
		return TRUE // Get dem
	if(!supress_message)
		to_chat(src, span_warning("You are too small to pull anything except cheese."))
	return FALSE


/mob/living/simple_animal/mouse/proc/on_entered(datum/source, atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	SIGNAL_HANDLER

	mouse_crossed(arrived)


/mob/living/simple_animal/mouse/proc/mouse_crossed(atom/movable/arrived)
	if(!stat && ishuman(arrived))
		to_chat(arrived, span_notice("[bicon(src)] Squeek!"))


/mob/living/simple_animal/mouse/ratvar_act()
	new/mob/living/simple_animal/mouse/clockwork(loc)
	gib()

/mob/living/simple_animal/mouse/proc/toast()
	add_atom_colour("#3A3A3A", FIXED_COLOUR_PRIORITY)
	desc = "It's toast."
	death()

/mob/living/simple_animal/mouse/proc/splat(obj/item/item = null, mob/living/user = null)
	if(non_standard)
		var/temp_state = initial(icon_state)
		icon_dead = "[temp_state]_splat"
		icon_state = "[temp_state]_splat"
	else
		icon_dead = "mouse_[mouse_color]_splat"
		icon_state = "mouse_[mouse_color]_splat"

	if(prob(50))
		var/turf/location = get_turf(src)
		add_splatter_floor(location)
		if(item)
			item.add_mob_blood(src)
		if(user)
			user.add_mob_blood(src)

/mob/living/simple_animal/mouse/death(gibbed)
	if(gibbed)
		make_remains()

	// Only execute the below if we successfully died
	. = ..(gibbed)
	if(!.)
		return FALSE
	layer = MOB_LAYER

/mob/living/simple_animal/mouse/proc/make_remains()
	var/obj/effect/decal/remains = new /obj/effect/decal/remains/mouse(src.loc)
	remains.pixel_x = pixel_x
	remains.pixel_y = pixel_y

/*
 * Mouse animation emotes
 */

/mob/living/simple_animal/mouse/proc/sniff()
	set name = "Понюхать"
	set desc = "Пытаешься что-то почуять"
	set category = "Мышь"

	emote("msniff", intentional = TRUE)

/mob/living/simple_animal/mouse/proc/shake()
	set name = "Дрожать"
	set desc = "Дрожит или дрыгается"
	set category = "Мышь"

	emote("mshake", intentional = TRUE)

/mob/living/simple_animal/mouse/proc/scratch()
	set name = "Почесаться"
	set desc = "Чешется"
	set category = "Мышь"

	emote("mscratch", intentional = TRUE)

/mob/living/simple_animal/mouse/proc/washup()
	set name = "Умыться"
	set desc = "Умывается"
	set category = "Мышь"

	emote("mwashup", intentional = TRUE)

/datum/emote/living/simple_animal/mouse/idle
	key = "msniff"
	key_third_person = "msniffs"
	message = "нюха%(ет,ют)%!"
	emote_type = EMOTE_AUDIBLE
	muzzled_noises = list("гортанные", "громкие")
	cooldown = 1 MINUTES
	audio_cooldown = 1 MINUTES
	var/anim_type = SNIFF
	volume = 1
	emote_type = EMOTE_VISIBLE|EMOTE_FORCE_NO_RUNECHAT

/datum/emote/living/simple_animal/mouse/idle/run_emote(mob/living/simple_animal/mouse/user, params, type_override, intentional)
	INVOKE_ASYNC(user, TYPE_PROC_REF(/mob/living/simple_animal/mouse, do_idle_animation), anim_type)
	return ..()

/datum/emote/living/simple_animal/mouse/idle/get_sound(mob/living/simple_animal/mouse/user)
	return user.squeak_sound

/datum/emote/living/simple_animal/mouse/idle/shake
	key = "mshake"
	key_third_person = "mshakes"
	message = "дрож%(ит,ат)%!"
	anim_type = SHAKE

/datum/emote/living/simple_animal/mouse/idle/scratch
	key = "mscratch"
	key_third_person = "mscratches"
	message = "чеш%(ет,ут)%ся!"
	anim_type = SCRATCH

/datum/emote/living/simple_animal/mouse/idle/washup
	key = "mwashup"
	key_third_person = "mwashesup"
	message = "умыва%(ет,ют)%ся!"
	anim_type = WASHUP

/*
 * Mouse types
 */

/mob/living/simple_animal/mouse/white
	mouse_color = "white"
	icon_state = "mouse_white"
	tts_seed = "Meepo"

/mob/living/simple_animal/mouse/gray
	mouse_color = "gray"
	icon_state = "mouse_gray"

/mob/living/simple_animal/mouse/brown
	mouse_color = "brown"
	icon_state = "mouse_brown"
	tts_seed = "Clockwerk"

//TOM IS ALIVE! SQUEEEEEEEE~K :)
/mob/living/simple_animal/mouse/brown/Tom
	name = "Tom"
	desc = "Jerry the cat is not amused."
	response_help  = "pets"
	response_disarm = "gently pushes aside"
	response_harm   = "splats"
	unique_pet = TRUE
	gold_core_spawnable = NO_SPAWN
	tts_seed = "Arthas"
	maxHealth = 10
	health = 10


/mob/living/simple_animal/mouse/blobinfected
	maxHealth = 100
	health = 100
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	gold_core_spawnable = NO_SPAWN
	var/cycles_alive = 0
	var/cycles_limit = 60
	var/has_burst = FALSE

/mob/living/simple_animal/mouse/blobinfected/Initialize(mapload)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(get_mind)), MOUSE_REVOTE_TIME)


/mob/living/simple_animal/mouse/blobinfected/get_scooped(mob/living/carbon/grabber)
	to_chat(grabber, "<span class='warning'>You try to pick up [src], but they slip out of your grasp!</span>")
	to_chat(src, "<span class='warning'>[src] tries to pick you up, but you wriggle free of their grasp!</span>")

/mob/living/simple_animal/mouse/blobinfected/proc/get_mind()
	if(mind || !SSticker || !SSticker.mode)
		return
	var/list/candidates = SSghost_spawns.poll_candidates("Вы хотите сыграть за мышь, зараженную Блобом?", ROLE_BLOB, TRUE, source = /mob/living/simple_animal/mouse/blobinfected)
	if(!length(candidates))
		log_and_message_admins("There were no players willing to play as a mouse infected with a blob.")
		return
	var/mob/M = pick(candidates)
	key = M.key
	var/datum/antagonist/blob_infected/blob_datum = new
	blob_datum.time_to_burst_hight = TIME_TO_BURST_MOUSE_HIGHT
	blob_datum.time_to_burst_low = TIME_TO_BURST_MOUSE_LOW
	mind.add_antag_datum(blob_datum)
	to_chat(src, span_userdanger("Теперь вы мышь, заражённая спорами Блоба. Найдите какое-нибудь укромное место до того, как вы взорветесь и станете Блобом! Вы можете перемещаться по вентиляции, нажав Alt+ЛКМ на вентиляционном отверстии."))
	log_game("[key] has become blob infested mouse.")
	notify_ghosts("Заражённая мышь появилась в [get_area(src)].", source = src, action = NOTIFY_FOLLOW)

/mob/living/simple_animal/mouse/fluff/clockwork
	name = "Chip"
	real_name = "Chip"
	mouse_color = "clockwork"
	icon_state = "mouse_clockwork"
	response_help  = "pets"
	response_disarm = "gently pushes aside"
	response_harm   = "stamps on"
	gold_core_spawnable = NO_SPAWN
	can_collar = 0
	butcher_results = list(/obj/item/stack/sheet/metal = 1)
	maxHealth = 20
	health = 20

/mob/living/simple_animal/mouse/decompile_act(obj/item/matter_decompiler/C, mob/user)
	if(!isdrone(user))
		user.visible_message("<span class='notice'>[user] sucks [src] into its decompiler. There's a horrible crunching noise.</span>", \
		"<span class='warning'>It's a bit of a struggle, but you manage to suck [src] into your decompiler. It makes a series of visceral crunching noises.</span>")
		new/obj/effect/decal/cleanable/blood/splatter(get_turf(src))
		C.stored_comms["wood"] += 2
		C.stored_comms["glass"] += 2
		qdel(src)
		return TRUE
	return ..()

/mob/living/simple_animal/mouse/rat
	name = "rat"
	real_name = "rat"
	desc = "Крыса. Рожа у неё хитрая и знакомая..."
	squeak_sound = 'sound/creatures/rat_squeak.ogg'
	icon_state 		= "rat_gray"
	icon_living 	= "rat_gray"
	icon_dead 		= "rat_gray_dead"
	icon_resting 	= "rat_gray_sleep"
	non_standard = TRUE
	mouse_color = null
	maxHealth = 15
	health = 15
	mob_size = MOB_SIZE_SMALL
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/mouse = 2)


/mob/living/simple_animal/mouse/rat/color_pick()
	if(!mouse_color)
		mouse_color = pick(list("gray","white","irish"))
		icon_state 		= "rat_[mouse_color]"
		icon_living 	= "rat_[mouse_color]"
		icon_dead 		= "rat_[mouse_color]_dead"
		icon_resting 	= "rat_[mouse_color]_sleep"

/mob/living/simple_animal/mouse/rat/gray
	name = "gray rat"
	real_name = "gray rat"
	desc = "Серая крыса. Не яркий представитель своего вида."
	mouse_color = "gray"

/mob/living/simple_animal/mouse/rat/white
	name = "white rat"
	real_name = "white rat"
	desc = "Типичный представитель лабораторных крыс."
	icon_state 		= "rat_white"
	icon_living 	= "rat_white"
	icon_dead 		= "rat_white_dead"
	icon_resting 	= "rat_white_sleep"
	mouse_color = "white"

/mob/living/simple_animal/mouse/rat/irish
	name = "irish rat"		//Да, я знаю что это вид. Это каламбурчик.
	real_name = "irish rat"
	desc = "Ирландская крыса. На космической станции?! На этот раз им точно некуда бежать!"
	icon_state 		= "rat_irish"
	icon_living 	= "rat_irish"
	icon_dead 		= "rat_irish_dead"
	icon_resting 	= "rat_irish_sleep"
	mouse_color = "irish"

#define MAX_HAMSTER 50
GLOBAL_VAR_INIT(hamster_count, 0)

/mob/living/simple_animal/mouse/hamster
	name = "хомяк"
	real_name = "хомяк"
	desc = "С надутыми щечками."
	icon_state = "hamster"
	icon_living = "hamster"
	icon_dead = "hamster_dead"
	icon_resting = "hamster_rest"
	gender = MALE
	non_standard = TRUE
	mobility_flags = MOBILITY_FLAGS_REST_CAPABLE_DEFAULT
	speak_chance = 0
	childtype = list(/mob/living/simple_animal/mouse/hamster/baby)
	animal_species = /mob/living/simple_animal/mouse/hamster
	holder_type = /obj/item/holder/hamster
	gold_core_spawnable = FRIENDLY_SPAWN
	tts_seed = "Gyro"
	maxHealth = 10
	health = 10

/mob/living/simple_animal/mouse/hamster/color_pick()
	return

/mob/living/simple_animal/mouse/hamster/New()
	gender = prob(80) ? MALE : FEMALE
	desc += MALE ? " Самец!" : " Самочка! Ох... Нет... "
	GLOB.hamster_count++
	. = ..()

/mob/living/simple_animal/mouse/hamster/Destroy()
	GLOB.hamster_count--
	. = ..()

/mob/living/simple_animal/mouse/hamster/death(gibbed)
	if(!gibbed)
		GLOB.hamster_count--
	. = ..()

/mob/living/simple_animal/mouse/hamster/pull_constraint(atom/movable/pulled_atom, state, supress_message = FALSE)
	return TRUE

/mob/living/simple_animal/mouse/hamster/Life(seconds, times_fired)
	..()
	if(GLOB.hamster_count < MAX_HAMSTER)
		make_babies()

/mob/living/simple_animal/mouse/hamster/baby
	name = "хомячок"
	real_name = "хомячок"
	desc = "Очень миленький! Какие у него пушистые щечки!"
	tts_seed = "Meepo"
	turns_per_move = 2
	response_help  = "полапал"
	response_disarm = "аккуратно отодвинул"
	response_harm   = "наступил на"
	attacktext = "толкается"
	transform = matrix(0.7, 0, 0, 0, 0.7, 0)
	health = 3
	maxHealth = 3
	var/amount_grown = 0
	can_hide = 1
	can_collar = 0
	holder_type = /obj/item/holder/hamster


/mob/living/simple_animal/mouse/hamster/baby/start_pulling(atom/movable/pulled_atom, state, force = pull_force, supress_message = FALSE)
	if(!supress_message)
		to_chat(src, span_warning("Вы слишком малы чтобы что-то тащить."))
	return FALSE


/mob/living/simple_animal/mouse/hamster/baby/Life(seconds, times_fired)
	. =..()
	if(.)
		amount_grown++
		if(amount_grown >= 100)
			var/mob/living/simple_animal/A = new /mob/living/simple_animal/mouse/hamster(loc)
			if(mind)
				mind.transfer_to(A)
			qdel(src)


/mob/living/simple_animal/mouse/hamster/baby/mouse_crossed(atom/movable/arrived)
	if(!stat && ishuman(arrived))
		to_chat(arrived, span_notice("[bicon(src)] раздавл[genderize_ru(gender, "ен", "на", "но")]!"))
		death()
		splat(user = arrived)


#undef SNIFF
#undef SHAKE
#undef SCRATCH
#undef WASHUP
