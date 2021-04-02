#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <cstrike>
#include <fun>

#define TASKID 1991

#define PLUGIN "Hacker Detector Admin"
#define VERSION "1.0"
#define AUTHOR "autornãoquispartecipar / Alex rafael"

// define se o plugin deve usar client_infochanged
// para manter os nomes dos jogadores atualizados
// (desative se a troca de nick está desativada no servidor)
#define CLIENT_INFOCHANGED false


// define a flag de acesso ao comando de invisibilidade
#define ADMIN_INVISIBILITY_FLAG ADMIN_BAN_TEMP

//nome do seu ClaN
#define PREFIX_MENU "ClaN Brasilia"  


// guarda se o jogador está invisível
public isInvisible[33];


// guarda a posição do jogador alvo
// e a direção que ele está olhando
public Float:targetPosition[3];
public Float:targetAngles[3];


// guardo os nomes dos jogadores
// para um uso otimizado
public playerNames[33][32];
public playeradminon, csdm_on



// nome das partes do corpo
public const BODY_PARTS[][] = {

	/* HIT_GENERIC	*/ "Acerto genérico",
	/* HIT_HEAD		*/ "Acerto na cabeça",
	/* HIT_CHEST 	*/ "Acerto no peito",
	/* HIT_STOMACH	*/ "Acerto no estômago",
	/* HIT_LEFTARM	*/ "Acerto no braço esquerdo",
	/* HIT_RIGHTARM	*/ "Acerto no braço direito",
	/* HIT_LEFTLEG	*/ "Acerto na pena esquerda",
	/* HIT_RIGHTLEG	*/ "Acerto na pena direita",
};


public plugin_init()
{
	register_plugin("PLUGIN", "VERSION","AUTHOR") 

	register_clcmd("say /admin", "invisibilityMenu", ADMIN_INVISIBILITY_FLAG);
	register_clcmd("say_team /admin", "invisibilityMenu", ADMIN_INVISIBILITY_FLAG);
	csdm_on	= register_cvar("csdm_on", "1")

	RegisterHamPlayer(Ham_Spawn, "playerSpawn", .Post = 1);
	RegisterHamPlayer(Ham_Killed, "playerKilled", .Post = 1);
	RegisterHamPlayer(Ham_TakeDamage, "playerDamage", .Post = 0);
}


public playerKilled(id, idattacker, shouldgib)
{
	if (playeradminon)
	{
		static players[32];
		new num;

		// consulta os jogadores vivos
		get_players(players, num, "a");


		// verifica se sobrou apenas 2 jogadores
		if ( num <= 3 )
		{
			for (new i = 0; i < num ; i++)
			{

				// verifica se um dos jogadores restantes
				// tem invisibilidade
				if ( isInvisible[players[i]] )
				{
					// mata ele silenciosamente
					user_silentkill(players[i], 1);

					if(task_exists(id + TASKID))
					{
						remove_task (id + TASKID) 
					}
				} 
			}
		}
	}


	return HAM_IGNORED;
}

public client_disconnected(id)
{
	if(isInvisible[id])
	{
		playeradminon = false
	}

	isInvisible[id] = 0;

	if(task_exists(id + TASKID))
	{
		remove_task (id + TASKID) 
	}
}



public client_putinserver(id)
{
	if ( is_user_connected(id) )
	{
		get_user_name(id, playerNames[id], charsmax(playerNames[]));
	}
}



#if CLIENT_INFOCHANGED
	public client_infochanged(id)
	{
		if ( is_user_connected(id) )
		{
			get_user_name(id, playerNames[id], charsmax(playerNames[]));
		}
	}
#endif



public playerSpawn(id)
{
	if (get_user_flags(id) & ADMIN_KICK) 
	{

		if ( isInvisible[id] && is_user_alive(id) )
		{
			if ( isInvisible[id]++ == 2 )
			{
				isInvisible[id] = 0;

				set_user_rendering(id);
				set_user_maxspeed(id, 1.0);
				set_user_footsteps(id, 0);
				set_user_noclip(id, 0);
				playeradminon = false

				client_print_color(id,print_team_default,"^4[^1%s^4] ^3Invisibilidade removida^1.", PREFIX_MENU)

				if(task_exists(id + TASKID))
				{
					remove_task (id + TASKID) 
				}

				return HAM_IGNORED;
			}


			//set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 1);
			set_user_rendering (id, kRenderFxNone, 0, 0, 0, kRenderTransTexture, 1)
			set_user_maxspeed(id, 999.0);
			set_user_footsteps(id);
			set_user_noclip(id, 1);


			if ( (targetPosition[0] + targetPosition[0] + targetPosition[0]) != 0.0 )
			{
				engfunc(EngFunc_SetOrigin, id, targetPosition);

				set_pev(id, pev_angles, targetAngles);
				set_pev(id, pev_fixangle, 1);
			}


			targetPosition[0] = targetPosition[1] = targetPosition[2] = 0.0;
			
		}
	}

	return HAM_IGNORED;
}



public playerDamage(this, idinflictor, idattacker, Float:damage, damagebits)
{
	if (playeradminon)
	{
		if ( isInvisible[this] )
		{
			new hit = get_ent_data(this, "CBaseMonster", "m_LastHitGroup");

			client_print_color(this, print_team_default, "^1(^4%s^1) Tiro: ^4%s", playerNames[idattacker], BODY_PARTS[hit]);
			log_to_file("admin_hacker_detector.txt","<%s> IP Tiro <%s>", playerNames[idattacker], BODY_PARTS[hit]);

			return HAM_SUPERCEDE;
		}
	}

	return HAM_IGNORED;
}



public invisibilityMenu(id, level, cid)
{
	if ( cmd_access(id, level, cid, 1) )
	{
		if ( !is_user_connected(id) )
		{
			return PLUGIN_HANDLED;
		}

		if(cs_get_user_team(id) == CS_TEAM_SPECTATOR)
		{
			client_print_color(id,print_team_default,"^4[^1%s^4] ^3voce não pode entra no modo spec escolhar uma Equipe^1.", PREFIX_MENU)
			return PLUGIN_HANDLED;
		}

		new xFmtxMenu[300]

		formatex(xFmtxMenu, charsmax(xFmtxMenu), "%s Hacker Detector Admin", PREFIX_MENU)

		new menu  = menu_create(xFmtxMenu, "invisibilityHandler")

		new players[32];
		new num;


		get_players(players, num, "a");


		for (new i = 0, userId[4]; i < num; i++)
		{
			if ( players[i] == id )
			{
				continue;
			}

			num_to_str(get_user_userid(players[i]), userId, charsmax(userId));

			menu_additem(menu, playerNames[players[i]], userId);
		}


		menu_display(id, menu);
		return PLUGIN_CONTINUE;
	}

	return PLUGIN_HANDLED;	
}




public xkillSelectTop(TASK)
{
	new id = TASK - TASKID

	new xFmtxMenu[300]

	formatex(xFmtxMenu, charsmax(xFmtxMenu), "^n^n^n%s \wdeseja se Matar?", PREFIX_MENU)

	new xNewMenu = menu_create(xFmtxMenu, "_xMenuSelectTopkill")
	
	menu_additem(xNewMenu, "sim"),
	menu_additem(xNewMenu, "não"),

	menu_setprop(xNewMenu, MPROP_EXITNAME, "Sair"),
	menu_display(id, xNewMenu, 0)
}

public _xMenuSelectTopkill(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu); return
	}
	
	switch(item)
	{
		case 0:
		{
			user_silentkill(id, 1);
			isInvisible[id] = 0;

			if(task_exists(id + TASKID))
			{
				remove_task (id + TASKID) 
			}

			set_user_rendering(id);
			set_user_maxspeed(id, 1.0);
			set_user_footsteps(id, 0);
			set_user_noclip(id, 0);
			playeradminon = false
			client_print_color(id,print_team_default,"^4[^1%s^4] ^3Invisibilidade removida^1.", PREFIX_MENU)
		}

		case 1:
		{

		}
	}
}



public invisibilityHandler(id, menu, item)
{
	if ( item != MENU_EXIT && is_user_connected(id))
	{
		new userId[4];
		new name[32];

		menu_item_getinfo(menu, item, .info = userId, .infolen = charsmax(userId), .name = name, .namelen = charsmax(name));


		new player = find_player("k", str_to_num(userId));

		if ( playeradminon)
		{
			client_print_color(id,print_team_default,"^4[^1%s^4] ^3Ja tem um admin usando esse modo aguardem.^1.", PREFIX_MENU)
			return PLUGIN_HANDLED;
		}

	
		if ( is_user_alive(player) || get_pcvar_num(csdm_on) == 1 )
		{
			playeradminon = true
			isInvisible[id] = 1;

		
			new position[3];

			if (is_user_connected(player))
			{
				get_user_origin(player, position, Origin_Client);
				pev(player, pev_angles, targetAngles);


				targetPosition[0] = float(position[0]);
				targetPosition[1] = float(position[1]);
				targetPosition[2] = float(position[2]) + 100.0;
			}



			new CsTeams:team = cs_get_user_team(id);
			new CsTeams:targetTeam = cs_get_user_team(player);


			if ( team != targetTeam )
			{
				cs_set_user_team(id, targetTeam == CS_TEAM_CT ? CS_TEAM_T : CS_TEAM_CT);
			}
			

			if(get_cvar_num( "mp_forcerespawn" ) !=1)
			{

				if(is_user_alive(id))
				{
					set_user_rendering (id, kRenderFxNone, 0, 0, 0, kRenderTransTexture, 1)
					set_user_maxspeed(id, 999.0);
					set_user_footsteps(id);
					set_user_noclip(id, 1);


					if ( (targetPosition[0] + targetPosition[0] + targetPosition[0]) != 0.0 )
					{
					engfunc(EngFunc_SetOrigin, id, targetPosition);

					set_pev(id, pev_angles, targetAngles);
					set_pev(id, pev_fixangle, 1);
					}


					targetPosition[0] = targetPosition[1] = targetPosition[2] = 0.0;
				}
				else
				{
					ExecuteHamB(Ham_CS_RoundRespawn, id);
					client_print_color(id,print_team_default,"^4[^1%s^4] ^3FOrce Respaw^1.", PREFIX_MENU)
				}
			}
			else
			{
				set_user_rendering (id, kRenderFxNone, 0, 0, 0, kRenderTransTexture, 1)
				set_user_maxspeed(id, 999.0);
				set_user_footsteps(id);
				set_user_noclip(id, 1);


				if ( (targetPosition[0] + targetPosition[0] + targetPosition[0]) != 0.0 )
				{
				engfunc(EngFunc_SetOrigin, id, targetPosition);

				set_pev(id, pev_angles, targetAngles);
				set_pev(id, pev_fixangle, 1);
				}


				targetPosition[0] = targetPosition[1] = targetPosition[2] = 0.0;
				
				client_print_color(id,print_team_default,"^4[^1%s^4] ^3Modo csdm detectado^1.", PREFIX_MENU)
			}

			client_print_color(id, print_team_red, "^4[^1%s^4] ^3Jogador ^4%s^3 selecionado^1.", PREFIX_MENU , playerNames[player]);
			set_task(5.0, "xkillSelectTop", TASKID + id, _, _, "a", 6)

		}
		else
		{
			client_print_color(id,print_team_default,"^4[^1%s^4] ^3Jogador selecionado não está vivo^1.", PREFIX_MENU)
		}


		menu_destroy(menu);
	}

	return PLUGIN_HANDLED;
}

